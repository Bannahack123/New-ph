// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
// FILE: lib/web_live_sync/web_pdf_router_service.dart

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'web_models.dart';
import '../../pdf/pdf_master_service.dart';

class WebPdfRouterService {
  /// 1. Generate Pure A4 Landscape PDF Bytes (Same as Mobile Architect Invoice)
  static Future<Uint8List> generateSaleBytes({
    required Sale sale,
    required Party party,
    required CompanyProfile shop,
    required AppConfig config,
  }) async {
    final pdf = pw.Document();
    const double masterWidth = 800;
    const int itemsPerPage = 18;
    int totalPages = (sale.items.length / itemsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;

    bool isLocal = shop.state.trim().toLowerCase() == sale.partyState.trim().toLowerCase();

    for (int pageNum = 0; pageNum < totalPages; pageNum++) {
      int start = pageNum * itemsPerPage;
      int end = (start + itemsPerPage < sale.items.length) ? start + itemsPerPage : sale.items.length;
      List<BillItem> pageItems = sale.items.sublist(start, end);
      bool isLastPage = (pageNum == totalPages - 1);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: pw.EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          build: (context) => pw.Container(
            width: masterWidth,
            height: 550,
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
            child: pw.Column(
              children: [
                // Top Header Box (800pt Fixed)
                pw.Row(
                  children: [
                    _hBox(
                      280,
                      true,
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(shop.name.toUpperCase(), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                          pw.Text(shop.address, style: const pw.TextStyle(fontSize: 7), maxLines: 2),
                          pw.Text("GSTIN: ${shop.gstin} | DL: ${shop.dlNo}", style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                          pw.Text("Mob: ${shop.phone}", style: const pw.TextStyle(fontSize: 6.5)),
                        ],
                      ),
                    ),
                    _hBox(
                      175,
                      true,
                      pw.Column(
                        children: [
                          pw.Text("TAX INVOICE", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                          pw.Divider(thickness: 0.5),
                          pw.Text(sale.billNo, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                          pw.Text(DateFormat('dd/MM/yyyy').format(sale.date), style: const pw.TextStyle(fontSize: 8)),
                          pw.Text(sale.paymentMode.toUpperCase(), style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ),
                    _hBox(
                      345,
                      false,
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("CONSIGNEE DETAILS:", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                          pw.Text(party.name, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                          pw.Text("${party.address}, ${party.city}", style: const pw.TextStyle(fontSize: 7.5), maxLines: 2),
                          pw.Text("GSTIN: ${party.gst} | DL: ${party.dl}", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                // Table Columns (800pt Exact Grid)
                pw.Container(
                  color: PdfColors.grey200,
                  decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
                  child: pw.Row(
                    children: [
                      _tCol("S.N", 25),
                      _tCol("Qty+Free", 50),
                      _tCol("Pack", 40),
                      _tCol("Product Description", 210, isLeft: true),
                      _tCol("Batch", 70),
                      _tCol("Exp", 45),
                      _tCol("HSN", 45),
                      _tCol("MRP", 55),
                      _tCol("Rate", 55),
                      if (isLocal) ...[
                        _tCol("CGST", 40),
                        _tCol("SGST", 40),
                      ] else ...[
                        _tCol("IGST", 80),
                      ],
                      _tCol("Net Total", 125, isLast: true),
                    ],
                  ),
                ),
                // Table Rows
                pw.Expanded(
                  child: pw.Column(
                    children: pageItems.asMap().entries.map((entry) {
                      int idx = entry.key;
                      var i = entry.value;
                      String fmt(double v) => v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);

                      return pw.Container(
                        decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.1, color: PdfColors.grey400))),
                        child: pw.Row(
                          children: [
                            _cell("${start + idx + 1}", 25),
                            _cell("${fmt(i.qty)}+${fmt(i.freeQty)}", 50),
                            _cell(i.packing, 40),
                            pw.Container(
                              width: 210,
                              padding: pw.EdgeInsets.only(left: 8),
                              alignment: pw.Alignment.centerLeft,
                              child: pw.Text(i.name, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                            ),
                            _cell(i.batch, 70),
                            _cell(i.exp, 45),
                            _cell(i.hsn, 45),
                            _cell(i.mrp.toStringAsFixed(2), 55),
                            _cell(i.rate.toStringAsFixed(2), 55),
                            if (isLocal) ...[
                              _cell("${(i.gstRate / 2).toStringAsFixed(1)}%", 40),
                              _cell("${(i.gstRate / 2).toStringAsFixed(1)}%", 40),
                            ] else ...[
                              _cell("${i.gstRate.toStringAsFixed(1)}%", 80),
                            ],
                            _cell(i.total.toStringAsFixed(2), 125),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (isLastPage) _buildFooter(shop.name, sale, config, isLocal),
              ],
            ),
          ),
        ),
      );
    }

    return pdf.save();
  }

  /// 2. Direct Browser Print in A4 Landscape
  static Future<void> printSaleInvoice({
    required Sale sale,
    required Party party,
    required CompanyProfile shop,
    required AppConfig config,
  }) async {
    final bytes = await generateSaleBytes(sale: sale, party: party, shop: shop, config: config);
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: 'Invoice_${sale.billNo}',
      format: PdfPageFormat.a4.landscape,
    );
  }

  /// 3. Direct PDF Download / Save File (Exact like Mobile App Save)
  static Future<void> downloadSalePdf({
    required Sale sale,
    required Party party,
    required CompanyProfile shop,
    required AppConfig config,
  }) async {
    final bytes = await generateSaleBytes(sale: sale, party: party, shop: shop, config: config);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Invoice_${sale.billNo}.pdf',
    );
  }

  static pw.Widget _hBox(double w, bool b, pw.Widget child) => pw.Container(
        width: w,
        height: 105,
        padding: pw.EdgeInsets.all(5),
        decoration: pw.BoxDecoration(
          border: pw.Border(
            right: pw.BorderSide(width: b ? 0.5 : 0),
            bottom: const pw.BorderSide(width: 0.5),
          ),
        ),
        child: child,
      );

  static pw.Widget _tCol(String t, double w, {bool isLast = false, bool isLeft = false}) => pw.Container(
        width: w,
        height: 20,
        alignment: isLeft ? pw.Alignment.centerLeft : pw.Alignment.center,
        padding: const pw.EdgeInsets.only(left: 5),
        decoration: pw.BoxDecoration(
          border: pw.Border(
            right: pw.BorderSide(width: isLast ? 0 : 0.5),
            bottom: const pw.BorderSide(width: 0.5),
          ),
        ),
        child: pw.Text(t, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
      );

  static pw.Widget _cell(String t, double w) => pw.Container(
        width: w,
        height: 18,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(width: 0.2, color: PdfColors.grey))),
        child: pw.Text(t, style: const pw.TextStyle(fontSize: 7.5)),
      );

  static pw.Widget _buildFooter(String shopName, Sale sale, AppConfig config, bool isLocal) {
    double taxableTotal = sale.items.fold(0.0, (sum, i) => sum + (i.qty * i.rate));
    double totalTax = sale.items.fold(0.0, (sum, i) => sum + (i.cgst + i.sgst + i.igst));

    return pw.Container(
      height: 110,
      decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(width: 0.5))),
      child: pw.Row(
        children: [
          // Left: Bank & Terms (From AppConfig)
          pw.Container(
            width: 330,
            padding: const pw.EdgeInsets.all(5),
            decoration: pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(width: 0.5))),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Amount in Words: RUPEES ${PdfMasterService.numberToWords(sale.totalAmount.round())} ONLY",
                    style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                pw.Spacer(),
                if (config.bankAccNumber.isNotEmpty) ...[
                  pw.Text("BANK: ${config.bankNameBranch.toUpperCase()} | A/C: ${config.bankAccNumber}", style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold)),
                  pw.Text("IFSC: ${config.bankIfsc.toUpperCase()} | BENEFICIARY: ${config.bankAccName.toUpperCase()}", style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold)),
                ],
                pw.Text(config.termsAndConditions.isNotEmpty ? config.termsAndConditions : "Terms: Goods once sold will not be taken back.",
                    style: const pw.TextStyle(fontSize: 6), maxLines: 2),
              ],
            ),
          ),
          // Center: Tax Calculation Breakdown
          pw.Container(
            width: 250,
            padding: const pw.EdgeInsets.all(5),
            decoration: pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(width: 0.5))),
            child: pw.Column(
              children: [
                _fRow("TAXABLE TOTAL", taxableTotal),
                if (isLocal) ...[
                  _fRow("CGST TOTAL", totalTax / 2),
                  _fRow("SGST TOTAL", totalTax / 2),
                ] else
                  _fRow("IGST TOTAL", totalTax),
                if (sale.extraDiscount > 0) _fRow("EXTRA DISCOUNT (-)", sale.extraDiscount),
                _fRow("ROUND OFF", sale.roundOff),
                pw.Divider(thickness: 0.5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("GRAND TOTAL", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text("Rs. ${sale.totalAmount.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          // Right: Signatory
          pw.Container(
            width: 220,
            padding: const pw.EdgeInsets.all(5),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("For $shopName", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 30),
                pw.Text(config.signLabel.isNotEmpty ? config.signLabel.toUpperCase() : "AUTHORISED SIGNATORY", style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _fRow(String l, double v) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(l, style: const pw.TextStyle(fontSize: 7.5)),
          pw.Text(v.toStringAsFixed(2), style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
        ],
      );
}
