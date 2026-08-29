// FILE: lib/web_live_sync/sub_views/web_challans/web_purchase_challan_billing_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../web_models.dart';
import '../../pharoah_web_manager.dart';
import '../../web_app_date_logic.dart';
import '../web_billing/quick_add_product_modal.dart';
import '../web_billing/web_batch_lookup_dialog.dart';

class WebPurchaseChallanBillingView extends StatefulWidget {
  final Party distributor;
  final String internalNo;
  final String supplierChallanNo;
  final DateTime challanDate;
  final PurchaseChallan? existingRecord;
  final bool isReadOnly;
  final VoidCallback onBack;

  const WebPurchaseChallanBillingView({
    super.key,
    required this.distributor,
    required this.internalNo,
    required this.supplierChallanNo,
    required this.challanDate,
    this.existingRecord,
    this.isReadOnly = false,
    required this.onBack,
  });

  @override
  State<WebPurchaseChallanBillingView> createState() => _WebPurchaseChallanBillingViewState();
}

class _WebPurchaseChallanBillingViewState extends State<WebPurchaseChallanBillingView> {
  final productSearchC = TextEditingController();
  final remarksC = TextEditingController();
  List<PurchaseItem> items = [];
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

  void _openPcItemDialog(PharoahWebManager webPh, Medicine med, {PurchaseItem? itemToEdit, int? editIndex}) {
    if (widget.isReadOnly) return;

    final batchC = TextEditingController(text: itemToEdit?.batch ?? "");
    final expC = TextEditingController(text: itemToEdit?.exp ?? "12/28");
    final mrpC = TextEditingController(text: itemToEdit?.mrp.toStringAsFixed(2) ?? med.mrp.toStringAsFixed(2));
    final purRateC = TextEditingController(text: itemToEdit?.purchaseRate.toStringAsFixed(2) ?? med.purRate.toStringAsFixed(2));
    final qtyC = TextEditingController(text: itemToEdit?.qty.toInt().toString() ?? "1");
    final freeC = TextEditingController(text: itemToEdit?.freeQty.toInt().toString() ?? "0");
    final gstC = TextEditingController(text: itemToEdit?.gstRate.toString() ?? med.gst.toString());

    List<BatchInfo> availableBatches = webPh.batchHistory[med.identityKey] ?? [];

    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setDialogState) {
          double q = double.tryParse(qtyC.text) ?? 0.0;
          double pRate = double.tryParse(purRateC.text) ?? 0.0;
          double g = double.tryParse(gstC.text) ?? 0.0;
          double itemTotal = (q * pRate) * (1 + g / 100);

          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Colors.white12)),
            title: Text("INWARD ITEM • ${med.name}", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: batchC,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            decoration: InputDecoration(
                              labelText: "BATCH NO *",
                              labelStyle: const TextStyle(color: Colors.white54, fontSize: 8.5),
                              filled: true,
                              fillColor: Colors.black26,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.layers_rounded, size: 16, color: Color(0xFFFBBF24)),
                                onPressed: () async {
                                  final selected = await showDialog<dynamic>(
                                    context: context,
                                    builder: (ctx) => WebBatchLookupDialog(medicine: med, batches: availableBatches),
                                  );
                                  if (selected != null && selected is BatchInfo) {
                                    setDialogState(() {
                                      batchC.text = selected.batch;
                                      expC.text = selected.exp;
                                      mrpC.text = selected.mrp.toStringAsFixed(2);
                                      purRateC.text = selected.purRate.toStringAsFixed(2);
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: expC,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            decoration: InputDecoration(
                              labelText: "EXPIRY (MM/YY)",
                              labelStyle: const TextStyle(color: Colors.white54, fontSize: 8.5),
                              filled: true,
                              fillColor: Colors.black26,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _input("MRP ₹", mrpC, isNum: true)),
                        const SizedBox(width: 10),
                        Expanded(child: _input("PUR. RATE ₹ *", purRateC, isNum: true, isHighlight: true, onChanged: (_) => setDialogState(() {}))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _input("INWARD QTY *", qtyC, isNum: true, isHighlight: true, onChanged: (_) => setDialogState(() {}))),
                        const SizedBox(width: 10),
                        Expanded(child: _input("FREE QTY", freeC, isNum: true)),
                        const SizedBox(width: 10),
                        Expanded(child: _input("GST %", gstC, isNum: true, onChanged: (_) => setDialogState(() {}))),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("INWARD ESTIMATE", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                          Text("₹${itemTotal.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 18, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c), child: const Text("CANCEL", style: TextStyle(color: Colors.white54))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white),
                onPressed: () {
                  if (batchC.text.trim().isEmpty || q <= 0 || pRate <= 0) return;
                  final newItem = PurchaseItem(
                    id: itemToEdit?.id ?? "PCITM-${DateTime.now().millisecondsSinceEpoch}",
                    srNo: itemToEdit != null ? itemToEdit.srNo : items.length + 1,
                    medicineID: med.id,
                    name: med.name,
                    packing: med.packing,
                    batch: batchC.text.trim(),
                    exp: expC.text.trim(),
                    hsn: med.hsnCode,
                    mrp: double.tryParse(mrpC.text) ?? 0.0,
                    qty: q,
                    freeQty: double.tryParse(freeC.text) ?? 0.0,
                    purchaseRate: pRate,
                    gstRate: g,
                    total: itemTotal,
                  );
                  setState(() {
                    if (editIndex != null) {
                      items[editIndex] = newItem;
                    } else {
                      items.add(newItem);
                    }
                  });
                  Navigator.pop(c);
                },
                child: const Text("ADD TO INWARD", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
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
          _openPcItemDialog(webPh, medObj);
        },
      ),
    );
  }

  double get subTotal => items.fold(0.0, (sum, it) => sum + it.total);

  void _handleSave(PharoahWebManager webPh) {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Inward challan cannot be empty!"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => isSaving = true);

    final newChallan = PurchaseChallan(
      id: widget.existingRecord?.id ?? "PCH-WEB-${DateTime.now().millisecondsSinceEpoch}",
      internalNo: widget.internalNo,
      billNo: widget.supplierChallanNo,
      partyId: widget.distributor.id,
      distributorName: widget.distributor.name,
      date: widget.challanDate,
      items: List.from(items),
      totalAmount: subTotal,
      status: widget.existingRecord?.status ?? "Pending",
      remarks: remarksC.text.trim(),
    );

    if (widget.existingRecord != null) {
      webPh.deletePurchaseChallan(widget.existingRecord!.id);
    }
    webPh.purchaseChallans.add(newChallan);
    webPh.pushUpdatedDataToCloud();

    setState(() => isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ Inward Challan ${widget.internalNo} Saved!"), backgroundColor: Colors.green),
    );
    widget.onBack();
  }

  Widget _input(String label, TextEditingController ctrl, {bool isNum = false, bool isHighlight = false, Function(String)? onChanged}) {
    return TextField(
      controller: ctrl,
      onChanged: onChanged,
      keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 8.5, fontWeight: FontWeight.bold),
        filled: true,
        fillColor: isHighlight ? const Color(0x33D97706) : Colors.black26,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    );
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
        title: Text(widget.isReadOnly ? "View Inward: ${widget.internalNo}" : "Inward Purchase Cart: ${widget.internalNo}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
        actions: [
          if (!widget.isReadOnly)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                ),
                onPressed: isSaving ? null : () => _handleSave(webPh),
                icon: const Icon(Icons.check_circle_rounded, size: 16),
                label: const Text("FINALIZE INWARD", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
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
                              hintText: "Search Product to add in inward challan...",
                              hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                              prefixIcon: const Icon(Icons.search, color: Color(0xFFFBBF24), size: 18),
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
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: Colors.black,
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
                        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0x33FBBF24))),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: matchingMeds.length,
                          itemBuilder: (context, idx) {
                            final m = matchingMeds[idx];
                            return ListTile(
                              dense: true,
                              title: Text(m.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              subtitle: Text("Pack: ${m.packing} • Pur Rate: ₹${m.purRate}", style: const TextStyle(color: Colors.white38, fontSize: 10)),
                              onTap: () {
                                setState(() => productSearchC.clear());
                                _openPcItemDialog(webPh, m);
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
                                  subtitle: Text("Batch: ${items[i].batch} • Exp: ${items[i].exp} • Qty: ${items[i].qty.toInt()} + ${items[i].freeQty.toInt()} • Rate: ₹${items[i].purchaseRate}", style: const TextStyle(color: Colors.white54, fontSize: 10)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text("₹${items[i].total.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.bold, fontSize: 12.5)),
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
                Text("SUPPLIER: ${widget.distributor.name}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                Text("Ref: ${widget.supplierChallanNo} • Date: ${WebAppDateLogic.format(widget.challanDate)}", style: const TextStyle(color: Colors.white54, fontSize: 10)),
                const Divider(color: Colors.white10, height: 20),
                TextField(
                  controller: remarksC,
                  readOnly: widget.isReadOnly,
                  style: const TextStyle(color: Colors.white, fontSize: 11.5),
                  decoration: const InputDecoration(
                    labelText: "INWARD REMARKS",
                    labelStyle: TextStyle(color: Colors.white54, fontSize: 9.5),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(),
                  ),
                ),
                const Spacer(),
                Text("TOTAL INWARD: ₹${subTotal.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                if (!widget.isReadOnly)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white),
                      onPressed: isSaving ? null : () => _handleSave(webPh),
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text("SAVE INWARD CHALLAN", style: TextStyle(fontWeight: FontWeight.bold)),
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
