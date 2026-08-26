import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../pharoah_web_manager.dart';
import '../../web_cloud_config.dart';
import 'package:http/http.dart' as http;

class WebNewSaleView extends StatefulWidget {
  final VoidCallback onBack;

  const WebNewSaleView({super.key, required this.onBack});

  @override
  State<WebNewSaleView> createState() => _WebNewSaleViewState();
}

class _WebNewSaleViewState extends State<WebNewSaleView> {
  final billNoC = TextEditingController();
  final extraDiscC = TextEditingController(text: "0");
  DateTime billDate = DateTime.now();
  String paymentMode = "CASH";
  
  Map<String, dynamic>? selectedParty;
  Map<String, dynamic>? selectedMed;

  final batchC = TextEditingController();
  final expC = TextEditingController(text: "12/26");
  final mrpC = TextEditingController(text: "0.0");
  final rateC = TextEditingController(text: "0.0");
  final qtyC = TextEditingController(text: "1");
  final freeC = TextEditingController(text: "0");
  final gstC = TextEditingController(text: "12");
  final discPerC = TextEditingController(text: "0.0");
  String rateType = "A";

  List<Map<String, dynamic>> billItems = [];
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final webPh = Provider.of<PharoahWebManager>(context, listen: false);
    int nextNum = webPh.sales.length + 101;
    billNoC.text = "INV-$nextNum";
  }

  @override
  void dispose() {
    billNoC.dispose();
    extraDiscC.dispose();
    batchC.dispose();
    expC.dispose();
    mrpC.dispose();
    rateC.dispose();
    qtyC.dispose();
    freeC.dispose();
    gstC.dispose();
    discPerC.dispose();
    super.dispose();
  }

  void _onProductSelected(Map<String, dynamic> med) {
    setState(() {
      selectedMed = med;
      mrpC.text = (med['mrp'] as num? ?? 0).toDouble().toStringAsFixed(2);
      gstC.text = (med['gst'] as num? ?? 12).toString();
      rateType = "A";
      rateC.text = (med['rateA'] as num? ?? (med['mrp'] as num? ?? 0)).toDouble().toStringAsFixed(2);
      batchC.text = "AUTO";
      expC.text = "12/26";
    });
  }

  void _applyRateLevel(String type) {
    if (selectedMed == null) return;
    setState(() {
      rateType = type;
      if (type == "A") {
        rateC.text = (selectedMed!['rateA'] as num? ?? selectedMed!['mrp'] ?? 0).toDouble().toStringAsFixed(2);
      } else if (type == "B") {
        rateC.text = (selectedMed!['rateB'] as num? ?? selectedMed!['mrp'] ?? 0).toDouble().toStringAsFixed(2);
      } else {
        double mrp = (selectedMed!['mrp'] as num? ?? 0).toDouble();
        double gst = (selectedMed!['gst'] as num? ?? 12).toDouble();
        double baseTaxable = mrp / (1 + (gst / 100));
        rateC.text = (baseTaxable * 0.92).toStringAsFixed(2);
      }
    });
  }

  void _addItemToCart() {
    if (selectedMed == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a product first!")));
      return;
    }
    double q = double.tryParse(qtyC.text) ?? 1;
    double freeQ = double.tryParse(freeC.text) ?? 0;
    double r = double.tryParse(rateC.text) ?? 0;
    double dPer = double.tryParse(discPerC.text) ?? 0;
    double gPer = double.tryParse(gstC.text) ?? 12;

    if (q <= 0) return;

    double gross = q * r;
    double discAmt = gross * (dPer / 100);
    double taxable = gross - discAmt;
    double taxAmt = taxable * (gPer / 100);
    double total = taxable + taxAmt;

    final webPh = Provider.of<PharoahWebManager>(context, listen: false);
    String shopState = (webPh.companyProfile['state'] ?? 'Rajasthan').toString().toLowerCase();
    String partyState = (selectedParty != null ? selectedParty!['state'] ?? 'Rajasthan' : 'Rajasthan').toString().toLowerCase();
    bool isLocal = shopState == partyState;

    setState(() {
      billItems.add({
        'srNo': billItems.length + 1,
        'medicineID': selectedMed!['id'] ?? selectedMed!['systemId'] ?? 'temp',
        'name': (selectedMed!['name'] ?? 'UNKNOWN').toString(),
        'packing': (selectedMed!['packing'] ?? 'N/A').toString(),
        'batch': batchC.text.trim().toUpperCase(),
        'exp': expC.text.trim(),
        'hsn': (selectedMed!['hsnCode'] ?? '3004').toString(),
        'mrp': double.tryParse(mrpC.text) ?? 0.0,
        'qty': q,
        'freeQty': freeQ,
        'rate': r,
        'gstRate': gPer,
        'taxable': taxable,
        'cgst': isLocal ? taxAmt / 2 : 0.0,
        'sgst': isLocal ? taxAmt / 2 : 0.0,
        'igst': isLocal ? 0.0 : taxAmt,
        'discountPer': dPer,
        'discountRupees': discAmt,
        'total': total,
      });

      selectedMed = null;
      qtyC.text = "1";
      freeC.text = "0";
      discPerC.text = "0.0";
    });
  }

  double get subTotal => billItems.fold(0.0, (sum, it) => sum + (it['total'] as num).toDouble());
  double get totalTaxable => billItems.fold(0.0, (sum, it) => sum + (it['taxable'] as num).toDouble());
  double get totalCGST => billItems.fold(0.0, (sum, it) => sum + (it['cgst'] as num).toDouble());
  double get totalSGST => billItems.fold(0.0, (sum, it) => sum + (it['sgst'] as num).toDouble());
  double get totalIGST => billItems.fold(0.0, (sum, it) => sum + (it['igst'] as num).toDouble());
  double get extraDiscount => double.tryParse(extraDiscC.text) ?? 0.0;
  double get rawGrandTotal => (subTotal - extraDiscount);
  double get finalGrandTotal => rawGrandTotal.roundToDouble();
  double get roundOff => double.parse((finalGrandTotal - rawGrandTotal).toStringAsFixed(2));

  Future<void> _saveInvoice(PharoahWebManager webPh) async {
    if (billItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot save empty bill!")));
      return;
    }

    setState(() => isSaving = true);

    String pName = selectedParty != null ? selectedParty!['name'].toString() : "CASH";
    String pGst = selectedParty != null ? (selectedParty!['gst'] ?? "N/A").toString() : "N/A";
    String pState = selectedParty != null ? (selectedParty!['state'] ?? "Rajasthan").toString() : "Rajasthan";

    final newSale = {
      'id': 'WEB-S-${DateTime.now().millisecondsSinceEpoch}',
      'billNo': billNoC.text.trim(),
      'partyId': selectedParty != null ? selectedParty!['id'] : 'cash',
      'partyName': pName,
      'partyGstin': pGst,
      'partyState': pState,
      'date': billDate.toIso8601String(),
      'paymentMode': paymentMode,
      'totalAmount': finalGrandTotal,
      'extraDiscount': extraDiscount,
      'roundOff': roundOff,
      'status': 'Active',
      'items': billItems,
      'sourceTag': 'WEB-PORTAL',
    };

    // 1. Update in Web Memory via clean manager method
    webPh.addSaleAndSync(newSale);

    // 2. Push Updated Database to Cloud Relay
    try {
      final payload = {
        "action": WebCloudConfig.actionPushStore,
        "storeToken": webPh.activeStoreToken,
        "companyId": webPh.companyProfile['id'] ?? 'STORE',
        "companyName": webPh.companyName,
        "adminUser": webPh.activeUsername,
        "adminPassword": webPh.activePassword,
        "fy": webPh.financialYear,
        "registryProfile": webPh.companyProfile,
        "files": {
          "sales.json": jsonEncode(webPh.sales),
          "meds.json": jsonEncode(webPh.medicines),
          "parts.json": jsonEncode(webPh.parties),
          "purc.json": jsonEncode(webPh.purchases),
          "vouc.json": jsonEncode(webPh.vouchers),
          "s_challan.json": jsonEncode(webPh.saleChallans),
          "p_challan.json": jsonEncode(webPh.purchaseChallans),
          "s_return.json": jsonEncode(webPh.saleReturns),
          "p_return.json": jsonEncode(webPh.purchaseReturns),
        },
        "syncedAt": DateTime.now().toIso8601String(),
      };

      await http.post(
        Uri.parse(WebCloudConfig.cloudRelayEndpoint),
        headers: WebCloudConfig.standardHeaders,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 20));

    } catch (e) {
      debugPrint("Web Sync Push Error: $e");
    }

    setState(() => isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Invoice ${billNoC.text} Saved & Synced!"), backgroundColor: Colors.green),
      );
      widget.onBack();
    }
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
                  _buildProductInputCard(webPh),
                  const SizedBox(height: 16),
                  _buildItemsDataTable(),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  _buildCustomerCard(webPh),
                  const SizedBox(height: 16),
                  _buildGrandTotalSummaryCard(webPh),
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
            label: const Text("BACK TO MODULES", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 18),
          const Icon(Icons.receipt_long_rounded, color: Color(0xFF38BDF8), size: 22),
          const SizedBox(width: 10),
          const Text(
            "NEW TAX INVOICE (SALE BILLING)",
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
          const Spacer(),
          SizedBox(
            width: 130,
            height: 36,
            child: TextField(
              controller: billNoC,
              style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w900, fontSize: 12),
              decoration: InputDecoration(
                labelText: "BILL NO",
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

  Widget _buildProductInputCard(PharoahWebManager webPh) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.4), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 5,
                child: Autocomplete<Map<String, dynamic>>(
                  displayStringForOption: (option) => "${option['name']} (${option['packing']})",
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty) return const Iterable.empty();
                    return webPh.medicines.where((m) =>
                        (m['name'] ?? '').toString().toLowerCase().contains(textEditingValue.text.toLowerCase())).cast<Map<String, dynamic>>();
                  },
                  onSelected: _onProductSelected,
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: "SEARCH PRODUCT / MEDICINE",
                        labelStyle: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                        hintText: "Type medicine name (e.g. DOLO, PAN 40)...",
                        hintStyle: const TextStyle(color: Colors.white24, fontSize: 11),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF38BDF8), size: 18),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: _miniInput("BATCH", batchC)),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: _miniInput("EXPIRY", expC)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ratePill("RATE A", rateType == "A", () => _applyRateLevel("A")),
              const SizedBox(width: 6),
              _ratePill("RATE B", rateType == "B", () => _applyRateLevel("B")),
              const SizedBox(width: 6),
              _ratePill("RATE C", rateType == "C", () => _applyRateLevel("C")),
              const SizedBox(width: 14),

              Expanded(child: _miniInput("MRP ₹", mrpC, isNum: true)),
              const SizedBox(width: 8),
              Expanded(child: _miniInput("RATE ₹", rateC, isNum: true)),
              const SizedBox(width: 8),
              Expanded(child: _miniInput("QTY", qtyC, isNum: true, isHighlight: true)),
              const SizedBox(width: 8),
              Expanded(child: _miniInput("FREE", freeC, isNum: true)),
              const SizedBox(width: 8),
              Expanded(child: _miniInput("DISC %", discPerC, isNum: true)),
              const SizedBox(width: 8),
              Expanded(child: _miniInput("GST %", gstC, isNum: true)),
              const SizedBox(width: 14),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: _addItemToCart,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text("ADD ITEM", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ratePill(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.black26,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? const Color(0xFF60A5FA) : Colors.white10),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontSize: 9.5, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _miniInput(String label, TextEditingController ctrl, {bool isNum = false, bool isHighlight = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: TextStyle(color: isHighlight ? Colors.cyanAccent : Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isHighlight ? Colors.cyanAccent : Colors.white54, fontSize: 8.5, fontWeight: FontWeight.bold),
        filled: true,
        fillColor: isHighlight ? const Color(0xFF2563EB).withOpacity(0.2) : Colors.black26,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    );
  }

  Widget _buildItemsDataTable() {
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
              const Icon(Icons.shopping_cart_outlined, color: Colors.cyanAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                "INVOICE ITEMS (${billItems.length})",
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              const Spacer(),
              if (billItems.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => billItems.clear()),
                  child: const Text("Clear All", style: TextStyle(color: Colors.redAccent, fontSize: 10)),
                ),
            ],
          ),
          const Divider(color: Colors.white10, height: 20),

          if (billItems.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text("Cart is empty. Search and add products above.", style: TextStyle(color: Colors.white38, fontSize: 12)),
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
                    6: FixedColumnWidth(70),
                    7: FixedColumnWidth(50),
                    8: FixedColumnWidth(85),
                    9: FixedColumnWidth(45),
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
                        _th("RATE"),
                        _th("GST%"),
                        _th("TOTAL"),
                        _th("DEL"),
                      ],
                    ),
                    ...billItems.asMap().entries.map((entry) {
                      int idx = entry.key;
                      var it = entry.value;
                      String qtyDisp = "${(it['qty'] as num).toInt()}${it['freeQty'] > 0 ? ' + ${it['freeQty'].toInt()}' : ''}";

                      return TableRow(
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white05))),
                        children: [
                          _td("${idx + 1}"),
                          _td(it['name'].toString(), isLeft: true, isBold: true),
                          _td(it['packing'].toString()),
                          _td(it['batch'].toString()),
                          _td(it['exp'].toString()),
                          _td(qtyDisp, isBold: true, color: Colors.cyanAccent),
                          _td("₹${(it['rate'] as num).toStringAsFixed(2)}"),
                          _td("${(it['gstRate'] as num).toInt()}%"),
                          _td("₹${(it['total'] as num).toStringAsFixed(2)}", isBold: true, color: Colors.greenAccent),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                            onPressed: () => setState(() => billItems.removeAt(idx)),
                          ),
                        ],
                      );
                    }).toList(),
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

  Widget _buildCustomerCard(PharoahWebManager webPh) {
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
            children: const [
              Icon(Icons.person_rounded, color: Color(0xFF38BDF8), size: 18),
              SizedBox(width: 8),
              Text("CUSTOMER / CONSIGNEE", style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ],
          ),
          const Divider(color: Colors.white10, height: 20),

          if (selectedParty != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.4))),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(selectedParty!['name'].toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                        const SizedBox(height: 3),
                        Text("GST: ${selectedParty!['gst'] ?? 'N/A'} | State: ${selectedParty!['state'] ?? 'Rajasthan'}", style: const TextStyle(color: Colors.white54, fontSize: 10)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: Colors.redAccent),
                    onPressed: () => setState(() => selectedParty = null),
                  ),
                ],
              ),
            )
          else
            Autocomplete<Map<String, dynamic>>(
              displayStringForOption: (option) => (option['name'] ?? '').toString(),
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) return const Iterable.empty();
                return webPh.parties.where((p) =>
                    (p['name'] ?? '').toString().toLowerCase().contains(textEditingValue.text.toLowerCase())).cast<Map<String, dynamic>>();
              },
              onSelected: (party) => setState(() => selectedParty = party),
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: "Select Customer (Default: CASH)...",
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                    prefixIcon: const Icon(Icons.person_search, color: Colors.cyanAccent, size: 18),
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

  Widget _buildGrandTotalSummaryCard(PharoahWebManager webPh) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF19243B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.4), width: 1.2),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("BILL CALCULATION SUMMARY", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const Divider(color: Colors.white10, height: 20),

          _sumRow("Items Taxable Value", "₹${totalTaxable.toStringAsFixed(2)}"),
          if (totalCGST > 0) _sumRow("Total CGST (+)", "₹${totalCGST.toStringAsFixed(2)}"),
          if (totalSGST > 0) _sumRow("Total SGST (+)", "₹${totalSGST.toStringAsFixed(2)}"),
          if (totalIGST > 0) _sumRow("Total IGST (+)", "₹${totalIGST.toStringAsFixed(2)}"),
          
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

          _sumRow("Auto Round Off", "₹${roundOff.toStringAsFixed(2)}"),
          const Divider(color: Colors.white24, height: 25),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("NET PAYABLE", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
              Text(
                "₹${finalGrandTotal.toStringAsFixed(0)}.00",
                style: const TextStyle(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 25),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: isSaving ? null : () => _saveInvoice(webPh),
              icon: isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_rounded, size: 20),
              label: Text(
                isSaving ? "SAVING & SYNCING..." : "SAVE & SYNC INVOICE",
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
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
}
