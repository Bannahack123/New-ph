// FILE: lib/web_live_sync/sub_views/web_challans/web_purchase_challan_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../web_models.dart';
import '../../pharoah_web_manager.dart';
import '../../web_app_date_logic.dart';
import '../../web_pharoah_numbering_engine.dart';
import '../web_billing/quick_add_party_modal.dart';
import 'web_purchase_challan_billing_view.dart';

class WebPurchaseChallanView extends StatefulWidget {
  final VoidCallback onBack;
  final PurchaseChallan? existingRecord;
  final bool isReadOnly;

  const WebPurchaseChallanView({
    super.key,
    required this.onBack,
    this.existingRecord,
    this.isReadOnly = false,
  });

  @override
  State<WebPurchaseChallanView> createState() => _WebPurchaseChallanViewState();
}

class _WebPurchaseChallanViewState extends State<WebPurchaseChallanView> {
  final internalNoC = TextEditingController();
  final supplierRefC = TextEditingController();
  final supplierSearchC = TextEditingController();
  DateTime selectedDate = DateTime.now();
  Party? selectedSupplier;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    final webPh = Provider.of<PharoahWebManager>(context, listen: false);
    _initInward(webPh);
  }

  void _initInward(PharoahWebManager webPh) {
    if (widget.existingRecord != null) {
      final ex = widget.existingRecord!;
      internalNoC.text = ex.internalNo;
      supplierRefC.text = ex.billNo;
      selectedDate = ex.date;
      try {
        selectedSupplier = webPh.parties.firstWhere((p) => p.name == ex.distributorName);
      } catch (_) {
        selectedSupplier = Party(id: ex.partyId, name: ex.distributorName, group: "Sundry Creditors");
      }
    } else {
      selectedDate = WebAppDateLogic.getSmartDate(webPh.financialYear);
      internalNoC.text = WebPharoahNumberingEngine.getNextNumber(
        prefix: "PCH-",
        startFrom: 1,
        currentList: webPh.purchaseChallans,
      );
    }
    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    internalNoC.dispose();
    supplierRefC.dispose();
    supplierSearchC.dispose();
    super.dispose();
  }

  void _openQuickAddSupplier(PharoahWebManager webPh) {
    if (widget.isReadOnly) return;
    showDialog(
      context: context,
      builder: (c) => QuickAddPartyModal(
        webPh: webPh,
        onPartyCreated: (newParty) {
          setState(() {
            selectedSupplier = newParty;
            supplierSearchC.clear();
          });
        },
      ),
    );
  }

  void _proceedToItemEntry() {
    if (selectedSupplier == null || supplierRefC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select Supplier and enter Supplier Ref No!"), backgroundColor: Colors.orange),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => WebPurchaseChallanBillingView(
          distributor: selectedSupplier!,
          internalNo: internalNoC.text.trim(),
          supplierChallanNo: supplierRefC.text.trim(),
          challanDate: selectedDate,
          existingRecord: widget.existingRecord,
          isReadOnly: widget.isReadOnly,
          onBack: () {
            Navigator.pop(c);
            widget.onBack();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final webPh = Provider.of<PharoahManager?>(context) ?? Provider.of<PharoahWebManager>(context);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFD97706)));
    }

    final query = supplierSearchC.text.trim().toLowerCase();
    final matchingSuppliers = query.isEmpty
        ? <Party>[]
        : (webPh as dynamic).parties
            .where((p) =>
                p.group == "Sundry Creditors" &&
                (p.name.toLowerCase().contains(query) || p.city.toLowerCase().contains(query)))
            .take(6)
            .toList();

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x66D97706), width: 1.2),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 8))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0x33D97706),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.inventory_2_rounded, color: Color(0xFFFBBF24), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "INWARD PURCHASE CHALLAN SETUP",
                        style: TextStyle(color: Color(0xFFFBBF24), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                      ),
                      Text(
                        widget.isReadOnly ? "View Inward Note" : (widget.existingRecord != null ? "Modify Inward Challan" : "New Stock Inward Challan"),
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white54),
                  onPressed: widget.onBack,
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 25),

            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: internalNoC,
                    readOnly: true,
                    style: const TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.w900, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: "INTERNAL ID",
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: supplierRefC,
                    readOnly: widget.isReadOnly,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: "SUPPLIER REF / CHALLAN NO *",
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 9.5, fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: widget.isReadOnly
                        ? null
                        : () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: WebAppDateLogic.getFYStart((webPh as dynamic).financialYear),
                              lastDate: WebAppDateLogic.getFYEnd((webPh as dynamic).financialYear),
                            );
                            if (picked != null) setState(() => selectedDate = picked);
                          },
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("INWARD DATE", style: TextStyle(color: Colors.white54, fontSize: 8.5, fontWeight: FontWeight.bold)),
                              Text(WebAppDateLogic.format(selectedDate), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Icon(Icons.calendar_month_rounded, color: Color(0xFFFBBF24), size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("SELECT SUPPLIER / DISTRIBUTOR *", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                if (!widget.isReadOnly)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: () => _openQuickAddSupplier(webPh),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 14),
                    label: const Text("+ SUPPLIER", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            if (selectedSupplier != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD97706), width: 1.2),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(backgroundColor: Color(0x33D97706), child: Icon(Icons.business_rounded, color: Color(0xFFFBBF24))),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(selectedSupplier!.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13.5)),
                          const SizedBox(height: 2),
                          Text("${selectedSupplier!.city} | GST: ${selectedSupplier!.gst}", style: const TextStyle(color: Colors.white54, fontSize: 10.5)),
                        ],
                      ),
                    ),
                    if (!widget.isReadOnly)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 20),
                        onPressed: () => setState(() => selectedSupplier = null),
                      ),
                  ],
                ),
              )
            else ...[
              TextField(
                controller: supplierSearchC,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                decoration: InputDecoration(
                  hintText: "Search Supplier by Name or City...",
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                  prefixIcon: const Icon(Icons.business, color: Color(0xFFFBBF24), size: 18),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onChanged: (_) => setState(() {}),
              ),
              if (matchingSuppliers.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  constraints: const BoxConstraints(maxHeight: 160),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0x33FBBF24)),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: matchingSuppliers.length,
                    itemBuilder: (context, idx) {
                      final p = matchingSuppliers[idx];
                      return ListTile(
                        dense: true,
                        title: Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        subtitle: Text("${p.city} | GST: ${p.gst}", style: const TextStyle(color: Colors.white38, fontSize: 10)),
                        onTap: () => setState(() {
                          selectedSupplier = p;
                          supplierSearchC.clear();
                        }),
                      );
                    },
                  ),
                ),
              ],
            ],

            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _proceedToItemEntry,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(
                  widget.isReadOnly ? "VIEW INWARD ITEMS" : "PROCEED TO INWARD CART",
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, letterSpacing: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
