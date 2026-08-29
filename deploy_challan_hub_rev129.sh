#!/bin/bash
set -e

export PATH="$HOME/flutter/bin:$PATH"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}   🚚 UPGRADING CHALLANS HUB & DEPLOY (#129)       ${NC}"
echo -e "${BLUE}====================================================${NC}\n"

# 1. Update Top Bar Badge to #PH-REV-129
echo -e "${YELLOW}[1/4] Updating Top Bar Badge to #PH-REV-129...${NC}"
cat << 'TOPBAR_EOF' > lib/web_live_sync/components/web_top_bar.dart
// FILE: lib/web_live_sync/components/web_top_bar.dart

import 'package:flutter/material.dart';
import '../pharoah_web_manager.dart';

class WebTopBar extends StatelessWidget implements PreferredSizeWidget {
  final PharoahWebManager webPh;
  final ValueChanged<String>? onSearchChanged;

  const WebTopBar({
    super.key,
    required this.webPh,
    this.onSearchChanged,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
              color: Color(0x332563EB),
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: const Icon(Icons.storefront_rounded, color: Color(0xFF38BDF8), size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                webPh.companyName.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              Row(
                children: [
                  Text(
                    "FY: ${webPh.financialYear}",
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: Color(0xFF38BDF8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0x2610B981),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.greenAccent, width: 0.5),
                    ),
                    child: const Text(
                      "#PH-REV-129",
                      style: TextStyle(color: Colors.greenAccent, fontSize: 8, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Container(
              height: 36,
              constraints: const BoxConstraints(maxWidth: 380),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: TextField(
                onChanged: onSearchChanged,
                style: const TextStyle(color: Colors.white, fontSize: 11.5),
                decoration: const InputDecoration(
                  hintText: "Search Medicines, Customers, Invoices...",
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 11),
                  prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF38BDF8), size: 16),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 9),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0x1F10B981),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x4D10B981)),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, color: Colors.greenAccent, size: 7),
                SizedBox(width: 6),
                Text(
                  "LIVE CLOUD",
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: Colors.white70, size: 20),
            tooltip: "Refresh Live Data",
            onPressed: () {
              webPh.refreshStoreData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("🔄 Live Cloud Database Refreshed!"),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
            tooltip: "Sign Out",
            onPressed: () => _confirmSignOut(context, webPh),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, PharoahWebManager webPh) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Colors.white10),
        ),
        title: const Text("Sign Out Workstation?", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text(
          "Are you sure you want to disconnect from this store workstation?",
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("CANCEL", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(c);
              webPh.signOut();
            },
            child: const Text("SIGN OUT", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
TOPBAR_EOF

# 2. Update web_pdf_router_service.dart with Challans Invoices & Reports Engines
echo -e "${YELLOW}[2/4] Updating web_pdf_router_service.dart with Challan engines...${NC}"
cat << 'PDF_EOF' > lib/web_live_sync/web_pdf_router_service.dart
// FILE: lib/web_live_sync/web_pdf_router_service.dart

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:archive/archive.dart';
import 'web_models.dart';
import '../../pdf/pdf_master_service.dart';

class WebPdfRouterService {
  
  // ===========================================================================
  // 1. SALE INVOICE (A4 LANDSCAPE)
  // ===========================================================================
  static Future<Uint8List> generateSaleBytes({
    required Sale sale,
    required Party party,
    required CompanyProfile shop,
    required AppConfig config,
  }) async {
    final pdf = pw.Document();
    const double masterWidth = 800;
    const double pageHeightLimit = 550;
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
          margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          build: (context) => pw.Column(
            children: [
              pw.Container(
                width: masterWidth,
                height: pageHeightLimit,
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                child: pw.Column(
                  children: [
                    pw.Row(
                      children: [
                        _hBox(
                          280, true,
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(shop.name.toUpperCase(), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                              pw.Text(shop.address, style: const pw.TextStyle(fontSize: 7), maxLines: 2),
                              pw.Text("GSTIN: ${shop.gstin} | DL: ${shop.dlNo}", style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                              pw.Text("Mob: ${shop.phone} | Email: ${shop.email.toLowerCase()}", style: const pw.TextStyle(fontSize: 7)),
                            ],
                          ),
                        ),
                        _hBox(
                          175, true,
                          pw.Column(
                            children: [
                              pw.Text("TAX INVOICE", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                              pw.Text(sale.paymentMode.toUpperCase(), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                              pw.Divider(thickness: 0.5),
                              pw.Text("No: ${sale.billNo}", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                              pw.Text(DateFormat('dd/MM/yyyy').format(sale.date), style: const pw.TextStyle(fontSize: 8)),
                            ],
                          ),
                        ),
                        _hBox(
                          345, false,
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text("CONSIGNEE:", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                              pw.Text(sale.partyName, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                              pw.Text("${sale.partyAddress.isNotEmpty ? sale.partyAddress : party.address}, ${sale.partyCity.isNotEmpty ? sale.partyCity : party.city}", style: const pw.TextStyle(fontSize: 7.5), maxLines: 2),
                              pw.Text("GST: ${sale.partyGstin} | DL: ${sale.partyDl.isNotEmpty ? sale.partyDl : party.dl}", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                              pw.Text("Mob: ${sale.partyPhone.isNotEmpty ? sale.partyPhone : party.phone}", style: const pw.TextStyle(fontSize: 7)),
                            ],
                          ),
                        ),
                      ],
                    ),

                    pw.Container(
                      color: PdfColors.grey200,
                      child: pw.Row(
                        children: [
                          _tCol("S.N", 25), _tCol("Qty+Free", 60), _tCol("Pack", 40),
                          _tCol("Product Description", 220, isLeft: true),
                          _tCol("Batch", 70), _tCol("Exp", 45), _tCol("HSN", 45),
                          _tCol("MRP", 55), _tCol("Rate", 55),
                          if (isLocal) ...[_tCol("CGST", 40), _tCol("SGST", 40)] else _tCol("IGST", 80),
                          _tCol("Net Amt", 100, isLast: true),
                        ],
                      ),
                    ),

                    pw.Expanded(
                      child: pw.Column(
                        children: pageItems.asMap().entries.map((entry) {
                          int idx = entry.key;
                          var i = entry.value;
                          String fmt(double v) => v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);
                          String qtyDisplay = "${fmt(i.qty)} + ${fmt(i.freeQty)}";

                          return pw.Container(
                            decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.1, color: PdfColors.grey400))),
                            child: pw.Row(
                              children: [
                                _cell("${start + idx + 1}", 25), _cell(qtyDisplay, 60), _cell(i.packing, 40),
                                pw.Container(
                                  width: 220, padding: const pw.EdgeInsets.only(left: 8), alignment: pw.Alignment.centerLeft,
                                  child: pw.Text(i.name, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                                ),
                                _cell(i.batch, 70), _cell(i.exp, 45), _cell(i.hsn, 45),
                                _cell(i.mrp.toStringAsFixed(2), 55), _cell(i.rate.toStringAsFixed(2), 55),
                                if (isLocal) ...[_cell("${(i.gstRate / 2).toStringAsFixed(1)}%", 40), _cell("${(i.gstRate / 2).toStringAsFixed(1)}%", 40)] else _cell("${i.gstRate.toStringAsFixed(1)}%", 80),
                                _cell(i.total.toStringAsFixed(2), 100),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    if (isLastPage) _buildSaleFooter(shop.name, sale, isLocal)
                    else pw.Container(
                      height: 30, alignment: pw.Alignment.centerRight, padding: const pw.EdgeInsets.only(right: 20),
                      child: pw.Text("Continued...", style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 8)),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  "This is a system-generated document. | Powered by Pharoah ERP [Web Workstation]",
                  style: const pw.TextStyle(fontSize: 5, color: PdfColors.grey600),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return pdf.save();
  }

  static Future<void> printSaleInvoice({required Sale sale, required Party party, required CompanyProfile shop, required AppConfig config}) async {
    final bytes = await generateSaleBytes(sale: sale, party: party, shop: shop, config: config);
    await Printing.layoutPdf(onLayout: (format) async => bytes, name: 'Invoice_${sale.billNo}', format: PdfPageFormat.a4.landscape);
  }

  static Future<void> downloadSalePdf({required Sale sale, required Party party, required CompanyProfile shop, required AppConfig config}) async {
    final bytes = await generateSaleBytes(sale: sale, party: party, shop: shop, config: config);
    await Printing.sharePdf(bytes: bytes, filename: 'Invoice_${sale.billNo}.pdf');
  }

  // ===========================================================================
  // 2. OUTWARD DELIVERY CHALLAN (A4 LANDSCAPE)
  // ===========================================================================
  static Future<Uint8List> generateSaleChallanBytes({
    required SaleChallan challan,
    required Party party,
    required CompanyProfile shop,
  }) async {
    final pdf = pw.Document();
    const double masterWidth = 800;
    const double pageHeightLimit = 550;
    const int itemsPerPage = 18;
    int totalPages = (challan.items.length / itemsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;

    for (int pageNum = 0; pageNum < totalPages; pageNum++) {
      int start = pageNum * itemsPerPage;
      int end = (start + itemsPerPage < challan.items.length) ? start + itemsPerPage : challan.items.length;
      List<BillItem> pageItems = challan.items.sublist(start, end);
      bool isLastPage = (pageNum == totalPages - 1);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          build: (context) => pw.Column(
            children: [
              pw.Container(
                width: masterWidth, height: pageHeightLimit,
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                child: pw.Column(
                  children: [
                    pw.Row(children: [
                      _hBox(280, true, pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                        pw.Text(shop.name.toUpperCase(), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                        pw.Text(shop.address, style: const pw.TextStyle(fontSize: 7), maxLines: 2),
                        pw.Text("GSTIN: ${shop.gstin} | DL: ${shop.dlNo}", style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                      ])),
                      _hBox(175, true, pw.Column(children: [
                        pw.Text("DELIVERY CHALLAN", style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
                        pw.Divider(thickness: 0.5),
                        pw.Text(challan.billNo, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        pw.Text(DateFormat('dd/MM/yyyy').format(challan.date), style: const pw.TextStyle(fontSize: 8)),
                        pw.Text(challan.status.toUpperCase(), style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: challan.status == "Billed" ? PdfColors.green900 : PdfColors.orange900)),
                      ])),
                      _hBox(345, false, pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                        pw.Text("CONSIGNEE / DESTINATION:", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                        pw.Text(party.name, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                        pw.Text("${party.address}, ${party.city}", style: const pw.TextStyle(fontSize: 7.5), maxLines: 2),
                        pw.Text("GST: ${party.gst} | DL: ${party.dl}", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ])),
                    ]),
                    pw.Container(
                      color: PdfColors.grey200,
                      child: pw.Row(children: [
                        _tCol("S.N", 25), _tCol("Qty+Free", 60), _tCol("Pack", 40),
                        _tCol("Product Description", 230, isLeft: true), _tCol("Batch", 75),
                        _tCol("Exp", 45), _tCol("HSN", 45), _tCol("MRP", 55), _tCol("Rate", 55),
                        _tCol("Net Total", 170, isLast: true),
                      ]),
                    ),
                    pw.Expanded(
                      child: pw.Column(children: pageItems.map((i) {
                        String fmt(double v) => v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);
                        return pw.Container(
                          decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.1, color: PdfColors.grey400))),
                          child: pw.Row(children: [
                            _cell("${challan.items.indexOf(i) + 1}", 25), _cell("${fmt(i.qty)}+${fmt(i.freeQty)}", 60), _cell(i.packing, 40),
                            pw.Container(width: 230, padding: const pw.EdgeInsets.only(left: 8), alignment: pw.Alignment.centerLeft, child: pw.Text(i.name, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                            _cell(i.batch, 75), _cell(i.exp, 45), _cell(i.hsn, 45),
                            _cell(i.mrp.toStringAsFixed(2), 55), _cell(i.rate.toStringAsFixed(2), 55),
                            _cell(i.total.toStringAsFixed(2), 170),
                          ]),
                        );
                      }).toList()),
                    ),
                    if (isLastPage) _buildChallanFooter(shop.name, challan.totalAmount, challan.remarks, isOutward: true)
                    else pw.Container(height: 30, alignment: pw.Alignment.centerRight, padding: const pw.EdgeInsets.only(right: 20), child: pw.Text("Continued...", style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 8))),
                  ],
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(child: pw.Text("This is a verified delivery note. | Powered by Pharoah ERP", style: const pw.TextStyle(fontSize: 5, color: PdfColors.grey600))),
            ],
          ),
        ),
      );
    }
    return pdf.save();
  }

  static Future<void> printSaleChallan({required SaleChallan challan, required Party party, required CompanyProfile shop}) async {
    final bytes = await generateSaleChallanBytes(challan: challan, party: party, shop: shop);
    await Printing.layoutPdf(onLayout: (format) async => bytes, name: 'Challan_${challan.billNo}', format: PdfPageFormat.a4.landscape);
  }

  static Future<void> downloadSaleChallanPdf({required SaleChallan challan, required Party party, required CompanyProfile shop}) async {
    final bytes = await generateSaleChallanBytes(challan: challan, party: party, shop: shop);
    await Printing.sharePdf(bytes: bytes, filename: 'Challan_${challan.billNo}.pdf');
  }

  // ===========================================================================
  // 3. INWARD PURCHASE CHALLAN (A4 LANDSCAPE)
  // ===========================================================================
  static Future<Uint8List> generatePurchaseChallanBytes({
    required PurchaseChallan challan,
    required Party party,
    required CompanyProfile shop,
  }) async {
    final pdf = pw.Document();
    const double masterWidth = 800;
    const double pageHeightLimit = 550;
    const int itemsPerPage = 16;
    int totalPages = (challan.items.length / itemsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;

    for (int pageNum = 0; pageNum < totalPages; pageNum++) {
      int start = pageNum * itemsPerPage;
      int end = (start + itemsPerPage < challan.items.length) ? start + itemsPerPage : challan.items.length;
      List<PurchaseItem> pageItems = challan.items.sublist(start, end);
      bool isLastPage = (pageNum == totalPages - 1);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          build: (context) => pw.Column(
            children: [
              pw.Container(
                width: masterWidth, height: pageHeightLimit,
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                child: pw.Column(
                  children: [
                    pw.Row(children: [
                      _hBox(285, true, pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                        pw.Text(shop.name.toUpperCase(), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                        pw.Text(shop.address, style: const pw.TextStyle(fontSize: 7), maxLines: 2),
                        pw.Text("GSTIN: ${shop.gstin} | DL: ${shop.dlNo}", style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                      ])),
                      _hBox(170, true, pw.Column(children: [
                        pw.Text("GOODS INWARD NOTE", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900)),
                        pw.Divider(thickness: 0.5),
                        pw.Text("ID: ${challan.internalNo}", style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                        pw.Text("Ref: ${challan.billNo}", style: const pw.TextStyle(fontSize: 8)),
                        pw.Text(DateFormat('dd/MM/yyyy').format(challan.date), style: const pw.TextStyle(fontSize: 8)),
                      ])),
                      _hBox(345, false, pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                        pw.Text("SUPPLIER DETAILS:", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                        pw.Text(party.name, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                        pw.Text("GSTIN: ${party.gst} | DL: ${party.dl}", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.Text("Mob: ${party.phone}", style: const pw.TextStyle(fontSize: 7)),
                      ])),
                    ]),
                    pw.Container(
                      color: PdfColors.grey200,
                      child: pw.Row(children: [
                        _tCol("S.N", 30), _tCol("Product Description", 280, isLeft: true),
                        _tCol("Packing", 60), _tCol("Batch", 80), _tCol("Expiry", 60),
                        _tCol("Qty", 60), _tCol("Pur. Rate", 90), _tCol("Total", 140, isLast: true),
                      ]),
                    ),
                    pw.Expanded(
                      child: pw.Column(children: pageItems.map((i) => pw.Container(
                        decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.1))),
                        child: pw.Row(children: [
                          _cell("${challan.items.indexOf(i) + 1}", 30), _cell(i.name, 280, isLeft: true),
                          _cell(i.packing, 60), _cell(i.batch, 80), _cell(i.exp, 60),
                          _cell("${i.qty.toInt()} + ${i.freeQty.toInt()}", 60),
                          _cell(i.purchaseRate.toStringAsFixed(2), 90),
                          _cell(i.total.toStringAsFixed(2), 140),
                        ]),
                      )).toList()),
                    ),
                    if (isLastPage) _buildChallanFooter(shop.name, challan.totalAmount, challan.remarks, isOutward: false)
                    else pw.Container(height: 30, alignment: pw.Alignment.centerRight, padding: const pw.EdgeInsets.only(right: 20), child: pw.Text("Continued...", style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 8))),
                  ],
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(child: pw.Text("This is a system-generated goods receipt note.", style: const pw.TextStyle(fontSize: 5, color: PdfColors.grey600))),
            ],
          ),
        ),
      );
    }
    return pdf.save();
  }

  static Future<void> printPurchaseChallan({required PurchaseChallan challan, required Party party, required CompanyProfile shop}) async {
    final bytes = await generatePurchaseChallanBytes(challan: challan, party: party, shop: shop);
    await Printing.layoutPdf(onLayout: (format) async => bytes, name: 'InwardChallan_${challan.internalNo}', format: PdfPageFormat.a4.landscape);
  }

  static Future<void> downloadPurchaseChallanPdf({required PurchaseChallan challan, required Party party, required CompanyProfile shop}) async {
    final bytes = await generatePurchaseChallanBytes(challan: challan, party: party, shop: shop);
    await Printing.sharePdf(bytes: bytes, filename: 'InwardChallan_${challan.internalNo}.pdf');
  }

  // ===========================================================================
  // 4. CHALLANS SUMMARY REPORT (A4 LANDSCAPE)
  // ===========================================================================
  static Future<Uint8List> generateChallanReportBytes({
    required List<dynamic> challans,
    required CompanyProfile shop,
    required DateTime from,
    required DateTime to,
    required bool isSaleChallan,
  }) async {
    final pdf = pw.Document();
    String title = isSaleChallan ? "SALE DELIVERY CHALLANS SUMMARY" : "PURCHASE INWARD CHALLANS SUMMARY";
    double grandTotal = challans.fold(0.0, (s, c) => s + (c.totalAmount as double));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => pw.Column(children: [
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(shop.name.toUpperCase(), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: isSaleChallan ? PdfColors.teal900 : PdfColors.amber900)),
              pw.Text(title, style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
            ]),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text("Period: ${DateFormat('dd/MM/yyyy').format(from)} to ${DateFormat('dd/MM/yyyy').format(to)}", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Text("Total Entries: ${challans.length}", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            ]),
          ]),
          pw.Divider(thickness: 1, color: isSaleChallan ? PdfColors.teal900 : PdfColors.amber900),
          pw.SizedBox(height: 6),
        ]),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: pw.BoxDecoration(color: isSaleChallan ? PdfColors.teal900 : PdfColors.amber900),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headers: ['DATE', 'CHALLAN NO', 'PARTY / DISTRIBUTOR', 'STATUS', 'REMARKS', 'TOTAL VALUE (Rs)'],
            data: challans.map((c) {
              String pName = isSaleChallan ? (c as SaleChallan).partyName : (c as PurchaseChallan).distributorName;
              return [
                DateFormat('dd/MM/yyyy').format(c.date as DateTime),
                c.billNo.toString(),
                pName,
                c.status.toString().toUpperCase(),
                c.remarks.toString().isEmpty ? "-" : c.remarks.toString(),
                (c.totalAmount as double).toStringAsFixed(2),
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 18),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)), border: pw.Border.all(color: PdfColors.grey300)),
              child: pw.Row(children: [
                pw.Text("GRAND TOTAL VALUE: ", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Text("Rs. ${grandTotal.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: isSaleChallan ? PdfColors.teal900 : PdfColors.amber900)),
              ]),
            ),
          ]),
        ],
      ),
    );

    return pdf.save();
  }

  static Future<void> printChallanReport({required List<dynamic> challans, required CompanyProfile shop, required DateTime from, required DateTime to, required bool isSaleChallan}) async {
    final bytes = await generateChallanReportBytes(challans: challans, shop: shop, from: from, to: to, isSaleChallan: isSaleChallan);
    await Printing.layoutPdf(onLayout: (format) async => bytes, name: 'ChallanReport', format: PdfPageFormat.a4.landscape);
  }

  static Future<void> downloadChallanReport({required List<dynamic> challans, required CompanyProfile shop, required DateTime from, required DateTime to, required bool isSaleChallan}) async {
    final bytes = await generateChallanReportBytes(challans: challans, shop: shop, from: from, to: to, isSaleChallan: isSaleChallan);
    await Printing.sharePdf(bytes: bytes, filename: 'ChallanReport_${DateFormat('ddMMMyy').format(from)}.pdf');
  }

  // ===========================================================================
  // 5. BULK ZIP DOWNLOAD
  // ===========================================================================
  static Future<void> downloadBulkZip({
    required List<dynamic> documents,
    required CompanyProfile shop,
    required AppConfig config,
    required Function(double, String) onProgress,
  }) async {
    final archive = Archive();

    for (int i = 0; i < documents.length; i++) {
      var doc = documents[i];
      Uint8List pdfBytes;
      String fileName;

      if (doc is Sale) {
        onProgress((i + 1) / documents.length, "Invoice: ${doc.billNo}");
        pdfBytes = await generateSaleBytes(
          sale: doc,
          party: Party(id: doc.partyId, name: doc.partyName, gst: doc.partyGstin, state: doc.partyState, address: doc.partyAddress, city: doc.partyCity, phone: doc.partyPhone, email: doc.partyEmail, dl: doc.partyDl),
          shop: shop,
          config: config,
        );
        fileName = "${doc.billNo.replaceAll('/', '_')}.pdf";
        archive.addFile(ArchiveFile(fileName, pdfBytes.length, pdfBytes));
      } else if (doc is Purchase) {
        onProgress((i + 1) / documents.length, "Inward: ${doc.internalNo}");
        pdfBytes = await generatePurchaseBytes(
          purchase: doc,
          party: Party(id: doc.partyId, name: doc.distributorName),
          shop: shop,
        );
        fileName = "${doc.internalNo.replaceAll('/', '_')}.pdf";
        archive.addFile(ArchiveFile(fileName, pdfBytes.length, pdfBytes));
      }
    }

    final zipData = ZipEncoder().encode(archive);
    if (zipData != null) {
      await Printing.sharePdf(
        bytes: Uint8List.fromList(zipData), 
        filename: 'Pharoah_Bulk_${DateFormat('ddMM_HHmm').format(DateTime.now())}.zip',
      );
    }
  }

  static Future<Uint8List> generatePurchaseBytes({required Purchase purchase, required Party party, required CompanyProfile shop}) async {
    final pdf = pw.Document();
    return pdf.save();
  }

  // ===========================================================================
  // SHARED UI HELPER WIDGETS
  // ===========================================================================
  static pw.Widget _hBox(double w, bool b, pw.Widget child) => pw.Container(width: w, height: 105, padding: const pw.EdgeInsets.all(5), decoration: pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(width: b ? 0.5 : 0), bottom: const pw.BorderSide(width: 0.5))), child: child);
  static pw.Widget _tCol(String t, double w, {bool isLast = false, bool isLeft = false}) => pw.Container(width: w, height: 20, alignment: isLeft ? pw.Alignment.centerLeft : pw.Alignment.center, padding: const pw.EdgeInsets.only(left: 5), decoration: pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(width: isLast ? 0 : 0.5), bottom: const pw.BorderSide(width: 0.5))), child: pw.Text(t, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)));
  static pw.Widget _cell(String t, double w, {bool isLeft = false}) => pw.Container(width: w, height: 18, alignment: isLeft ? pw.Alignment.centerLeft : pw.Alignment.center, decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(width: 0.2, color: PdfColors.grey))), child: pw.Text(t, style: const pw.TextStyle(fontSize: 7.5)));

  static pw.Widget _buildSaleFooter(String shopName, Sale sale, bool isLocal) {
    double taxableTotal = sale.items.fold(0.0, (sum, i) => sum + (i.qty * i.rate));
    double totalTax = sale.items.fold(0.0, (sum, i) => sum + (i.cgst + i.sgst + i.igst));

    return pw.Container(
      height: 110, decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(width: 0.5))),
      child: pw.Row(
        children: [
          pw.Container(
            width: 330, padding: const pw.EdgeInsets.all(5), decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(width: 0.5))),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Amount in Words:", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                pw.Text("RUPEES ${PdfMasterService.numberToWords(sale.totalAmount.round())} ONLY", style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                pw.Spacer(),
                pw.Text("Terms: Goods once sold will not be taken back. Subject to local jurisdiction.", style: const pw.TextStyle(fontSize: 6), maxLines: 2),
              ],
            ),
          ),
          pw.Container(
            width: 250, padding: const pw.EdgeInsets.all(5), decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(width: 0.5))),
            child: pw.Column(
              children: [
                _fRow("TAXABLE TOTAL", taxableTotal),
                if (isLocal) ...[_fRow("CGST TOTAL", totalTax / 2), _fRow("SGST TOTAL", totalTax / 2)] else _fRow("IGST TOTAL", totalTax),
                if (sale.extraDiscount > 0) _fRow("EXTRA DISCOUNT (-)", sale.extraDiscount),
                _fRow("ROUND OFF", sale.roundOff),
                pw.Divider(thickness: 0.5),
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Text("GRAND TOTAL", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text("Rs. ${sale.totalAmount.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                ]),
              ],
            ),
          ),
          pw.Container(
            width: 220, padding: const pw.EdgeInsets.all(5),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("For $shopName", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 30),
                pw.Text("AUTHORISED SIGNATORY", style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildChallanFooter(String shopName, double total, String remarks, {required bool isOutward}) {
    return pw.Container(
      height: 110, decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(width: 0.5))),
      child: pw.Row(
        children: [
          pw.Container(
            width: 480, padding: const pw.EdgeInsets.all(8), decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(width: 0.5))),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("REMARKS / VEHICLE NOTE: ${remarks.isEmpty ? 'Materials dispatched in good condition.' : remarks}", style: const pw.TextStyle(fontSize: 7.5)),
                pw.Spacer(),
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Text("RECEIVER'S SIGNATURE & STAMP", style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                ]),
              ],
            ),
          ),
          pw.Container(
            width: 320, padding: const pw.EdgeInsets.all(8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Text("NET CHALLAN VALUE", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text("Rs. ${total.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: isOutward ? PdfColors.teal900 : PdfColors.amber900)),
                ]),
                pw.Spacer(),
                pw.Text("For $shopName", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Text("AUTHORISED SIGNATORY", style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
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
PDF_EOF

# 3. Upgrade web_challan_view.dart with 1:1 App Parity (Tabs, 4-Way Menu, Date Filter, No-Crash UI)
echo -e "${YELLOW}[3/4] Upgrading web_challan_view.dart with 1:1 App parity...${NC}"
cat << 'CHALLAN_EOF' > lib/web_live_sync/web_challan_view.dart
// FILE: lib/web_live_sync/web_challan_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'web_models.dart';
import 'pharoah_web_manager.dart';
import 'web_app_date_logic.dart';
import 'web_pharoah_numbering_engine.dart';
import 'web_pdf_router_service.dart';

class WebChallanView extends StatefulWidget {
  final VoidCallback onBack;
  final int initialTabIndex;

  const WebChallanView({
    super.key,
    required this.onBack,
    this.initialTabIndex = 0,
  });

  @override
  State<WebChallanView> createState() => _WebChallanViewState();
}

class _WebChallanViewState extends State<WebChallanView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sale Challan State
  final scNumberC = TextEditingController();
  final scRemarksC = TextEditingController();
  DateTime scDate = DateTime.now();
  Party? scSelectedCustomer;
  List<BillItem> scItems = [];

  // Purchase Challan State
  final pcInternalNoC = TextEditingController();
  final pcSupplierRefC = TextEditingController();
  final pcRemarksC = TextEditingController();
  DateTime pcDate = DateTime.now();
  Party? pcSelectedSupplier;
  List<PurchaseItem> pcItems = [];

  // Register State
  DateTime regFromDate = DateTime.now();
  DateTime regToDate = DateTime.now();
  String registerSearch = "";
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
    final webPh = Provider.of<PharoahWebManager>(context, listen: false);

    scNumberC.text = webPh.getNextBillNumber("CHALLAN", "SCH-", 101);
    pcInternalNoC.text = WebPharoahNumberingEngine.getNextNumber(
      prefix: "PCH-",
      startFrom: 1,
      currentList: webPh.purchaseChallans,
    );

    scDate = WebAppDateLogic.getSmartDate(webPh.financialYear);
    pcDate = scDate;
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
    scNumberC.dispose();
    scRemarksC.dispose();
    pcInternalNoC.dispose();
    pcSupplierRefC.dispose();
    pcRemarksC.dispose();
    super.dispose();
  }

  // ===========================================================================
  // 1. OUTWARD SALE CHALLAN ITEM ENTRY
  // ===========================================================================
  void _openScItemDialog(PharoahWebManager webPh, Medicine med) {
    final batchC = TextEditingController();
    final expC = TextEditingController(text: "12/28");
    final mrpC = TextEditingController(text: med.mrp.toStringAsFixed(2));
    final rateC = TextEditingController(text: med.rateA.toStringAsFixed(2));
    final qtyC = TextEditingController(text: "1");
    final freeC = TextEditingController(text: "0");
    final gstC = TextEditingController(text: med.gst.toString());

    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setDialogState) {
          double q = double.tryParse(qtyC.text) ?? 0.0;
          double r = double.tryParse(rateC.text) ?? 0.0;
          double g = double.tryParse(gstC.text) ?? 0.0;
          double itemTotal = (q * r) * (1 + g / 100);

          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Colors.white12)),
            title: Text("DISPATCH ITEM • ${med.name}", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
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
                        Expanded(child: _input("CHALLAN RATE ₹ *", rateC, isNum: true, isHighlight: true, onChanged: (_) => setDialogState(() {}))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _input("DISPATCH QTY *", qtyC, isNum: true, isHighlight: true, onChanged: (_) => setDialogState(() {}))),
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
                          const Text("ESTIMATED DISPATCH VALUE", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                          Text("₹${itemTotal.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 18, fontWeight: FontWeight.w900)),
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
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
                onPressed: () {
                  if (batchC.text.trim().isEmpty || q <= 0 || r <= 0) return;
                  final newItem = BillItem(
                    id: "SCITM-${DateTime.now().millisecondsSinceEpoch}",
                    srNo: scItems.length + 1,
                    medicineID: med.id,
                    name: med.name,
                    packing: med.packing,
                    batch: batchC.text.trim(),
                    exp: expC.text.trim(),
                    hsn: med.hsnCode,
                    mrp: double.tryParse(mrpC.text) ?? 0.0,
                    qty: q,
                    freeQty: double.tryParse(freeC.text) ?? 0.0,
                    rate: r,
                    gstRate: g,
                    total: itemTotal,
                  );
                  setState(() => scItems.add(newItem));
                  Navigator.pop(c);
                },
                child: const Text("ADD TO CHALLAN", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _saveSaleChallan(PharoahWebManager webPh) {
    if (scSelectedCustomer == null || scItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select Customer and add items!"), backgroundColor: Colors.orange));
      return;
    }

    double total = scItems.fold(0.0, (sum, it) => sum + it.total);

    final newChallan = SaleChallan(
      id: "SCH-WEB-${DateTime.now().millisecondsSinceEpoch}",
      billNo: scNumberC.text.trim(),
      partyId: scSelectedCustomer!.id,
      partyName: scSelectedCustomer!.name,
      partyGstin: scSelectedCustomer!.gst,
      partyState: scSelectedCustomer!.state,
      date: scDate,
      items: List.from(scItems),
      totalAmount: total,
      status: "Pending",
      remarks: scRemarksC.text.trim(),
    );

    webPh.saleChallans.add(newChallan);
    webPh.pushUpdatedDataToCloud();

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Delivery Challan ${scNumberC.text} Saved!"), backgroundColor: Colors.green));
    widget.onBack();
  }

  // ===========================================================================
  // 2. INWARD PURCHASE CHALLAN ENTRY
  // ===========================================================================
  void _openPcItemDialog(PharoahWebManager webPh, Medicine med) {
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
            title: Text("INWARD ITEM • ${med.name}", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
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
                          const Text("INWARD VALUE", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
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
                    id: "PCITM-${DateTime.now().millisecondsSinceEpoch}",
                    srNo: pcItems.length + 1,
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
                  setState(() => pcItems.add(newItem));
                  Navigator.pop(c);
                },
                child: const Text("ADD TO INWARD CHALLAN", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _savePurchaseChallan(PharoahWebManager webPh) {
    if (pcSelectedSupplier == null || pcSupplierRefC.text.trim().isEmpty || pcItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select Supplier, Ref No & add items!"), backgroundColor: Colors.orange));
      return;
    }

    double total = pcItems.fold(0.0, (sum, it) => sum + it.total);

    final newChallan = PurchaseChallan(
      id: "PCH-WEB-${DateTime.now().millisecondsSinceEpoch}",
      internalNo: pcInternalNoC.text.trim(),
      billNo: pcSupplierRefC.text.trim(),
      partyId: pcSelectedSupplier!.id,
      distributorName: pcSelectedSupplier!.name,
      date: pcDate,
      items: List.from(pcItems),
      totalAmount: total,
      status: "Pending",
      remarks: pcRemarksC.text.trim(),
    );

    webPh.purchaseChallans.add(newChallan);
    webPh.pushUpdatedDataToCloud();

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Inward Challan ${pcInternalNoC.text} Saved!"), backgroundColor: Colors.green));
    widget.onBack();
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
          // Top Header Bar
          Row(
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
              const SizedBox(width: 15),
              const Icon(Icons.local_shipping_rounded, color: Color(0xFF0F766E), size: 22),
              const SizedBox(width: 10),
              const Text(
                "DELIVERY & INWARD CHALLANS HUB",
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // Tabs Switcher
          Container(
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF0F766E),
              labelColor: const Color(0xFF2DD4BF),
              unselectedLabelColor: Colors.white54,
              tabs: [
                const Tab(text: "OUTWARD SALE CHALLAN", icon: Icon(Icons.local_shipping_rounded, size: 16)),
                const Tab(text: "INWARD PURCHASE CHALLAN", icon: Icon(Icons.inventory_2_rounded, size: 16)),
                Tab(text: "CHALLANS REGISTER (${webPh.saleChallans.length + webPh.purchaseChallans.length})", icon: const Icon(Icons.list_alt_rounded, size: 16)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSaleChallanTab(webPh),
                _buildPurchaseChallanTab(webPh),
                _buildRegisterTab(webPh),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleChallanTab(PharoahWebManager webPh) {
    double total = scItems.fold(0.0, (sum, it) => sum + it.total);

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
                        displayStringForOption: (m) => "${m.name} (${m.packing}) - Stock: ${m.stock.toInt()}",
                        optionsBuilder: (textEditingValue) {
                          if (textEditingValue.text.isEmpty) return const Iterable.empty();
                          return webPh.medicines.where((m) =>
                              m.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                        },
                        onSelected: (med) => _openScItemDialog(webPh, med),
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            decoration: const InputDecoration(
                              hintText: "Search Product to add in outward delivery challan...",
                              hintStyle: TextStyle(color: Colors.white38, fontSize: 11),
                              prefixIcon: Icon(Icons.search, color: Color(0xFF0F766E), size: 18),
                              border: InputBorder.none,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: scItems.isEmpty
                    ? const Center(child: Text("No items in delivery challan.", style: TextStyle(color: Colors.white38)))
                    : ListView.builder(
                        itemCount: scItems.length,
                        itemBuilder: (c, i) => Card(
                          color: const Color(0xFF1E293B),
                          margin: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            dense: true,
                            title: Text(scItems[i].name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            subtitle: Text("Batch: ${scItems[i].batch} | Qty: ${scItems[i].qty.toInt()} + ${scItems[i].freeQty.toInt()} | Rate: ₹${scItems[i].rate}", style: const TextStyle(color: Colors.white54, fontSize: 10)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("₹${scItems[i].total.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFF2DD4BF), fontWeight: FontWeight.bold, fontSize: 12)),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                                  onPressed: () => setState(() => scItems.removeAt(i)),
                                ),
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
                _input("CHALLAN NUMBER", scNumberC),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: scDate,
                      firstDate: WebAppDateLogic.getFYStart(webPh.financialYear),
                      lastDate: WebAppDateLogic.getFYEnd(webPh.financialYear),
                    );
                    if (picked != null) setState(() => scDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("DATE: ${DateFormat('dd/MM/yyyy').format(scDate)}", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        const Icon(Icons.calendar_month, color: Color(0xFF2DD4BF), size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Autocomplete<Party>(
                  displayStringForOption: (p) => "${p.name} (${p.city})",
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty) return const Iterable.empty();
                    return webPh.parties.where((p) => p.group == "Sundry Debtors" && p.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (p) => setState(() => scSelectedCustomer = p),
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: "SELECT CUSTOMER *",
                        labelStyle: TextStyle(color: Colors.white54, fontSize: 9),
                        prefixIcon: Icon(Icons.person, color: Color(0xFF38BDF8), size: 16),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _input("DISPATCH REMARKS / VEHICLE", scRemarksC),
                const Spacer(),
                Text("TOTAL CHALLAN: ₹${total.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: () => _saveSaleChallan(webPh),
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text("SAVE DELIVERY CHALLAN", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseChallanTab(PharoahWebManager webPh) {
    double total = pcItems.fold(0.0, (sum, it) => sum + it.total);

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
                          return webPh.medicines.where((m) =>
                              m.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                        },
                        onSelected: (med) => _openPcItemDialog(webPh, med),
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            decoration: const InputDecoration(
                              hintText: "Search Product to add in inward purchase challan...",
                              hintStyle: TextStyle(color: Colors.white38, fontSize: 11),
                              prefixIcon: Icon(Icons.search, color: Color(0xFFD97706), size: 18),
                              border: InputBorder.none,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: pcItems.isEmpty
                    ? const Center(child: Text("No items in inward challan.", style: TextStyle(color: Colors.white38)))
                    : ListView.builder(
                        itemCount: pcItems.length,
                        itemBuilder: (c, i) => Card(
                          color: const Color(0xFF1E293B),
                          margin: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            dense: true,
                            title: Text(pcItems[i].name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            subtitle: Text("Batch: ${pcItems[i].batch} | Qty: ${pcItems[i].qty.toInt()} + ${pcItems[i].freeQty.toInt()} | Pur Rate: ₹${pcItems[i].purchaseRate}", style: const TextStyle(color: Colors.white54, fontSize: 10)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("₹${pcItems[i].total.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.bold, fontSize: 12)),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                                  onPressed: () => setState(() => pcItems.removeAt(i)),
                                ),
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
                _input("INTERNAL INWARD ID", pcInternalNoC),
                const SizedBox(height: 10),
                _input("SUPPLIER REF / CHALLAN NO *", pcSupplierRefC, isCaps: true),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: pcDate,
                      firstDate: WebAppDateLogic.getFYStart(webPh.financialYear),
                      lastDate: WebAppDateLogic.getFYEnd(webPh.financialYear),
                    );
                    if (picked != null) setState(() => pcDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("DATE: ${DateFormat('dd/MM/yyyy').format(pcDate)}", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        const Icon(Icons.calendar_month, color: Color(0xFFFBBF24), size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Autocomplete<Party>(
                  displayStringForOption: (p) => "${p.name} (${p.city})",
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty) return const Iterable.empty();
                    return webPh.parties.where((p) => p.group == "Sundry Creditors" && p.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (p) => setState(() => pcSelectedSupplier = p),
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: "SELECT SUPPLIER *",
                        labelStyle: TextStyle(color: Colors.white54, fontSize: 9),
                        prefixIcon: Icon(Icons.business, color: Color(0xFFF59E0B), size: 16),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _input("INWARD REMARKS", pcRemarksC),
                const Spacer(),
                Text("TOTAL INWARD: ₹${total.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: () => _savePurchaseChallan(webPh),
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text("SAVE INWARD CHALLAN", style: TextStyle(fontWeight: FontWeight.bold)),
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

    List<dynamic> allChallans = [...webPh.saleChallans, ...webPh.purchaseChallans];
    allChallans.sort((a, b) => (b.date as DateTime).compareTo(a.date as DateTime));

    final filtered = allChallans.where((c) {
      final cDateOnly = _dateOnly(c.date as DateTime);
      bool dateMatch = !cDateOnly.isBefore(fDateOnly) && !cDateOnly.isAfter(tDateOnly);
      String name = c is SaleChallan ? c.partyName : (c as PurchaseChallan).distributorName;
      bool searchMatch = registerSearch.isEmpty ||
          name.toLowerCase().contains(registerSearch.toLowerCase()) || 
          c.billNo.toString().toLowerCase().contains(registerSearch.toLowerCase());
      return dateMatch && searchMatch;
    }).toList();

    double totalRegisterVal = filtered.fold(0.0, (s, c) => s + (c.totalAmount as double));

    return Column(
      children: [
        // Filter Bar
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _dateTile("FROM DATE", regFromDate, (d) => setState(() => regFromDate = d), webPh.financialYear)),
                  const SizedBox(width: 10),
                  Expanded(child: _dateTile("TO DATE", regToDate, (d) => setState(() => regToDate = d), webPh.financialYear)),
                  const SizedBox(width: 14),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    onPressed: () => WebPdfRouterService.printChallanReport(challans: filtered, shop: activeShop, from: regFromDate, to: regToDate, isSaleChallan: true),
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                    label: const Text("PRINT REPORT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: const InputDecoration(
                  hintText: "Search in Challans Register (Party, Challan No)...",
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 11),
                  prefixIcon: Icon(Icons.search, color: Color(0xFF0F766E), size: 16),
                  filled: true, fillColor: Colors.black26,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (v) => setState(() => registerSearch = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // List
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text("No challans found for selected period.", style: TextStyle(color: Colors.white38)))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  itemBuilder: (c, i) {
                    final item = filtered[i];
                    bool isSc = item is SaleChallan;
                    String party = isSc ? item.partyName : (item as PurchaseChallan).distributorName;
                    bool isPending = item.status == "Pending";
                    Color themeColor = isSc ? const Color(0xFF2DD4BF) : const Color(0xFFFBBF24);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSc ? const Color(0x330F766E) : const Color(0x33D97706),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(isSc ? "SALE CH" : "PUR CH",
                              style: TextStyle(color: themeColor, fontSize: 9.5, fontWeight: FontWeight.bold)),
                        ),
                        title: Row(
                          children: [
                            Text(party, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(width: 8),
                            _statusBadge(item.status.toString().toUpperCase(), isPending),
                          ],
                        ),
                        subtitle: Text("Challan No: ${item.billNo} • Date: ${DateFormat('dd/MM/yyyy').format(item.date as DateTime)} • Items: ${item.items.length}",
                            style: const TextStyle(color: Colors.white38, fontSize: 10.5)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "₹${(item.totalAmount as double).toStringAsFixed(2)}",
                              style: TextStyle(color: themeColor, fontWeight: FontWeight.w900, fontSize: 14),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.print_outlined, color: Color(0xFF38BDF8), size: 18),
                              tooltip: "Print Landscape Challan",
                              onPressed: () {
                                final partyObj = webPh.parties.firstWhere(
                                  (p) => p.name == party,
                                  orElse: () => Party(id: 'temp', name: party),
                                );
                                if (isSc) {
                                  WebPdfRouterService.printSaleChallan(challan: item as SaleChallan, party: partyObj, shop: activeShop);
                                } else {
                                  WebPdfRouterService.printPurchaseChallan(challan: item as PurchaseChallan, party: partyObj, shop: activeShop);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.download_rounded, color: Colors.greenAccent, size: 18),
                              tooltip: "Download PDF",
                              onPressed: () {
                                final partyObj = webPh.parties.firstWhere(
                                  (p) => p.name == party,
                                  orElse: () => Party(id: 'temp', name: party),
                                );
                                if (isSc) {
                                  WebPdfRouterService.downloadSaleChallanPdf(challan: item as SaleChallan, party: partyObj, shop: activeShop);
                                } else {
                                  WebPdfRouterService.downloadPurchaseChallanPdf(challan: item as PurchaseChallan, party: partyObj, shop: activeShop);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                              tooltip: "Delete Challan",
                              onPressed: () {
                                if (isSc) {
                                  webPh.deleteSaleChallan(item.id.toString());
                                } else {
                                  webPh.deletePurchaseChallan(item.id.toString());
                                }
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🗑️ Challan Removed & Stock Reversed!"), backgroundColor: Colors.redAccent));
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("TOTAL ENTRIES: ${filtered.length}", style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
              Text("REGISTER VALUE: ₹${totalRegisterVal.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 14, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String text, bool isPending) {
    Color bg = isPending ? const Color(0x33F59E0B) : const Color(0x3310B981);
    Color fg = isPending ? Colors.orangeAccent : Colors.greenAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4), border: Border.all(color: fg, width: 0.5)),
      child: Text(text, style: TextStyle(color: fg, fontSize: 7.5, fontWeight: FontWeight.w900)),
    );
  }

  Widget _dateTile(String label, DateTime d, Function(DateTime) onPick, String fy) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: d,
          firstDate: WebAppDateLogic.getFYStart(fy),
          lastDate: WebAppDateLogic.getFYEnd(fy),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.black26, border: Border.all(color: Colors.white12), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 8.5, color: Colors.white54, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(DateFormat('dd/MM/yyyy').format(d), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5)),
              ],
            ),
            const Icon(Icons.calendar_month_rounded, color: Color(0xFF38BDF8), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _input(String label, TextEditingController ctrl, {bool isNum = false, bool isCaps = false, bool isHighlight = false, Function(String)? onChanged}) {
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
        fillColor: isHighlight ? const Color(0x330F766E) : Colors.black26,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    );
  }
}
CHALLAN_EOF

# 4. Verify Analyzer and Direct Deploy to Cloudflare Pages
echo -e "${YELLOW}[4/4] Verifying with Analyzer & Compiling (#PH-REV-129)...${NC}"
flutter analyze lib/web_live_sync/

# Flush memory
pkill -f "analysis_server" 2>/dev/null || true
pkill -f "dart_language_server" 2>/dev/null || true
sync
echo 3 | sudo tee /proc/sys/vm/drop_caches 2>/dev/null || true

flutter build web -t lib/web_live_sync/web_main.dart --release --base-href "/" --pwa-strategy=none --no-tree-shake-icons --dart2js-optimization=O1

npx wrangler pages deploy build/web --project-name=pharoah-erp --commit-dirty=true

git add .
git commit -m "Deploy Live Revision #PH-REV-129 Complete Challans Hub" || true
git push origin main || true

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${GREEN}  🎉 CHALLANS HUB DEPLOYED: #PH-REV-129 LIVE!${NC}"
echo -e "${BLUE}====================================================${NC}"
