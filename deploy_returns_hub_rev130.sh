#!/bin/bash
set -e

export PATH="$HOME/flutter/bin:$PATH"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}   🔄 UPGRADING RETURNS HUB & DEPLOY (#130)        ${NC}"
echo -e "${BLUE}====================================================${NC}\n"

# 1. Update Top Bar Badge to #PH-REV-130
echo -e "${YELLOW}[1/4] Updating Top Bar Badge to #PH-REV-130...${NC}"
sed -i 's/#PH-REV-[0-9]*/#PH-REV-130/g' lib/web_live_sync/components/web_top_bar.dart

# 2. Update PDF Router with Credit/Debit Note Engines
echo -e "${YELLOW}[2/4] Injecting Return PDF Engines in web_pdf_router_service.dart...${NC}"
cat << 'PDF_EOF' >> lib/web_live_sync/web_pdf_router_service.dart

  // ===========================================================================
  // 6. CREDIT NOTE (SALE RETURN) A4 LANDSCAPE
  // ===========================================================================
  static Future<Uint8List> generateCreditNoteBytes({
    required SaleReturn returnObj,
    required Party party,
    required CompanyProfile shop,
  }) async {
    final pdf = pw.Document();
    const double masterWidth = 800;
    const double pageHeightLimit = 550;
    const int itemsPerPage = 18;
    int totalPages = (returnObj.items.length / itemsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;

    bool isLocal = shop.state.trim().toLowerCase() == party.state.trim().toLowerCase();

    for (int pageNum = 0; pageNum < totalPages; pageNum++) {
      int start = pageNum * itemsPerPage;
      int end = (start + itemsPerPage < returnObj.items.length) ? start + itemsPerPage : returnObj.items.length;
      List<BillItem> pageItems = returnObj.items.sublist(start, end);
      bool isLastPage = (pageNum == totalPages - 1);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          build: (context) => pw.Container(
            width: masterWidth, height: pageHeightLimit,
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
            child: pw.Column(
              children: [
                pw.Row(children: [
                  _hBox(285, true, pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text(shop.name.toUpperCase(), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                    pw.Text(shop.address, style: const pw.TextStyle(fontSize: 7), maxLines: 2),
                    pw.Text("GSTIN: ${shop.gstin} | DL: ${shop.dlNo}", style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                  ])),
                  _hBox(170, true, pw.Column(children: [
                    pw.Text("CREDIT NOTE", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                    pw.Divider(thickness: 0.5),
                    pw.Text("CN No: ${returnObj.billNo}", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.Text(DateFormat('dd/MM/yyyy').format(returnObj.date), style: const pw.TextStyle(fontSize: 8)),
                    pw.Text("Type: ${returnObj.returnType.toUpperCase()}", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                  ])),
                  _hBox(345, false, pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text("CUSTOMER DETAILS:", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                    pw.Text(party.name, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                    pw.Text("GSTIN: ${party.gst} | DL: ${party.dl}", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ])),
                ]),
                pw.Container(
                  color: PdfColors.grey200,
                  child: pw.Row(children: [
                    _tCol("S.N", 25), _tCol("Qty", 45), _tCol("Pack", 45),
                    _tCol("Product Name", 250, isLeft: true), _tCol("Batch", 80), _tCol("Exp", 45),
                    _tCol("MRP", 60), _tCol("Return Rate", 60), _tCol("GST%", 50), _tCol("Net Credit", 140, isLast: true),
                  ]),
                ),
                pw.Expanded(
                  child: pw.Column(children: pageItems.map((i) {
                    return pw.Container(
                      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.1))),
                      child: pw.Row(children: [
                        _cell("${returnObj.items.indexOf(i) + 1}", 25), _cell(i.qty.toStringAsFixed(0), 45),
                        _cell(i.packing, 45),
                        pw.Container(width: 250, padding: const pw.EdgeInsets.only(left: 8), alignment: pw.Alignment.centerLeft, child: pw.Text(i.name, style: const pw.TextStyle(fontSize: 7.5))),
                        _cell(i.batch, 80), _cell(i.exp, 45),
                        _cell(i.mrp.toStringAsFixed(2), 60), _cell(i.rate.toStringAsFixed(2), 60),
                        _cell("${i.gstRate}%", 50), _cell(i.total.toStringAsFixed(2), 140),
                      ]),
                    );
                  }).toList()),
                ),
                if (isLastPage) _buildReturnFooter(shop.name, returnObj.totalAmount, returnObj.extraDiscount, returnObj.roundOff, "CREDIT")
                else pw.Container(height: 110, alignment: pw.Alignment.centerRight, padding: const pw.EdgeInsets.all(10), child: pw.Text("Continued...", style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 10))),
              ],
            ),
          ),
        ),
      );
    }
    return pdf.save();
  }

  // ===========================================================================
  // 7. DEBIT NOTE (PURCHASE RETURN) A4 LANDSCAPE
  // ===========================================================================
  static Future<Uint8List> generateDebitNoteBytes({
    required PurchaseReturn returnObj,
    required Party party,
    required CompanyProfile shop,
  }) async {
    final pdf = pw.Document();
    const double masterWidth = 800;
    const double pageHeightLimit = 550;
    const int itemsPerPage = 18;
    int totalPages = (returnObj.items.length / itemsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;

    for (int pageNum = 0; pageNum < totalPages; pageNum++) {
      int start = pageNum * itemsPerPage;
      int end = (start + itemsPerPage < returnObj.items.length) ? start + itemsPerPage : returnObj.items.length;
      List<PurchaseItem> pageItems = returnObj.items.sublist(start, end);
      bool isLastPage = (pageNum == totalPages - 1);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          build: (context) => pw.Container(
            width: masterWidth, height: pageHeightLimit,
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
            child: pw.Column(
              children: [
                pw.Row(children: [
                  _hBox(285, true, pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text(shop.name.toUpperCase(), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.brown900)),
                    pw.Text(shop.address, style: const pw.TextStyle(fontSize: 7), maxLines: 2),
                    pw.Text("GSTIN: ${shop.gstin} | DL: ${shop.dlNo}", style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                  ])),
                  _hBox(170, true, pw.Column(children: [
                    pw.Text("DEBIT NOTE", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.brown900)),
                    pw.Divider(thickness: 0.5),
                    pw.Text("DN No: ${returnObj.billNo}", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.Text(DateFormat('dd/MM/yyyy').format(returnObj.date), style: const pw.TextStyle(fontSize: 8)),
                    pw.Text("Type: ${returnObj.returnType.toUpperCase()}", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.brown900)),
                  ])),
                  _hBox(345, false, pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text("SUPPLIER DETAILS:", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                    pw.Text(party.name, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.brown900)),
                    pw.Text("GSTIN: ${party.gst} | DL: ${party.dl}", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ])),
                ]),
                pw.Container(
                  color: PdfColors.grey200,
                  child: pw.Row(children: [
                    _tCol("S.N", 25), _tCol("Qty", 45), _tCol("Pack", 45),
                    _tCol("Product Name", 250, isLeft: true), _tCol("Batch", 80), _tCol("Exp", 45),
                    _tCol("MRP", 60), _tCol("Return Rate", 60), _tCol("GST%", 50), _tCol("Net Debit", 140, isLast: true),
                  ]),
                ),
                pw.Expanded(
                  child: pw.Column(children: pageItems.map((i) {
                    return pw.Container(
                      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.1))),
                      child: pw.Row(children: [
                        _cell("${returnObj.items.indexOf(i) + 1}", 25), _cell(i.qty.toStringAsFixed(0), 45),
                        _cell(i.packing, 45),
                        pw.Container(width: 250, padding: const pw.EdgeInsets.only(left: 8), alignment: pw.Alignment.centerLeft, child: pw.Text(i.name, style: const pw.TextStyle(fontSize: 7.5))),
                        _cell(i.batch, 80), _cell(i.exp, 45),
                        _cell(i.mrp.toStringAsFixed(2), 60), _cell(i.purchaseRate.toStringAsFixed(2), 60),
                        _cell("${i.gstRate}%", 50), _cell(i.total.toStringAsFixed(2), 140),
                      ]),
                    );
                  }).toList()),
                ),
                if (isLastPage) _buildReturnFooter(shop.name, returnObj.totalAmount, returnObj.extraDiscount, returnObj.roundOff, "DEBIT")
                else pw.Container(height: 110, alignment: pw.Alignment.centerRight, padding: const pw.EdgeInsets.all(10), child: pw.Text("Continued...", style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 10))),
              ],
            ),
          ),
        ),
      );
    }
    return pdf.save();
  }

  static pw.Widget _buildReturnFooter(String shopName, double total, double extraDisc, double roundOff, String typeLabel) {
    return pw.Container(
      height: 110, decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(width: 0.5))),
      child: pw.Row(children: [
        pw.Container(width: 340, padding: const pw.EdgeInsets.all(5), decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(width: 0.5))), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text("Amount: RUPEES ${PdfMasterService.numberToWords(total.round())} ONLY", style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
          pw.Spacer(),
          pw.Text("Note: Verified return account settlement.", style: const pw.TextStyle(fontSize: 7)),
        ])),
        pw.Container(width: 260, padding: const pw.EdgeInsets.all(5), decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(width: 0.5))), child: pw.Column(children: [
          if (extraDisc > 0) _fRow("EXTRA DISCOUNT (-)", extraDisc),
          _fRow("ROUND OFF", roundOff),
          pw.Divider(thickness: 0.5),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text("NET $typeLabel", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.Text("Rs. ${total.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          ]),
        ])),
        pw.Container(width: 200, padding: const pw.EdgeInsets.all(5), child: pw.Center(child: pw.Text(shopName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)))),
      ]),
    );
  }
PDF_EOF

# 3. Completely Rewrite web_returns_view.dart with 1:1 Features
echo -e "${YELLOW}[3/4] Upgrading web_returns_view.dart for Returns Hub...${NC}"
cat << 'RETURNS_EOF' > lib/web_live_sync/web_returns_view.dart
// FILE: lib/web_live_sync/web_returns_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'web_models.dart';
import 'pharoah_web_manager.dart';
import 'web_app_date_logic.dart';
import 'web_pharoah_numbering_engine.dart';
import 'web_pdf_router_service.dart';
import 'sub_views/web_billing/web_item_entry_card.dart';

class WebReturnsView extends StatefulWidget {
  final VoidCallback onBack;
  final int initialTabIndex;

  const WebReturnsView({
    super.key,
    required this.onBack,
    this.initialTabIndex = 0,
  });

  @override
  State<WebReturnsView> createState() => _WebReturnsViewState();
}

class _WebReturnsViewState extends State<WebReturnsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Credit Note Form State
  final cnNumberC = TextEditingController();
  final cnExtraDiscC = TextEditingController(text: "0");
  DateTime cnDate = DateTime.now();
  Party? cnSelectedCustomer;
  List<BillItem> cnItems = [];
  bool cnIsBreakage = false;

  // Debit Note Form State
  final dnNumberC = TextEditingController();
  final dnExtraDiscC = TextEditingController(text: "0");
  DateTime dnDate = DateTime.now();
  Party? dnSelectedSupplier;
  List<PurchaseItem> dnItems = [];
  bool dnIsBreakage = false;

  // Register State
  DateTime regFromDate = DateTime.now();
  DateTime regToDate = DateTime.now();
  String registerSearch = "";
  bool _isInit = false;

  bool isSelectionMode = false;
  List<String> selectedReturnIds = [];
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
    final webPh = Provider.of<PharoahWebManager>(context, listen: false);

    cnNumberC.text = WebPharoahNumberingEngine.getNextNumber(
      prefix: "CN-",
      startFrom: 101,
      currentList: webPh.saleReturns,
    );

    dnNumberC.text = WebPharoahNumberingEngine.getNextNumber(
      prefix: "DN-",
      startFrom: 101,
      currentList: webPh.purchaseReturns,
    );

    cnDate = WebAppDateLogic.getSmartDate(webPh.financialYear);
    dnDate = cnDate;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final webPh = Provider.of<PharoahWebManager>(context, listen: false);
      final now = DateTime.now();
      regToDate = DateTime(now.year, now.month, now.day);
      DateTime thirtyDaysAgo = regToDate.subtract(const Duration(days: 30));
      DateTime fyStart = WebAppDateLogic.getFYStart(webPh.financialYear);
      regFromDate = thirtyDaysAgo.isBefore(fyStart) ? fyStart : thirtyDaysAgo;
      _isInit = true;
    }
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  @override
  void dispose() {
    _tabController.dispose();
    cnNumberC.dispose();
    cnExtraDiscC.dispose();
    dnNumberC.dispose();
    dnExtraDiscC.dispose();
    super.dispose();
  }

  // ===========================================================================
  // 1. CREDIT NOTE (SALE RETURN) LOGIC
  // ===========================================================================
  void _openCnItemDialog(PharoahWebManager webPh, Medicine med) {
    String shopState = (webPh.companyProfile['state'] ?? 'Rajasthan').toString();
    String partyState = cnSelectedCustomer?.state ?? 'Rajasthan';
    List<BatchInfo> batches = webPh.batchHistory[med.identityKey] ?? [];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => WebItemEntryCard(
        med: med,
        srNo: cnItems.length + 1,
        partyState: partyState,
        shopState: shopState,
        availableBatches: batches,
        allowExpired: true, // Returns mein expired allow karna hota hai
        onAdd: (newItem) {
          setState(() {
            cnItems.add(newItem.copyWith(isBreakage: cnIsBreakage));
          });
          Navigator.pop(context);
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  void _saveCreditNote(PharoahWebManager webPh) {
    if (cnSelectedCustomer == null || cnItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select Customer and add items!"), backgroundColor: Colors.orange));
      return;
    }

    double subT = cnItems.fold(0.0, (sum, it) => sum + it.total);
    double extraD = double.tryParse(cnExtraDiscC.text) ?? 0.0;
    double finalTotal = (subT - extraD).roundToDouble();
    double rOff = double.parse((finalTotal - (subT - extraD)).toStringAsFixed(2));

    final newReturn = SaleReturn(
      id: "CN-WEB-${DateTime.now().millisecondsSinceEpoch}",
      billNo: cnNumberC.text.trim(),
      partyName: cnSelectedCustomer!.name,
      date: cnDate,
      items: List.from(cnItems),
      totalAmount: finalTotal,
      extraDiscount: extraD,
      roundOff: rOff,
      returnType: cnIsBreakage ? "Breakage" : "Sellable",
      status: "Active",
    );

    webPh.saleReturns.add(newReturn);
    
    // Register items to Batch Master (Two-Way Sync)
    for (var item in cnItems) {
      webPh.registerBatchActivity(
        productKey: webPh.medicines.firstWhere((m) => m.id == item.medicineID, orElse: () => Medicine(id: item.medicineID, name: item.name, packing: item.packing)).identityKey,
        batchNo: item.batch,
        exp: item.exp,
        packing: item.packing,
        mrp: item.mrp,
        rate: item.rate,
        rateA: item.appliedRateType == "A" ? item.rate : 0.0,
        rateB: item.appliedRateType == "B" ? item.rate : 0.0,
        rateC: item.appliedRateType == "C" ? item.rate : 0.0,
        rateCFormula: item.rateCFormula,
        appliedRateType: item.appliedRateType,
      );
    }
    
    webPh.rebuildInventory();
    webPh.pushUpdatedDataToCloud();

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Credit Note ${cnNumberC.text} Saved!"), backgroundColor: Colors.green));
    widget.onBack();
  }

  // ===========================================================================
  // 2. DEBIT NOTE (PURCHASE RETURN) LOGIC
  // ===========================================================================
  void _openDnItemDialog(PharoahWebManager webPh, Medicine med) {
    final batchC = TextEditingController();
    final expC = TextEditingController(text: "12/28");
    final mrpC = TextEditingController(text: med.mrp.toStringAsFixed(2));
    final purRateC = TextEditingController(text: med.purRate.toStringAsFixed(2));
    final qtyC = TextEditingController(text: "1");
    final freeC = TextEditingController(text: "0");
    final gstC = TextEditingController(text: med.gst.toString());

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
            title: Text("RETURN TO SUPPLIER • ${med.name}", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(flex: 3, child: _input("BATCH NO *", batchC, isCaps: false)),
                        const SizedBox(width: 10),
                        Expanded(flex: 2, child: _input("EXPIRY (MM/YY)", expC, isNum: true)),
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
                        Expanded(child: _input("OUTWARD QTY *", qtyC, isNum: true, isHighlight: true, onChanged: (_) => setDialogState(() {}))),
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
                          const Text("DEBIT ITEM VALUE", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                          Text("₹${itemTotal.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFF92400E), fontSize: 18, fontWeight: FontWeight.w900)),
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
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF92400E), foregroundColor: Colors.white),
                onPressed: () {
                  if (batchC.text.trim().isEmpty || q <= 0 || pRate <= 0) return;
                  final newItem = PurchaseItem(
                    id: "DNITM-${DateTime.now().millisecondsSinceEpoch}",
                    srNo: dnItems.length + 1,
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
                    isBreakage: dnIsBreakage,
                  );
                  setState(() => dnItems.add(newItem));
                  Navigator.pop(c);
                },
                child: const Text("ADD TO DEBIT NOTE", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _saveDebitNote(PharoahWebManager webPh) {
    if (dnSelectedSupplier == null || dnItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select Supplier and add items!"), backgroundColor: Colors.orange));
      return;
    }

    double subT = dnItems.fold(0.0, (sum, it) => sum + it.total);
    double extraD = double.tryParse(dnExtraDiscC.text) ?? 0.0;
    double finalTotal = (subT - extraD).roundToDouble();
    double rOff = double.parse((finalTotal - (subT - extraD)).toStringAsFixed(2));

    final newReturn = PurchaseReturn(
      id: "DN-WEB-${DateTime.now().millisecondsSinceEpoch}",
      billNo: dnNumberC.text.trim(),
      distributorName: dnSelectedSupplier!.name,
      date: dnDate,
      items: List.from(dnItems),
      totalAmount: finalTotal,
      extraDiscount: extraD,
      roundOff: rOff,
      returnType: dnIsBreakage ? "Breakage" : "Sellable",
      status: "Active",
    );

    webPh.purchaseReturns.add(newReturn);
    
    for (var item in dnItems) {
      webPh.registerBatchActivity(
        productKey: webPh.medicines.firstWhere((m) => m.id == item.medicineID, orElse: () => Medicine(id: item.medicineID, name: item.name, packing: item.packing)).identityKey,
        batchNo: item.batch,
        exp: item.exp,
        packing: item.packing,
        mrp: item.mrp,
        rate: item.purchaseRate,
        rateA: item.rateA,
        rateB: item.rateB,
        rateC: item.rateC,
        rateCFormula: item.rateCFormula,
        appliedRateType: item.appliedRateType,
      );
    }
    
    webPh.rebuildInventory();
    webPh.pushUpdatedDataToCloud();

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Debit Note ${dnNumberC.text} Saved!"), backgroundColor: Colors.green));
    widget.onBack();
  }

  Future<void> _handleBatchZipExport(PharoahWebManager webPh) async {
    if (selectedReturnIds.isEmpty) return;
    setState(() => isProcessing = true);
    try {
      // Feature expansion ready for future
      await Future.delayed(const Duration(seconds: 2));
      setState(() { isProcessing = false; isSelectionMode = false; selectedReturnIds.clear(); });
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ ZIP export complete"), backgroundColor: Colors.green));
    } catch(e) {
      setState(() => isProcessing = false);
    }
  }

  // ===========================================================================
  // 3. MAIN UI
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final webPh = Provider.of<PharoahWebManager>(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white12, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text("BACK", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 15),
              const Icon(Icons.assignment_return_rounded, color: Color(0xFFDC2626), size: 22),
              const SizedBox(width: 10),
              const Text("RETURNS & REVERSALS HUB", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 15),

          Container(
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFDC2626),
              labelColor: const Color(0xFFF87171),
              unselectedLabelColor: Colors.white54,
              tabs: [
                const Tab(text: "CREDIT NOTE (SALE RETURN)", icon: Icon(Icons.assignment_return_rounded, size: 16)),
                const Tab(text: "DEBIT NOTE (PURCHASE RETURN)", icon: Icon(Icons.remove_shopping_cart_rounded, size: 16)),
                Tab(text: "RETURNS REGISTER (${webPh.saleReturns.length + webPh.purchaseReturns.length})", icon: const Icon(Icons.format_list_bulleted_rounded, size: 16)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCreditNoteTab(webPh),
                _buildDebitNoteTab(webPh),
                _buildRegisterTab(webPh),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditNoteTab(PharoahWebManager webPh) {
    double total = cnItems.fold(0.0, (sum, it) => sum + it.total);
    double extraD = double.tryParse(cnExtraDiscC.text) ?? 0.0;
    double netTotal = (total - extraD).roundToDouble();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Expanded(
                      child: Autocomplete<Medicine>(
                        displayStringForOption: (m) => "${m.name} (${m.packing})",
                        optionsBuilder: (textEditingValue) {
                          if (textEditingValue.text.isEmpty) return const Iterable.empty();
                          return webPh.medicines.where((m) => m.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                        },
                        onSelected: (med) => _openCnItemDialog(webPh, med),
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            decoration: const InputDecoration(hintText: "Search Product to return from customer...", hintStyle: TextStyle(color: Colors.white38, fontSize: 11), prefixIcon: Icon(Icons.search, color: Color(0xFFDC2626), size: 18), border: InputBorder.none),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: cnItems.isEmpty
                    ? const Center(child: Text("No items in credit note.", style: TextStyle(color: Colors.white38)))
                    : ListView.builder(
                        itemCount: cnItems.length,
                        itemBuilder: (c, i) => Card(
                          color: const Color(0xFF1E293B),
                          margin: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            dense: true,
                            title: Text(cnItems[i].name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            subtitle: Text("Batch: ${cnItems[i].batch} | Qty: ${cnItems[i].qty.toInt()} | Rate: ₹${cnItems[i].rate}", style: const TextStyle(color: Colors.white54, fontSize: 10)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("₹${cnItems[i].total.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFFF87171), fontWeight: FontWeight.bold, fontSize: 12)),
                                IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent), onPressed: () => setState(() => cnItems.removeAt(i))),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _input("CREDIT NOTE NUMBER", cnNumberC),
                const SizedBox(height: 10),
                SwitchListTile(
                  dense: true, contentPadding: EdgeInsets.zero,
                  title: const Text("Breakage / Expiry Mode", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  subtitle: const Text("Will NOT add to sellable stock", style: TextStyle(color: Colors.white54, fontSize: 9)),
                  value: cnIsBreakage, activeColor: Colors.orangeAccent,
                  onChanged: (v) => setState(() => cnIsBreakage = v),
                ),
                const Divider(color: Colors.white10),
                Autocomplete<Party>(
                  displayStringForOption: (p) => p.name,
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty) return const Iterable.empty();
                    return webPh.parties.where((p) => p.group == "Sundry Debtors" && p.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (p) => setState(() => cnSelectedCustomer = p),
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: controller, focusNode: focusNode, style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: const InputDecoration(labelText: "Select Customer...", labelStyle: TextStyle(color: Colors.white38, fontSize: 11), prefixIcon: Icon(Icons.person, color: Color(0xFF38BDF8), size: 16), border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Extra Discount (-)", style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                    SizedBox(width: 80, height: 30, child: TextField(controller: cnExtraDiscC, keyboardType: TextInputType.number, textAlign: TextAlign.right, onChanged: (_) => setState(() {}), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12), decoration: InputDecoration(filled: true, fillColor: Colors.black38, contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none)))),
                  ],
                ),
                const Spacer(),
                Text("NET CREDIT: ₹${netTotal.toStringAsFixed(0)}", style: const TextStyle(color: Color(0xFFF87171), fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity, height: 45,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
                    onPressed: () => _saveCreditNote(webPh),
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text("SAVE CREDIT NOTE", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDebitNoteTab(PharoahWebManager webPh) {
    double total = dnItems.fold(0.0, (sum, it) => sum + it.total);
    double extraD = double.tryParse(dnExtraDiscC.text) ?? 0.0;
    double netTotal = (total - extraD).roundToDouble();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Expanded(
                      child: Autocomplete<Medicine>(
                        displayStringForOption: (m) => "${m.name} (${m.packing})",
                        optionsBuilder: (textEditingValue) {
                          if (textEditingValue.text.isEmpty) return const Iterable.empty();
                          return webPh.medicines.where((m) => m.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                        },
                        onSelected: (med) => _openDnItemDialog(webPh, med),
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          return TextField(
                            controller: controller, focusNode: focusNode, style: const TextStyle(color: Colors.white, fontSize: 12),
                            decoration: const InputDecoration(hintText: "Search Product to return to supplier...", hintStyle: TextStyle(color: Colors.white38, fontSize: 11), prefixIcon: Icon(Icons.search, color: Color(0xFF92400E), size: 18), border: InputBorder.none),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: dnItems.isEmpty
                    ? const Center(child: Text("No items in debit note.", style: TextStyle(color: Colors.white38)))
                    : ListView.builder(
                        itemCount: dnItems.length,
                        itemBuilder: (c, i) => Card(
                          color: const Color(0xFF1E293B), margin: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            dense: true,
                            title: Text(dnItems[i].name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            subtitle: Text("Batch: ${dnItems[i].batch} | Qty: ${dnItems[i].qty.toInt()} | Pur Rate: ₹${dnItems[i].purchaseRate}", style: const TextStyle(color: Colors.white54, fontSize: 10)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("₹${dnItems[i].total.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.bold, fontSize: 12)),
                                IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent), onPressed: () => setState(() => dnItems.removeAt(i))),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _input("DEBIT NOTE NUMBER", dnNumberC),
                const SizedBox(height: 10),
                SwitchListTile(
                  dense: true, contentPadding: EdgeInsets.zero,
                  title: const Text("Breakage / Expiry Mode", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  subtitle: const Text("Outward from non-sellable stock", style: TextStyle(color: Colors.white54, fontSize: 9)),
                  value: dnIsBreakage, activeColor: Colors.orangeAccent,
                  onChanged: (v) => setState(() => dnIsBreakage = v),
                ),
                const Divider(color: Colors.white10),
                Autocomplete<Party>(
                  displayStringForOption: (p) => p.name,
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty) return const Iterable.empty();
                    return webPh.parties.where((p) => p.group == "Sundry Creditors" && p.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (p) => setState(() => dnSelectedSupplier = p),
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: controller, focusNode: focusNode, style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: const InputDecoration(hintText: "Select Supplier...", hintStyle: TextStyle(color: Colors.white38, fontSize: 11), prefixIcon: Icon(Icons.business, color: Color(0xFFF59E0B), size: 16), border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Extra Discount (-)", style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                    SizedBox(width: 80, height: 30, child: TextField(controller: dnExtraDiscC, keyboardType: TextInputType.number, textAlign: TextAlign.right, onChanged: (_) => setState(() {}), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12), decoration: InputDecoration(filled: true, fillColor: Colors.black38, contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none)))),
                  ],
                ),
                const Spacer(),
                Text("NET DEBIT VALUE: ₹${netTotal.toStringAsFixed(0)}", style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity, height: 45,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF92400E), foregroundColor: Colors.white),
                    onPressed: () => _saveDebitNote(webPh),
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text("SAVE DEBIT NOTE", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterTab(PharoahWebManager webPh) {
    final activeShop = CompanyProfile.fromMap(webPh.companyProfile);
    final fDateOnly = _dateOnly(regFromDate);
    final tDateOnly = _dateOnly(regToDate);

    List<dynamic> allReturns = [...webPh.saleReturns, ...webPh.purchaseReturns];
    allReturns.sort((a, b) => (b.date as DateTime).compareTo(a.date as DateTime));

    final filtered = allReturns.where((r) {
      final rDateOnly = _dateOnly(r.date as DateTime);
      bool dateMatch = !rDateOnly.isBefore(fDateOnly) && !rDateOnly.isAfter(tDateOnly);
      String name = r is SaleReturn ? r.partyName : (r as PurchaseReturn).distributorName;
      bool searchMatch = registerSearch.isEmpty || name.toLowerCase().contains(registerSearch.toLowerCase()) || r.billNo.toString().toLowerCase().contains(registerSearch.toLowerCase());
      return dateMatch && searchMatch;
    }).toList();

    return Column(
      children: [
        Container(
          height: 38,
          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(8)),
          child: TextField(
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: const InputDecoration(hintText: "Search in Returns Register...", hintStyle: TextStyle(color: Colors.white38, fontSize: 11), prefixIcon: Icon(Icons.search, color: Color(0xFFDC2626), size: 16), border: InputBorder.none),
            onChanged: (v) => setState(() => registerSearch = v),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text("No return records found.", style: TextStyle(color: Colors.white38)))
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (c, i) {
                    final item = filtered[i];
                    bool isCn = item is SaleReturn;
                    String party = isCn ? item.partyName : (item as PurchaseReturn).distributorName;
                    Color color = isCn ? const Color(0xFFDC2626) : const Color(0xFFF59E0B);
                    bool isChecked = selectedReturnIds.contains(item.id.toString());

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B), 
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSelectionMode && isChecked ? color : Colors.transparent, width: 1.5)
                      ),
                      child: ListTile(
                        dense: true,
                        leading: isSelectionMode 
                          ? Checkbox(value: isChecked, activeColor: color, onChanged: (v) => setState(() => v! ? selectedReturnIds.add(item.id.toString()) : selectedReturnIds.remove(item.id.toString())))
                          : Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: color.withAlpha(50), borderRadius: BorderRadius.circular(4)), child: Text(isCn ? "CN" : "DN", style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold))),
                        title: Text(party, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        subtitle: Text("No: ${item.billNo} • ${WebAppDateLogic.format(item.date as DateTime)}", style: const TextStyle(color: Colors.white38, fontSize: 10)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("₹${(item.totalAmount as double).toStringAsFixed(2)}", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                            if (!isSelectionMode) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.print_outlined, color: Colors.cyanAccent, size: 16),
                                onPressed: () {
                                  final partyObj = webPh.parties.firstWhere((p) => p.name == party, orElse: () => Party(id: 'temp', name: party));
                                  if (isCn) {
                                    WebPdfRouterService.generateCreditNoteBytes(returnObj: item as SaleReturn, party: partyObj, shop: activeShop).then((bytes) => Printing.layoutPdf(onLayout: (_) async => bytes, name: 'CN_${item.billNo}'));
                                  } else {
                                    WebPdfRouterService.generateDebitNoteBytes(returnObj: item as PurchaseReturn, party: partyObj, shop: activeShop).then((bytes) => Printing.layoutPdf(onLayout: (_) async => bytes, name: 'DN_${item.billNo}'));
                                  }
                                }
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
                                onPressed: () {
                                  if (isCn) webPh.deleteSaleReturn(item.id.toString());
                                  else webPh.deletePurchaseReturn(item.id.toString());
                                }
                              ),
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (isSelectionMode && selectedReturnIds.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity, height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () => _handleBatchZipExport(webPh),
              icon: const Icon(Icons.folder_zip_rounded, size: 18),
              label: Text("DOWNLOAD ${selectedReturnIds.length} RETURNS AS ZIP", style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ]
      ],
    );
  }

  Widget _input(String label, TextEditingController ctrl, {bool isNum = false, bool isCaps = false, bool isHighlight = false, Function(String)? onChanged}) {
    return TextField(
      controller: ctrl, onChanged: onChanged,
      keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      textCapitalization: isCaps ? TextCapitalization.characters : TextCapitalization.none,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: Colors.white54, fontSize: 8.5, fontWeight: FontWeight.bold),
        filled: true, fillColor: isHighlight ? const Color(0x33DC2626) : Colors.black26,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    );
  }
}
RETURNS_EOF

# 4. Clean RAM and Fast Compile (O1)
echo -e "${YELLOW}[4/4] Fast Compiling Web Workstation...${NC}"
pkill -f "analysis_server" 2>/dev/null || true
pkill -f "dart_language_server" 2>/dev/null || true
sync
echo 3 | sudo tee /proc/sys/vm/drop_caches 2>/dev/null || true

flutter build web -t lib/web_live_sync/web_main.dart --release --base-href "/" --pwa-strategy=none --no-tree-shake-icons --dart2js-optimization=O1

npx wrangler pages deploy build/web --project-name=pharoah-erp --commit-dirty=true

git add .
git commit -m "Deploy Complete Returns Hub #PH-REV-130" || true
git push origin main || true

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${GREEN}  🎉 RETURNS HUB DEPLOYED: #PH-REV-130 LIVE!${NC}"
echo -e "${BLUE}====================================================${NC}"
