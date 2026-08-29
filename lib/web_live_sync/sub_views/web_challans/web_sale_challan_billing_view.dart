// FILE: lib/web_live_sync/sub_views/web_challans/web_sale_challan_billing_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../web_models.dart';
import '../../pharoah_web_manager.dart';
import '../../web_app_date_logic.dart';
import '../../web_pdf_router_service.dart';
import '../web_billing/quick_add_product_modal.dart';
import '../web_billing/web_item_entry_card.dart';
import 'web_challan_signature_view.dart';

class WebSaleChallanBillingView extends StatefulWidget {
  final Party party;
  final String challanNo;
  final DateTime challanDate;
  final SaleChallan? existingRecord;
  final bool isReadOnly;
  final VoidCallback onBack;

  const WebSaleChallanBillingView({
    super.key,
    required this.party,
    required this.challanNo,
    required this.challanDate,
    this.existingRecord,
    this.isReadOnly = false,
    required this.onBack,
  });

  @override
  State<WebSaleChallanBillingView> createState() => _WebSaleChallanBillingViewState();
}

class _WebSaleChallanBillingViewState extends State<WebSaleChallanBillingView> {
  final productSearchC = TextEditingController();
  final remarksC = TextEditingController();
  List<BillItem> items = [];
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingRecord != null) {
      items = List.from(widget.existingRecord!.items);
      remarksC.text = widget.existingRecord!.remarks;
    }
  }

  @override
  void dispose() {
    productSearchC.dispose();
    remarksC.dispose();
    super.dispose();
  }

  void _openItemEntry(Medicine med, {BillItem? itemToEdit, int? editIndex}) {
    if (widget.isReadOnly) return;
    final webPh = Provider.of<PharoahWebManager>(context, listen: false);
    String shopState = (webPh.companyProfile['state'] ?? 'Rajasthan').toString();
    List<BatchInfo> batches = webPh.batchHistory[med.identityKey] ?? [];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => WebItemEntryCard(
        med: med,
        srNo: itemToEdit != null ? itemToEdit.srNo : items.length + 1,
        partyState: widget.party.state,
        shopState: shopState,
        availableBatches: batches,
        existingItem: itemToEdit,
        onAdd: (newItem) {
          setState(() {
            if (editIndex != null) {
              items[editIndex] = newItem;
            } else {
              items.add(newItem);
            }
          });
          Navigator.pop(context);
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  void _openQuickAddProduct(PharoahWebManager webPh) {
    if (widget.isReadOnly) return;
    showDialog(
      context: context,
      builder: (c) => QuickAddProductModal(
        webPh: webPh,
        onProductCreated: (newMedMap) {
          final medObj = Medicine.fromMap(newMedMap);
          _openItemEntry(medObj);
        },
      ),
    );
  }

  double get subTotal => items.fold(0.0, (sum, it) => sum + it.total);

  void _handleSave(PharoahWebManager webPh) {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Challan cannot be empty!"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => isSaving = true);

    final newChallan = SaleChallan(
      id: widget.existingRecord?.id ?? "SCH-WEB-${DateTime.now().millisecondsSinceEpoch}",
      billNo: widget.challanNo,
      partyId: widget.party.id,
      partyName: widget.party.name,
      partyGstin: widget.party.gst,
      partyState: widget.party.state,
      date: widget.challanDate,
      items: List.from(items),
      totalAmount: subTotal,
      status: widget.existingRecord?.status ?? "Pending",
      remarks: remarksC.text.trim(),
      isSigned: widget.existingRecord?.isSigned ?? false,
      sigHistory: widget.existingRecord?.sigHistory ?? [],
    );

    if (widget.existingRecord != null) {
      webPh.deleteSaleChallan(widget.existingRecord!.id);
    }
    webPh.saleChallans.add(newChallan);
    webPh.pushUpdatedDataToCloud();

    setState(() => isSaving = false);

    if (webPh.appConfig.showCustomerSignChallan && !widget.isReadOnly) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (c) => WebChallanSignatureView(
            challan: newChallan,
            party: widget.party,
            onBack: widget.onBack,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Sale Challan ${widget.challanNo} Saved!"), backgroundColor: Colors.green),
      );
      widget.onBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    final webPh = Provider.of<PharoahWebManager>(context);

    final query = productSearchC.text.trim().toLowerCase();
    final matchingMeds = query.isEmpty
        ? <Medicine>[]
        : webPh.medicines
            .where((m) =>
                m.name.toLowerCase().contains(query) ||
                m.systemId.toLowerCase().contains(query))
            .take(6)
            .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(widget.isReadOnly ? "View Challan: ${widget.challanNo}" : "Outward Delivery Cart: ${widget.challanNo}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
        actions: [
          if (!widget.isReadOnly)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                ),
                onPressed: isSaving ? null : () => _handleSave(webPh),
                icon: const Icon(Icons.check_circle_rounded, size: 16),
                label: const Text("FINALIZE CHALLAN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 7,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (!widget.isReadOnly) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: productSearchC,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            decoration: InputDecoration(
                              hintText: "Search Product to add in delivery challan...",
                              hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                              prefixIcon: const Icon(Icons.search, color: Color(0xFF2DD4BF), size: 18),
                              filled: true,
                              fillColor: const Color(0xFF1E293B),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _openQuickAddProduct(webPh),
                          icon: const Icon(Icons.add_box_rounded, size: 16),
                          label: const Text("+ PRODUCT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    if (matchingMeds.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 180),
                        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0x332DD4BF))),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: matchingMeds.length,
                          itemBuilder: (context, idx) {
                            final m = matchingMeds[idx];
                            return ListTile(
                              dense: true,
                              title: Text(m.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              subtitle: Text("Pack: ${m.packing} • Stock: ${m.stock.toInt()} • Rate: ₹${m.rateA}", style: const TextStyle(color: Colors.white38, fontSize: 10)),
                              onTap: () {
                                setState(() => productSearchC.clear());
                                _openItemEntry(m);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                  ],

                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(14)),
                      child: items.isEmpty
                          ? const Center(child: Text("Cart is empty. Search products above.", style: TextStyle(color: Colors.white38)))
                          : ListView.builder(
                              itemCount: items.length,
                              itemBuilder: (c, i) => Card(
                                color: const Color(0xFF0F172A),
                                margin: const EdgeInsets.only(bottom: 6),
                                child: ListTile(
                                  dense: true,
                                  title: Text(items[i].name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  subtitle: Text("Batch: ${items[i].batch} • Exp: ${items[i].exp} • Qty: ${items[i].qty.toInt()} + ${items[i].freeQty.toInt()} • Rate: ₹${items[i].rate}", style: const TextStyle(color: Colors.white54, fontSize: 10)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text("₹${items[i].total.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFF2DD4BF), fontWeight: FontWeight.bold, fontSize: 12.5)),
                                      if (!widget.isReadOnly) ...[
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                                          onPressed: () => setState(() => items.removeAt(i)),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Container(
            width: 320,
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(color: Color(0xFF1E293B), border: Border(left: BorderSide(color: Colors.white10))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("CONSIGNEE: ${widget.party.name}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                Text("Date: ${WebAppDateLogic.format(widget.challanDate)} • ${widget.party.city}", style: const TextStyle(color: Colors.white54, fontSize: 10)),
                const Divider(color: Colors.white10, height: 20),
                TextField(
                  controller: remarksC,
                  readOnly: widget.isReadOnly,
                  style: const TextStyle(color: Colors.white, fontSize: 11.5),
                  decoration: const InputDecoration(
                    labelText: "DISPATCH NOTES / VEHICLE NO",
                    labelStyle: TextStyle(color: Colors.white54, fontSize: 9.5),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(),
                  ),
                ),
                const Spacer(),
                Text("TOTAL VALUE: ₹${subTotal.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                if (!widget.isReadOnly)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
                      onPressed: isSaving ? null : () => _handleSave(webPh),
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text("SAVE DELIVERY CHALLAN", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
