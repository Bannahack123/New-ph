// FILE: lib/web_live_sync/web_purchase_entry_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'web_models.dart';
import 'pharoah_web_manager.dart';
import 'web_app_date_logic.dart';

class WebPurchaseEntryView extends StatefulWidget {
  final VoidCallback onBack;

  const WebPurchaseEntryView({super.key, required this.onBack});

  @override
  State<WebPurchaseEntryView> createState() => _WebPurchaseEntryViewState();
}

class _WebPurchaseEntryViewState extends State<WebPurchaseEntryView> {
  final supplierBillNoC = TextEditingController();
  final internalNoC = TextEditingController();
  final extraDiscC = TextEditingController(text: "0");
  DateTime billDate = DateTime.now();
  DateTime entryDate = DateTime.now();
  String paymentMode = "CREDIT";

  Party? selectedSupplier;
  List<PurchaseItem> purchaseItems = [];
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final webPh = Provider.of<PharoahWebManager>(context, listen: false);
    internalNoC.text = webPh.getNextBillNumber("PURCHASE", "PUR-", 1);
    billDate = WebAppDateLogic.getSmartDate(webPh.financialYear);
    entryDate = DateTime.now();
  }

  @override
  void dispose() {
    supplierBillNoC.dispose();
    internalNoC.dispose();
    extraDiscC.dispose();
    super.dispose();
  }

  void _openPurchaseItemDialog(PharoahWebManager webPh, Medicine med, {PurchaseItem? itemToEdit, int? editIndex}) {
    final batchC = TextEditingController(text: itemToEdit?.batch ?? "");
    final expC = TextEditingController(text: itemToEdit?.exp ?? "12/28");
    final mrpC = TextEditingController(text: itemToEdit?.mrp.toStringAsFixed(2) ?? med.mrp.toStringAsFixed(2));
    final purRateC = TextEditingController(text: itemToEdit?.purchaseRate.toStringAsFixed(2) ?? med.purRate.toStringAsFixed(2));
    final rateAC = TextEditingController(text: itemToEdit?.rateA.toStringAsFixed(2) ?? med.rateA.toStringAsFixed(2));
    final rateBC = TextEditingController(text: itemToEdit?.rateB.toStringAsFixed(2) ?? med.rateB.toStringAsFixed(2));
    final rateCC = TextEditingController(text: itemToEdit?.rateC.toStringAsFixed(2) ?? med.rateC.toStringAsFixed(2));
    final qtyC = TextEditingController(text: itemToEdit?.qty.toInt().toString() ?? "1");
    final freeC = TextEditingController(text: itemToEdit?.freeQty.toInt().toString() ?? "0");
    final gstC = TextEditingController(text: itemToEdit?.gstRate.toString() ?? med.gst.toString());
    final discPerC = TextEditingController(text: itemToEdit?.discountPer.toString() ?? "0.0");

    String selectedRateType = itemToEdit?.appliedRateType ?? "A";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => StatefulBuilder(
        builder: (context, setDialogState) {
          double q = double.tryParse(qtyC.text) ?? 0.0;
          double pRate = double.tryParse(purRateC.text) ?? 0.0;
          double dPer = double.tryParse(discPerC.text) ?? 0.0;
          double gPer = double.tryParse(gstC.text) ?? 0.0;

          double gross = q * pRate;
          double discAmt = gross * (dPer / 100);
          double taxable = gross - discAmt;
          double itemTotal = taxable * (1 + gPer / 100);

          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.white12),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0x33F59E0B),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.downloading_rounded, color: Color(0xFFF59E0B), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "PURCHASE INWARD ITEM ENTRY",
                        style: TextStyle(color: Color(0xFFF59E0B), fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      Text(
                        "${med.name} (${med.packing})",
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                  onPressed: () => Navigator.pop(c),
                ),
              ],
            ),
            content: SizedBox(
              width: 580,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(flex: 3, child: _dialogInput("BATCH NO *", batchC, isCaps: true)),
                        const SizedBox(width: 10),
                        Expanded(flex: 2, child: _dialogInput("EXPIRY (MM/YY) *", expC, isNum: true)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _dialogInput("MRP ₹", mrpC, isNum: true, onChanged: (_) => setDialogState(() {}))),
                        const SizedBox(width: 10),
                        Expanded(child: _dialogInput("PUR. RATE ₹ *", purRateC, isNum: true, isHighlight: true, onChanged: (_) => setDialogState(() {}))),
                        const SizedBox(width: 10),
                        Expanded(child: _dialogInput("GST %", gstC, isNum: true, onChanged: (_) => setDialogState(() {}))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _dialogInput("QTY *", qtyC, isNum: true, isHighlight: true, onChanged: (_) => setDialogState(() {}))),
                        const SizedBox(width: 10),
                        Expanded(child: _dialogInput("FREE QTY", freeC, isNum: true)),
                        const SizedBox(width: 10),
                        Expanded(child: _dialogInput("ITEM DISC %", discPerC, isNum: true, onChanged: (_) => setDialogState(() {}))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white10),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("SALE RATES FOR THIS BATCH", style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _dialogInput("RATE A (STD)", rateAC, isNum: true)),
                        const SizedBox(width: 8),
                        Expanded(child: _dialogInput("RATE B (SPL)", rateBC, isNum: true)),
                        const SizedBox(width: 8),
                        Expanded(child: _dialogInput("RATE C (MIN)", rateCC, isNum: true)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Taxable: ₹${taxable.toStringAsFixed(2)} | GST: ₹${(itemTotal - taxable).toStringAsFixed(2)}",
                              style: const TextStyle(color: Colors.white54, fontSize: 10.5, fontWeight: FontWeight.bold)),
                          Text("₹${itemTotal.toStringAsFixed(2)}",
                              style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 18, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text("CANCEL", style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  if (batchC.text.trim().isEmpty || expC.text.trim().isEmpty || q <= 0 || pRate <= 0) return;

                  double mrp = double.tryParse(mrpC.text) ?? 0.0;
                  double a = double.tryParse(rateAC.text) ?? mrp;
                  double b = double.tryParse(rateBC.text) ?? (a * 0.95);
                  double rateCVal = double.tryParse(rateCC.text) ?? (a * 0.92);

                  final newItem = PurchaseItem(
                    id: itemToEdit?.id ?? "PITM-${DateTime.now().millisecondsSinceEpoch}",
                    srNo: itemToEdit != null ? itemToEdit.srNo : purchaseItems.length + 1,
                    medicineID: med.id,
                    name: med.name,
                    packing: med.packing,
                    batch: batchC.text.trim(),
                    exp: expC.text.trim(),
                    hsn: med.hsnCode,
                    mrp: mrp,
                    qty: q,
                    freeQty: double.tryParse(freeC.text) ?? 0.0,
                    purchaseRate: pRate,
                    gstRate: gPer,
                    total: itemTotal,
                    rateA: a,
                    rateB: b,
                    rateC: rateCVal,
                    discountPer: dPer,
                    discountRupees: discAmt,
                    appliedRateType: selectedRateType,
                  );

                  setState(() {
                    if (editIndex != null) {
                      purchaseItems[editIndex] = newItem;
                    } else {
                      purchaseItems.add(newItem);
                    }
                  });

                  Navigator.pop(c);
                },
                child: Text(itemToEdit != null ? "UPDATE ITEM" : "ADD TO INWARD", style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          );
        },
      ),
    );
  }

  // Calculations
  double get subTotal => purchaseItems.fold(0.0, (sum, it) => sum + it.total);
  double get totalTaxable => purchaseItems.fold(0.0, (sum, it) => sum + (it.qty * it.purchaseRate - it.discountRupees));
  double get totalITC => subTotal - totalTaxable;
  double get extraDiscount => double.tryParse(extraDiscC.text) ?? 0.0;
  double get rawGrandTotal => (subTotal - extraDiscount);
  double get finalGrandTotal => rawGrandTotal.roundToDouble();
  double get roundOff => double.parse((finalGrandTotal - rawGrandTotal).toStringAsFixed(2));

  void _savePurchase(PharoahWebManager webPh) {
    if (selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a Supplier / Distributor!"), backgroundColor: Colors.orange),
      );
      return;
    }

    if (supplierBillNoC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Supplier Bill No is required!"), backgroundColor: Colors.orange),
      );
      return;
    }

    if (purchaseItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Purchase cannot be empty! Please add products."), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => isSaving = true);

    final newPurchase = Purchase(
      id: "PUR-WEB-${DateTime.now().millisecondsSinceEpoch}",
      internalNo: internalNoC.text.trim(),
      billNo: supplierBillNoC.text.trim(),
      partyId: selectedSupplier!.id,
      distributorName: selectedSupplier!.name,
      date: billDate,
      entryDate: entryDate,
      paymentMode: paymentMode,
      totalAmount: finalGrandTotal,
      extraDiscount: extraDiscount,
      roundOff: roundOff,
      gstStatus: "Pending",
      items: List.from(purchaseItems),
      sourceTag: "WEB-PORTAL",
    );

    webPh.addPurchaseAndSync(newPurchase);
    setState(() => isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ Purchase Inward ${internalNoC.text} Saved & Stock Updated!"), backgroundColor: Colors.green),
    );

    widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    final webPh = Provider.of<PharoahWebManager>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderBar(webPh),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: Column(
                children: [
                  _buildProductSearchCard(webPh),
                  const SizedBox(height: 16),
                  _buildCartTable(webPh),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  _buildSupplierCard(webPh),
                  const SizedBox(height: 16),
                  _buildGrandTotalCard(webPh),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderBar(PharoahWebManager webPh) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white12,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text("BACK", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 18),
          const Icon(Icons.downloading_rounded, color: Color(0xFFF59E0B), size: 22),
          const SizedBox(width: 10),
          const Text(
            "PURCHASE / STOCK INWARD ENTRY",
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
          const Spacer(),
          SizedBox(
            width: 120,
            height: 36,
            child: TextField(
              controller: internalNoC,
              style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.w900, fontSize: 12),
              decoration: InputDecoration(
                labelText: "ENTRY ID",
                labelStyle: const TextStyle(color: Colors.white54, fontSize: 9),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 140,
            height: 36,
            child: TextField(
              controller: supplierBillNoC,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
              decoration: InputDecoration(
                labelText: "SUPPLIER BILL NO *",
                labelStyle: const TextStyle(color: Colors.white54, fontSize: 9),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'CASH', label: Text('CASH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
              ButtonSegment(value: 'CREDIT', label: Text('CREDIT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
            ],
            selected: {paymentMode},
            onSelectionChanged: (v) => setState(() => paymentMode = v.first),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSearchCard(PharoahWebManager webPh) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x66F59E0B), width: 1.2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Autocomplete<Medicine>(
              displayStringForOption: (m) => "${m.name} (${m.packing}) - Stock: ${m.stock.toInt()}",
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) return const Iterable.empty();
                return webPh.medicines.where((m) =>
                    m.name.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                    m.systemId.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: (med) => _openPurchaseItemDialog(webPh, med),
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: "SEARCH PRODUCT TO INWARD",
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                    hintText: "Type medicine name to add stock...",
                    hintStyle: const TextStyle(color: Colors.white24, fontSize: 11),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFFF59E0B), size: 18),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartTable(PharoahWebManager webPh) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_rounded, color: Color(0xFFF59E0B), size: 18),
              const SizedBox(width: 8),
              Text(
                "INWARD ITEMS (${purchaseItems.length})",
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              const Spacer(),
              if (purchaseItems.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => purchaseItems.clear()),
                  child: const Text("Clear All", style: TextStyle(color: Colors.redAccent, fontSize: 10)),
                ),
            ],
          ),
          const Divider(color: Colors.white10, height: 20),
          if (purchaseItems.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text("Inward cart is empty. Search products above to add stock.", style: TextStyle(color: Colors.white38, fontSize: 12)),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 700),
                child: Table(
                  columnWidths: const {
                    0: FixedColumnWidth(40),
                    1: FlexColumnWidth(3),
                    2: FixedColumnWidth(70),
                    3: FixedColumnWidth(80),
                    4: FixedColumnWidth(60),
                    5: FixedColumnWidth(70),
                    6: FixedColumnWidth(75),
                    7: FixedColumnWidth(50),
                    8: FixedColumnWidth(85),
                    9: FixedColumnWidth(70),
                  },
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10))),
                      children: [
                        _th("SN"),
                        _th("PRODUCT NAME", isLeft: true),
                        _th("PACK"),
                        _th("BATCH"),
                        _th("EXP"),
                        _th("QTY"),
                        _th("PUR. RATE"),
                        _th("GST%"),
                        _th("TOTAL"),
                        _th("ACTIONS"),
                      ],
                    ),
                    ...purchaseItems.asMap().entries.map((entry) {
                      int idx = entry.key;
                      PurchaseItem it = entry.value;
                      String qtyDisp = "${it.qty.toInt()}${it.freeQty > 0 ? ' + ${it.freeQty.toInt()}' : ''}";

                      return TableRow(
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10))),
                        children: [
                          _td("${idx + 1}"),
                          _td(it.name, isLeft: true, isBold: true),
                          _td(it.packing),
                          _td(it.batch),
                          _td(it.exp),
                          _td(qtyDisp, isBold: true, color: const Color(0xFFF59E0B)),
                          _td("₹${it.purchaseRate.toStringAsFixed(2)}"),
                          _td("${it.gstRate.toInt()}%"),
                          _td("₹${it.total.toStringAsFixed(2)}", isBold: true, color: Colors.greenAccent),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_note_rounded, size: 16, color: Color(0xFF38BDF8)),
                                onPressed: () {
                                  final med = webPh.medicines.firstWhere(
                                    (m) => m.id == it.medicineID || m.name == it.name,
                                    orElse: () => Medicine(id: it.medicineID, name: it.name, packing: it.packing),
                                  );
                                  _openPurchaseItemDialog(webPh, med, itemToEdit: it, editIndex: idx);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                                onPressed: () => setState(() => purchaseItems.removeAt(idx)),
                              ),
                            ],
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _th(String t, {bool isLeft = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
    child: Text(t, textAlign: isLeft ? TextAlign.left : TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 9.5, fontWeight: FontWeight.bold)),
  );

  Widget _td(String t, {bool isLeft = false, bool isBold = false, Color color = Colors.white}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
    child: Text(t, textAlign: isLeft ? TextAlign.left : TextAlign.center, style: TextStyle(color: color, fontSize: 11, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
  );

  Widget _buildSupplierCard(PharoahWebManager webPh) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.business_rounded, color: Color(0xFFF59E0B), size: 18),
              SizedBox(width: 8),
              Text("SUPPLIER / DISTRIBUTOR", style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ],
          ),
          const Divider(color: Colors.white10, height: 20),
          if (selectedSupplier != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x66F59E0B)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(selectedSupplier!.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                        const SizedBox(height: 3),
                        Text("GST: ${selectedSupplier!.gst} | City: ${selectedSupplier!.city}", style: const TextStyle(color: Colors.white54, fontSize: 10)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: Colors.redAccent),
                    onPressed: () => setState(() => selectedSupplier = null),
                  ),
                ],
              ),
            )
          else
            Autocomplete<Party>(
              displayStringForOption: (p) => "${p.name} (${p.city})",
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) return const Iterable.empty();
                return webPh.parties.where((p) =>
                    p.group == "Sundry Creditors" &&
                    (p.name.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                     p.city.toLowerCase().contains(textEditingValue.text.toLowerCase())));
              },
              onSelected: (p) => setState(() => selectedSupplier = p),
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: "Select Supplier / Distributor...",
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFFF59E0B), size: 18),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildGrandTotalCard(PharoahWebManager webPh) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF19243B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x66F59E0B), width: 1.2),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("INWARD SUMMARY", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const Divider(color: Colors.white10, height: 20),
          _sumRow("Taxable Inward Value", "₹${totalTaxable.toStringAsFixed(2)}"),
          _sumRow("Input GST (ITC)", "₹${totalITC.toStringAsFixed(2)}"),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Extra Discount (-)", style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
              SizedBox(
                width: 80,
                height: 30,
                child: TextField(
                  controller: extraDiscC,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black38,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                  ),
                ),
              ),
            ],
          ),
          _sumRow("Round Off", "₹${roundOff.toStringAsFixed(2)}"),
          const Divider(color: Colors.white24, height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("TOTAL INWARD VALUE", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
              Text(
                "₹${finalGrandTotal.toStringAsFixed(0)}.00",
                style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 24, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: isSaving ? null : () => _savePurchase(webPh),
              icon: isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.check_circle_rounded, size: 18),
              label: Text(
                isSaving ? "SAVING..." : "SAVE & ADD STOCK",
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sumRow(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
    ]),
  );

  Widget _dialogInput(String label, TextEditingController ctrl, {bool isNum = false, bool isCaps = false, bool isHighlight = false, Function(String)? onChanged}) {
    return TextField(
      controller: ctrl,
      onChanged: onChanged,
      keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      textCapitalization: isCaps ? TextCapitalization.characters : TextCapitalization.none,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 8.5, fontWeight: FontWeight.bold),
        filled: true,
        fillColor: isHighlight ? const Color(0x33F59E0B) : Colors.black26,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: isHighlight ? const BorderSide(color: Color(0xFFF59E0B)) : BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    );
  }
}
