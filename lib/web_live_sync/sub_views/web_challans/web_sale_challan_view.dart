// FILE: lib/web_live_sync/sub_views/web_challans/web_sale_challan_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../web_models.dart';
import '../../pharoah_web_manager.dart';
import '../../web_app_date_logic.dart';
import '../../web_pharoah_numbering_engine.dart';
import '../web_billing/quick_add_party_modal.dart';
import 'web_sale_challan_billing_view.dart';

class WebSaleChallanView extends StatefulWidget {
  final VoidCallback onBack;
  final SaleChallan? existingRecord;
  final bool isReadOnly;

  const WebSaleChallanView({
    super.key,
    required this.onBack,
    this.existingRecord,
    this.isReadOnly = false,
  });

  @override
  State<WebSaleChallanView> createState() => _WebSaleChallanViewState();
}

class _WebSaleChallanViewState extends State<WebSaleChallanView> {
  final challanNoC = TextEditingController();
  final partySearchC = TextEditingController();
  DateTime selectedDate = DateTime.now();
  Party? selectedParty;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    final webPh = Provider.of<PharoahWebManager>(context, listen: false);
    _initChallan(webPh);
  }

  void _initChallan(PharoahWebManager webPh) {
    if (widget.existingRecord != null) {
      final ex = widget.existingRecord!;
      challanNoC.text = ex.billNo;
      selectedDate = ex.date;
      try {
        selectedParty = webPh.parties.firstWhere((p) => p.name == ex.partyName);
      } catch (_) {
        selectedParty = Party(id: ex.partyId, name: ex.partyName, gst: ex.partyGstin, state: ex.partyState);
      }
    } else {
      selectedDate = WebAppDateLogic.getSmartDate(webPh.financialYear);
      String prefix = "SCH-";
      int start = 101;
      try {
        final defSeries = webPh.numberingSeries.firstWhere((s) => s.type == "CHALLAN" && s.isDefault && s.isActive);
        prefix = defSeries.prefix;
        start = defSeries.startNumber;
      } catch (_) {}

      challanNoC.text = WebPharoahNumberingEngine.getNextNumber(
        prefix: prefix,
        startFrom: start,
        currentList: webPh.saleChallans,
      );
    }
    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    challanNoC.dispose();
    partySearchC.dispose();
    super.dispose();
  }

  void _openQuickAddCustomer(PharoahWebManager webPh) {
    if (widget.isReadOnly) return;
    showDialog(
      context: context,
      builder: (c) => QuickAddPartyModal(
        webPh: webPh,
        onPartyCreated: (newParty) {
          setState(() {
            selectedParty = newParty;
            partySearchC.clear();
          });
        },
      ),
    );
  }

  void _proceedToItemEntry() {
    if (selectedParty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a customer / party!"), backgroundColor: Colors.orange),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => WebSaleChallanBillingView(
          party: selectedParty!,
          challanNo: challanNoC.text.trim(),
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
    final webPh = Provider.of<PharoahWebManager>(context);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E)));
    }

    final query = partySearchC.text.trim().toLowerCase();
    final matchingParties = query.isEmpty
        ? <Party>[]
        : webPh.parties
            .where((p) =>
                p.group == "Sundry Debtors" &&
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
          border: Border.all(color: const Color(0x660F766E), width: 1.2),
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
                    color: Color(0x330F766E),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_shipping_rounded, color: Color(0xFF2DD4BF), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "OUTWARD DELIVERY CHALLAN SETUP",
                        style: TextStyle(color: Color(0xFF2DD4BF), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                      ),
                      Text(
                        widget.isReadOnly ? "View Delivery Note" : (widget.existingRecord != null ? "Modify Delivery Challan" : "New Outward Delivery Note"),
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
                    controller: challanNoC,
                    readOnly: widget.existingRecord != null || widget.isReadOnly,
                    style: const TextStyle(color: Color(0xFF2DD4BF), fontWeight: FontWeight.w900, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: "CHALLAN NUMBER",
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: widget.isReadOnly
                        ? null
                        : () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: WebAppDateLogic.getFYStart(webPh.financialYear),
                              lastDate: WebAppDateLogic.getFYEnd(webPh.financialYear),
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
                              const Text("DISPATCH DATE", style: TextStyle(color: Colors.white54, fontSize: 8.5, fontWeight: FontWeight.bold)),
                              Text(WebAppDateLogic.format(selectedDate), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Icon(Icons.calendar_month_rounded, color: Color(0xFF2DD4BF), size: 18),
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
                const Text("SELECT CUSTOMER / CONSIGNEE *", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                if (!widget.isReadOnly)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: () => _openQuickAddCustomer(webPh),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 14),
                    label: const Text("+ CUSTOMER", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            if (selectedParty != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF0F766E), width: 1.2),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(backgroundColor: Color(0x330F766E), child: Icon(Icons.person_rounded, color: Color(0xFF2DD4BF))),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(selectedParty!.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13.5)),
                          const SizedBox(height: 2),
                          Text("${selectedParty!.city} | GST: ${selectedParty!.gst} | State: ${selectedParty!.state}", style: const TextStyle(color: Colors.white54, fontSize: 10.5)),
                        ],
                      ),
                    ),
                    if (!widget.isReadOnly)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 20),
                        onPressed: () => setState(() => selectedParty = null),
                      ),
                  ],
                ),
              )
            else ...[
              TextField(
                controller: partySearchC,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                decoration: InputDecoration(
                  hintText: "Search Customer by Name, City or Phone...",
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                  prefixIcon: const Icon(Icons.person_search_rounded, color: Color(0xFF2DD4BF), size: 18),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onChanged: (_) => setState(() {}),
              ),
              if (matchingParties.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  constraints: const BoxConstraints(maxHeight: 160),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0x332DD4BF)),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: matchingParties.length,
                    itemBuilder: (context, idx) {
                      final p = matchingParties[idx];
                      return ListTile(
                        dense: true,
                        title: Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        subtitle: Text("${p.city} | GST: ${p.gst}", style: const TextStyle(color: Colors.white38, fontSize: 10)),
                        onTap: () => setState(() {
                          selectedParty = p;
                          partySearchC.clear();
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
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _proceedToItemEntry,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(
                  widget.isReadOnly ? "VIEW CHALLAN ITEMS" : "PROCEED TO ITEM CART",
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
