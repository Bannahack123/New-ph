#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}   🚀 PHAROAH WEB UPGRADE & DEPLOY: #PH-REV-124    ${NC}"
echo -e "${BLUE}====================================================${NC}\n"

# 1. Update Top Bar with Single Verification Badge (#PH-REV-124)
echo -e "${YELLOW}[1/4] Setting Top Bar Badge to #PH-REV-124...${NC}"
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
                      "#PH-REV-124",
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

# 2. Update WebSaleSummaryView with direct lib/ imports & strict Date-Only Matching
echo -e "${YELLOW}[2/4] Connecting lib/ core modules to WebSaleSummaryView...${NC}"
cat << 'SUMMARY_EOF' > lib/web_live_sync/web_sale_summary_view.dart
// FILE: lib/web_live_sync/web_sale_summary_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

import 'web_models.dart';
import 'pharoah_web_manager.dart';
import 'web_pdf_router_service.dart';
import 'sub_views/web_billing/web_new_sale_view.dart';
import '../../app_date_logic.dart';
import '../../models.dart';
import '../../pdf/sale_report_pdf.dart';

class WebSaleSummaryView extends StatefulWidget {
  final VoidCallback onBack;

  const WebSaleSummaryView({super.key, required this.onBack});

  @override
  State<WebSaleSummaryView> createState() => _WebSaleSummaryViewState();
}

class _WebSaleSummaryViewState extends State<WebSaleSummaryView> {
  DateTime fromDate = DateTime.now();
  DateTime toDate = DateTime.now();
  String searchQuery = "";
  bool _isInit = false;

  bool isSelectionMode = false;
  List<String> selectedBillIds = [];
  bool isProcessing = false;
  double progressValue = 0.0;
  String progressText = "";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final webPh = Provider.of<PharoahWebManager>(context, listen: false);
      final now = DateTime.now();
      toDate = DateTime(now.year, now.month, now.day);
      DateTime thirtyDaysAgo = toDate.subtract(const Duration(days: 30));
      DateTime fyStart = AppDateLogic.getFYStart(webPh.financialYear);
      fromDate = thirtyDaysAgo.isBefore(fyStart) ? fyStart : thirtyDaysAgo;
      _isInit = true;
    }
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  Future<void> _handleBatchZipExport(PharoahWebManager webPh) async {
    if (selectedBillIds.isEmpty) return;

    setState(() { 
      isProcessing = true; 
      progressText = "Preparing Invoices ZIP Bundle..."; 
      progressValue = 0.0;
    });

    try {
      List<Sale> billsToZip = webPh.sales.where((s) => selectedBillIds.contains(s.id)).toList();
      final shopProfile = CompanyProfile.fromMap(webPh.companyProfile);

      await WebPdfRouterService.downloadBulkZip(
        documents: billsToZip,
        shop: shopProfile,
        config: webPh.appConfig,
        onProgress: (v, n) {
          if (mounted) {
            setState(() {
              progressValue = v;
              progressText = "Packing: $n";
            });
          }
        },
      );

      setState(() { 
        isProcessing = false; 
        isSelectionMode = false; 
        selectedBillIds.clear(); 
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Invoice ZIP Bundle exported successfully!"), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Export Error: $e"), backgroundColor: Colors.redAccent));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final webPh = Provider.of<PharoahWebManager>(context);
    final activeShop = CompanyProfile.fromMap(webPh.companyProfile);

    final fDateOnly = _dateOnly(fromDate);
    final tDateOnly = _dateOnly(toDate);

    // Precise Date-Only & Active status match (Direct from live memory)
    List<Sale> filteredSales = webPh.sales.reversed.where((s) {
      final sDateOnly = _dateOnly(s.date);
      bool dateMatch = !sDateOnly.isBefore(fDateOnly) && !sDateOnly.isAfter(tDateOnly);
      bool searchMatch = searchQuery.isEmpty ||
          s.billNo.toLowerCase().contains(searchQuery.toLowerCase()) || 
          s.partyName.toLowerCase().contains(searchQuery.toLowerCase());
      bool isActive = s.status.isEmpty || s.status.toLowerCase() == "active";

      return isActive && dateMatch && searchMatch;
    }).toList();

    double totalTaxable = 0.0;
    double totalTax = 0.0;
    double netTotal = 0.0;
    double cashTotal = 0.0;
    double creditTotal = 0.0;

    for (var s in filteredSales) {
      double sTax = s.items.fold(0.0, (sum, it) => sum + (it.cgst + it.sgst + it.igst));
      totalTax += sTax; 
      totalTaxable += (s.totalAmount - sTax); 
      netTotal += s.totalAmount;
      if (s.paymentMode.toUpperCase() == 'CASH') {
        cashTotal += s.totalAmount;
      } else {
        creditTotal += s.totalAmount;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. TOP HEADER BAR ---
              _buildHeaderBar(webPh, filteredSales, activeShop),

              const SizedBox(height: 16),

              // --- 2. FILTER & SEARCH SECTION ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _dateTile("FROM DATE", fromDate, (d) => setState(() => fromDate = d), webPh.financialYear)),
                        const SizedBox(width: 12),
                        Expanded(child: _dateTile("TO DATE", toDate, (d) => setState(() => toDate = d), webPh.financialYear)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      style: const TextStyle(color: Colors.white, fontSize: 12.5),
                      decoration: InputDecoration(
                        hintText: "Search by Bill No (e.g. INV-101) or Party / Customer Name...", 
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 11.5),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF38BDF8), size: 18),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: Colors.white54, size: 16),
                                onPressed: () => setState(() => searchQuery = ""),
                              )
                            : null,
                        border: InputBorder.none,
                        filled: true,
                        fillColor: Colors.black26,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (v) => setState(() => searchQuery = v),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),

              // --- 3. INVOICES LIST ---
              Expanded(
                child: filteredSales.isEmpty 
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.receipt_long_outlined, size: 40, color: Colors.white24),
                            const SizedBox(height: 12),
                            Text(
                              webPh.sales.isEmpty 
                                ? "No invoices recorded yet in this store database."
                                : "No invoices found between ${DateFormat('dd/MM/yyyy').format(fromDate)} and ${DateFormat('dd/MM/yyyy').format(toDate)}.",
                              style: const TextStyle(color: Colors.white38, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredSales.length,
                      itemBuilder: (c, i) {
                        final s = filteredSales[i];
                        final p = webPh.parties.firstWhere(
                          (x) => x.name == s.partyName, 
                          orElse: () => Party(id: "temp", name: s.partyName, gst: s.partyGstin, state: s.partyState, address: s.partyAddress, city: s.partyCity, phone: s.partyPhone, email: s.partyEmail, dl: s.partyDl),
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelectionMode && selectedBillIds.contains(s.id) ? const Color(0xFF38BDF8) : Colors.white10,
                              width: isSelectionMode && selectedBillIds.contains(s.id) ? 1.5 : 1.0,
                            ),
                          ),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            
                            leading: isSelectionMode 
                              ? Checkbox(
                                  value: selectedBillIds.contains(s.id), 
                                  activeColor: const Color(0xFF38BDF8),
                                  onChanged: (v) => setState(() => v! ? selectedBillIds.add(s.id) : selectedBillIds.remove(s.id)),
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: const BoxDecoration(
                                    color: Color(0x262563EB),
                                    borderRadius: BorderRadius.all(Radius.circular(8)),
                                  ),
                                  child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF38BDF8), size: 18),
                                ),

                            title: Row(
                              children: [
                                Text(s.partyName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                                const SizedBox(width: 8),
                                _badge(s.paymentMode.toUpperCase(), s.paymentMode.toUpperCase() == "CASH" ? Colors.greenAccent : Colors.blueAccent),
                              ],
                            ),
                            subtitle: _buildSubtitleWidget(s),
                            
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min, 
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "₹${s.totalAmount.toStringAsFixed(2)}",
                                      style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w900, fontSize: 14),
                                    ),
                                    Text(
                                      "${s.items.length} items",
                                      style: const TextStyle(color: Colors.white38, fontSize: 9.5),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 14),
                                
                                if (!isSelectionMode) ...[
                                  IconButton(
                                    icon: const Icon(Icons.print_outlined, color: Color(0xFF38BDF8), size: 18), 
                                    tooltip: "Print Landscape Invoice",
                                    onPressed: () => WebPdfRouterService.printSaleInvoice(sale: s, party: p, shop: activeShop, config: webPh.appConfig),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.download_rounded, color: Colors.greenAccent, size: 18), 
                                    tooltip: "Download PDF File",
                                    onPressed: () => WebPdfRouterService.downloadSalePdf(sale: s, party: p, shop: activeShop, config: webPh.appConfig),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_note_rounded, color: Colors.orangeAccent, size: 20), 
                                    tooltip: "Edit / Modify Bill",
                                    onPressed: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (ctx) => Scaffold(
                                        backgroundColor: const Color(0xFF0F172A),
                                        body: WebNewSaleView(
                                          onBack: () => Navigator.pop(ctx),
                                          initialParty: p,
                                          initialBillNo: s.billNo,
                                          initialDate: s.date,
                                          initialMode: s.paymentMode,
                                          existingItems: s.items,
                                          linkedChallanIds: s.linkedChallanIds,
                                          modifySaleId: s.id,
                                          isReadOnly: false,
                                        ),
                                      )));
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18), 
                                    tooltip: "Delete Bill (Reverse Stock)",
                                    onPressed: () => _confirmDelete(webPh, s),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              ),
              
              const SizedBox(height: 16),

              // --- 4. BOTTOM SUMMARY STRIP ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF19243B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF2563EB).withAlpha(100), width: 1.2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                  children: [
                    _botCol("CASH SALES", cashTotal, color: Colors.greenAccent),
                    _botCol("CREDIT SALES", creditTotal, color: Colors.blueAccent),
                    _botCol("TAXABLE AMOUNT", totalTaxable, color: Colors.white70), 
                    _botCol("TOTAL OUTPUT GST", totalTax, color: Colors.orangeAccent), 
                    _botCol("NET TURNOVER", netTotal, isNet: true, color: Colors.greenAccent),
                  ],
                ),
              ),

              // --- 5. BATCH ZIP ACTION BAR ---
              if (isSelectionMode && selectedBillIds.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B), 
                      foregroundColor: Colors.black, 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _handleBatchZipExport(webPh),
                    icon: const Icon(Icons.folder_zip_rounded, size: 18),
                    label: Text("DOWNLOAD ${selectedBillIds.length} SELECTED INVOICES AS ZIP", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
                ),
              ],
            ],
          ),

          if (isProcessing)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFFF59E0B)),
                    const SizedBox(height: 20),
                    Text(progressText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SizedBox(width: 200, child: LinearProgressIndicator(value: progressValue, color: const Color(0xFFF59E0B), backgroundColor: Colors.white10)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderBar(PharoahWebManager webPh, List<Sale> filteredSales, CompanyProfile activeShop) {
    return Row(
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
        const Icon(Icons.description_outlined, color: Color(0xFF38BDF8), size: 22),
        const SizedBox(width: 10),
        const Text(
          "SALES REGISTER / AUDIT",
          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5),
        ),
        const Spacer(),

        if (filteredSales.isNotEmpty) ...[
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
            label: const Text("PRINT SUMMARY REPORT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
            onPressed: () => WebPdfRouterService.printSaleReport(sales: filteredSales, shop: activeShop, from: fromDate, to: toDate),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B),
              foregroundColor: Colors.cyanAccent,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.cyanAccent)),
            ),
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text("DOWNLOAD REPORT PDF", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
            onPressed: () => WebPdfRouterService.downloadSaleReport(sales: filteredSales, shop: activeShop, from: fromDate, to: toDate),
          ),
          const SizedBox(width: 8),
        ],

        if (filteredSales.isNotEmpty)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelectionMode ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: Icon(isSelectionMode ? Icons.close_rounded : Icons.checklist_rtl_rounded, size: 16),
            label: Text(isSelectionMode ? "CANCEL" : "SELECT BILLS (ZIP)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
            onPressed: () => setState(() { 
              isSelectionMode = !isSelectionMode; 
              selectedBillIds.clear(); 
            }),
          ),
      ],
    );
  }

  Widget _buildSubtitleWidget(Sale s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 3),
        Row(
          children: [
            Text("Bill: ${s.billNo} • ${DateFormat('dd/MM/yyyy').format(s.date)}", style: const TextStyle(fontSize: 10.5, color: Colors.white54)),
            const SizedBox(width: 8),
            if (s.linkedChallanIds.isNotEmpty)
              _badge("MERGED", Colors.orangeAccent),
            if (s.sourceTag.isNotEmpty)
              _badge("IMPORT: ${s.sourceTag}", Colors.lightBlueAccent),
          ],
        ),
      ],
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 7.5, fontWeight: FontWeight.w900)),
    );
  }

  Widget _dateTile(String label, DateTime d, Function(DateTime) onPick, String fy) {
    return InkWell(
      onTap: () async { 
        DateTime? p = await showDatePicker(
          context: context,
          initialDate: d,
          firstDate: AppDateLogic.getFYStart(fy),
          lastDate: AppDateLogic.getFYEnd(fy),
        ); 
        if (p != null) onPick(p); 
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), 
        decoration: BoxDecoration(
          color: Colors.black26, 
          border: Border.all(color: Colors.white12), 
          borderRadius: BorderRadius.circular(8),
        ), 
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

  Widget _botCol(String label, double val, {bool isNet = false, Color color = Colors.white}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)), 
        const SizedBox(height: 4),
        Text("₹${val.toStringAsFixed(2)}", style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: isNet ? 18 : 12.5)),
      ],
    );
  }

  void _confirmDelete(PharoahWebManager webPh, Sale sale) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white12)),
        title: const Text("Delete Invoice?", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        content: Text(
          "Are you sure you want to delete '${sale.billNo}'?\n\n• Stock will be automatically reversed.\n• Any linked delivery challans will be reverted back to 'Pending'.",
          style: const TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("CANCEL", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () { 
              webPh.deleteSale(sale.id); 
              Navigator.pop(c); 

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("🗑️ Invoice ${sale.billNo} Deleted & Stock Reversed!"), backgroundColor: Colors.redAccent)
              );
            }, 
            child: const Text("YES, DELETE", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
SUMMARY_EOF

# 3. Update WebNewSaleView with Normalized Date Save
echo -e "${YELLOW}[3/4] Updating WebNewSaleView with normalized date saving...${NC}"
cat << 'SALEVIEW_EOF' > lib/web_live_sync/sub_views/web_billing/web_new_sale_view.dart
// FILE: lib/web_live_sync/sub_views/web_billing/web_new_sale_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../web_models.dart';
import '../../pharoah_web_manager.dart';
import '../../web_app_date_logic.dart';
import '../../web_pharoah_numbering_engine.dart';
import '../../web_pdf_router_service.dart';
import 'web_item_entry_card.dart';
import 'quick_add_party_modal.dart';
import 'quick_add_product_modal.dart';
import '../../../app_date_logic.dart';
import '../../../models.dart';

class WebNewSaleView extends StatefulWidget {
  final VoidCallback onBack;
  final Party? initialParty;
  final String? initialBillNo;
  final DateTime? initialDate;
  final String? initialMode;
  final List<BillItem>? existingItems;
  final List<String>? linkedChallanIds;
  final String? modifySaleId;
  final bool isReadOnly;

  const WebNewSaleView({
    super.key, 
    required this.onBack,
    this.initialParty,
    this.initialBillNo,
    this.initialDate,
    this.initialMode,
    this.existingItems,
    this.linkedChallanIds,
    this.modifySaleId,
    this.isReadOnly = false,
  });

  @override
  State<WebNewSaleView> createState() => _WebNewSaleViewState();
}

class _WebNewSaleViewState extends State<WebNewSaleView> {
  final billNoC = TextEditingController();
  final extraDiscC = TextEditingController(text: "0");
  final productSearchC = TextEditingController();
  final customerSearchC = TextEditingController();

  DateTime billDate = DateTime.now();
  String paymentMode = "CASH";

  NumberingSeries? selectedSeries;
  Party? selectedParty;
  List<BillItem> billItems = [];
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final webPh = Provider.of<PharoahWebManager>(context, listen: false);
    _initBillingSession(webPh);
  }

  void _initBillingSession(PharoahWebManager webPh) {
    if (widget.initialParty != null || widget.existingItems != null) {
      billDate = widget.initialDate ?? DateTime.now();
      paymentMode = widget.initialMode ?? "CASH";
      billNoC.text = widget.initialBillNo ?? "DRAFT";
      selectedParty = widget.initialParty;
      
      if (widget.existingItems != null) {
        billItems = List.from(widget.existingItems!);
      }
      
      if (widget.modifySaleId != null) {
        try {
          final exSale = webPh.sales.firstWhere((s) => s.id == widget.modifySaleId);
          extraDiscC.text = exSale.extraDiscount.toString();
        } catch (_) {}
      }
    } else {
      billDate = AppDateLogic.getSmartDate(webPh.financialYear);
      final activeSeriesList = webPh.numberingSeries.where((s) => s.type == "SALE" && s.isActive).toList();
      if (activeSeriesList.isNotEmpty) {
        selectedSeries = activeSeriesList.firstWhere((s) => s.isDefault, orElse: () => activeSeriesList.first);
      }
      _refreshBillNumber(webPh);
    }
  }

  void _refreshBillNumber(PharoahWebManager webPh) {
    if (widget.initialBillNo != null && widget.initialBillNo != "DRAFT") return;
    String prefix = selectedSeries?.prefix ?? "INV-";
    int start = selectedSeries?.startNumber ?? 101;
    billNoC.text = WebPharoahNumberingEngine.getNextNumber(
      prefix: prefix,
      startFrom: start,
      currentList: webPh.sales,
    );
  }

  void _handlePartySelected(PharoahWebManager webPh, Party party) {
    setState(() {
      selectedParty = party;
      customerSearchC.clear();
      if (party.defaultSeriesId.isNotEmpty) {
        try {
          selectedSeries = webPh.numberingSeries.firstWhere((s) => s.id == party.defaultSeriesId);
        } catch (_) {}
      }
    });
    _refreshBillNumber(webPh);
  }

  @override
  void dispose() {
    billNoC.dispose();
    extraDiscC.dispose();
    productSearchC.dispose();
    customerSearchC.dispose();
    super.dispose();
  }

  void _openItemEntry(Medicine med, {BillItem? itemToEdit, int? editIndex}) {
    if (widget.isReadOnly) return;

    final webPh = Provider.of<PharoahWebManager>(context, listen: false);
    String shopState = (webPh.companyProfile['state'] ?? 'Rajasthan').toString();
    String partyState = selectedParty?.state ?? 'Rajasthan';

    List<BatchInfo> batches = webPh.batchHistory[med.identityKey] ?? [];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => WebItemEntryCard(
        med: med,
        srNo: itemToEdit != null ? itemToEdit.srNo : billItems.length + 1,
        partyState: partyState,
        shopState: shopState,
        availableBatches: batches,
        existingItem: itemToEdit,
        onAdd: (newItem) {
          setState(() {
            if (editIndex != null) {
              billItems[editIndex] = newItem;
            } else {
              billItems.add(newItem);
            }
          });
          Navigator.pop(context);
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  void _openQuickAddCustomer(PharoahWebManager webPh) {
    if (widget.isReadOnly) return;
    showDialog(
      context: context,
      builder: (c) => QuickAddPartyModal(
        webPh: webPh,
        onPartyCreated: (newParty) {
          _handlePartySelected(webPh, newParty);
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
          _openItemEntry(medObj);
        },
      ),
    );
  }

  double get subTotal => billItems.fold(0.0, (sum, it) => sum + it.total);
  double get totalTaxable => billItems.fold(0.0, (sum, it) => sum + (it.qty * it.rate - it.discountRupees));
  double get totalCGST => billItems.fold(0.0, (sum, it) => sum + it.cgst);
  double get totalSGST => billItems.fold(0.0, (sum, it) => sum + it.sgst);
  double get totalIGST => billItems.fold(0.0, (sum, it) => sum + it.igst);
  double get extraDiscount => double.tryParse(extraDiscC.text) ?? 0.0;
  double get rawGrandTotal => (subTotal - extraDiscount);
  double get finalGrandTotal => rawGrandTotal.roundToDouble();
  double get roundOff => double.parse((finalGrandTotal - rawGrandTotal).toStringAsFixed(2));

  void _saveInvoice(PharoahWebManager webPh, {bool andPrint = false}) async {
    if (billItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot save empty bill! Please add products."), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => isSaving = true);
    final Party activeParty = selectedParty ?? Party(id: 'cash', name: 'CASH', group: 'Cash in Hand');

    final newSale = Sale(
      id: widget.modifySaleId ?? "SALE-WEB-${DateTime.now().millisecondsSinceEpoch}",
      billNo: billNoC.text.trim(),
      partyId: activeParty.id,
      partyName: activeParty.name,
      partyGstin: activeParty.gst,
      partyState: activeParty.state,
      date: DateTime(billDate.year, billDate.month, billDate.day, 12, 0, 0),
      paymentMode: paymentMode,
      totalAmount: finalGrandTotal,
      extraDiscount: extraDiscount,
      roundOff: roundOff,
      status: "Active",
      items: List.from(billItems),
      linkedChallanIds: widget.linkedChallanIds ?? [],
      sourceTag: "WEB-PORTAL",
      partyAddress: activeParty.address,
      partyCity: activeParty.city,
      partyPhone: activeParty.phone,
      partyEmail: activeParty.email,
      partyDl: activeParty.dl,
      partyPan: activeParty.pan,
    );

    if (widget.modifySaleId != null) webPh.deleteSale(widget.modifySaleId!);
    webPh.addSaleAndSync(newSale);
    
    if (widget.linkedChallanIds != null) {
      for (var id in widget.linkedChallanIds!) {
        int idx = webPh.saleChallans.indexWhere((c) => c.id == id);
        if (idx != -1) webPh.saleChallans[idx].status = "Billed";
      }
      webPh.pushUpdatedDataToCloud();
    }

    setState(() => isSaving = false);

    if (andPrint) {
      final shopProfile = CompanyProfile.fromMap(webPh.companyProfile);
      await WebPdfRouterService.printSaleInvoice(
        sale: newSale,
        party: activeParty,
        shop: shopProfile,
        config: webPh.appConfig,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Invoice ${billNoC.text} Saved Successfully!"), backgroundColor: Colors.green),
      );
      widget.onBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    final webPh = Provider.of<PharoahWebManager>(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWideScreen = constraints.maxWidth > 1100;

        return IgnorePointer(
          ignoring: widget.isReadOnly,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderBar(webPh),
              const SizedBox(height: 16),
              if (isWideScreen)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 13,
                      child: Column(
                        children: [
                          if (!widget.isReadOnly) _buildProductSearchCard(webPh),
                          if (!widget.isReadOnly) const SizedBox(height: 16),
                          _buildCartTable(webPh),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 340, maxWidth: 420),
                      child: Column(
                        children: [
                          _buildCustomerCard(webPh),
                          const SizedBox(height: 16),
                          _buildGrandTotalCard(webPh),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _buildCustomerCard(webPh),
                    const SizedBox(height: 16),
                    if (!widget.isReadOnly) _buildProductSearchCard(webPh),
                    if (!widget.isReadOnly) const SizedBox(height: 16),
                    _buildCartTable(webPh),
                    const SizedBox(height: 16),
                    _buildGrandTotalCard(webPh),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderBar(PharoahWebManager webPh) {
    final activeSeriesList = webPh.numberingSeries.where((s) => s.type == "SALE" && s.isActive).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white12,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text("BACK", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Icon(Icons.receipt_long_rounded, color: widget.isReadOnly ? Colors.purpleAccent : const Color(0xFF38BDF8), size: 20),
              const SizedBox(width: 8),
              Text(
                widget.isReadOnly ? "VIEW INVOICE" : "TAX INVOICE",
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ],
          ),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (activeSeriesList.isNotEmpty && widget.existingItems == null) ...[
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<NumberingSeries>(
                      value: selectedSeries,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      items: activeSeriesList.map((s) => DropdownMenuItem(value: s, child: Text("${s.name} (${s.prefix})"))).toList(),
                      onChanged: (v) {
                        setState(() => selectedSeries = v);
                        _refreshBillNumber(webPh);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              SizedBox(
                width: 110,
                height: 36,
                child: TextField(
                  controller: billNoC,
                  readOnly: widget.initialBillNo != null || widget.isReadOnly,
                  style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w900, fontSize: 12),
                  decoration: InputDecoration(
                    labelText: "BILL NO",
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 9),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              InkWell(
                onTap: widget.isReadOnly ? null : () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: billDate,
                    firstDate: AppDateLogic.getFYStart(webPh.financialYear),
                    lastDate: AppDateLogic.getFYEnd(webPh.financialYear),
                  );
                  if (picked != null) {
                    setState(() => billDate = picked);
                  }
                },
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, color: Color(0xFF38BDF8), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('dd/MM/yyyy').format(billDate),
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'CASH', label: Text('CASH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                  ButtonSegment(value: 'CREDIT', label: Text('CREDIT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                ],
                selected: {paymentMode},
                onSelectionChanged: widget.isReadOnly ? null : (v) => setState(() => paymentMode = v.first),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductSearchCard(PharoahWebManager webPh) {
    final query = productSearchC.text.trim().toLowerCase();
    final matchingMeds = query.isEmpty
        ? <Medicine>[]
        : webPh.medicines
            .where((m) =>
                m.name.toLowerCase().contains(query) ||
                m.systemId.toLowerCase().contains(query) ||
                m.hsnCode.toLowerCase().contains(query))
            .take(6)
            .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x662563EB), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: productSearchC,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: "SEARCH PRODUCT / MEDICINE",
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                    hintText: "Type medicine name (e.g. DOLO, PAN, AZITHRAL)...",
                    hintStyle: const TextStyle(color: Colors.white24, fontSize: 11),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF38BDF8), size: 18),
                    suffixIcon: productSearchC.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Colors.white54, size: 18),
                            onPressed: () => setState(() => productSearchC.clear()),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onChanged: (v) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: () => _openQuickAddProduct(webPh),
                icon: const Icon(Icons.add_box_rounded, size: 18),
                label: const Text("+ PRODUCT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
              ),
            ],
          ),

          if (matchingMeds.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x3338BDF8)),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: matchingMeds.length,
                itemBuilder: (context, idx) {
                  final med = matchingMeds[idx];
                  return Container(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
                    ),
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      leading: const Icon(Icons.medication_rounded, color: Color(0xFF38BDF8), size: 18),
                      title: Row(
                        children: [
                          Text(med.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                          const SizedBox(width: 8),
                          Text("(${med.packing})", style: const TextStyle(color: Colors.white54, fontSize: 11)),
                          const Spacer(),
                          Text(
                            "Stock: ${med.stock.toInt()} Qty",
                            style: TextStyle(
                              color: med.stock > 0 ? Colors.greenAccent : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        "MRP: ₹${med.mrp.toStringAsFixed(2)} | Rate A: ₹${med.rateA.toStringAsFixed(2)} | GST: ${med.gst.toInt()}%",
                        style: const TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                      onTap: () {
                        setState(() => productSearchC.clear());
                        _openItemEntry(med);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCartTable(PharoahWebManager webPh) {
    return Container(
      width: double.infinity,
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
              if (billItems.isNotEmpty && !widget.isReadOnly)
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
                        _th("RATE"),
                        _th("GST%"),
                        _th("TOTAL"),
                        _th("ACTIONS"),
                      ],
                    ),
                    ...billItems.asMap().entries.map((entry) {
                      int idx = entry.key;
                      BillItem it = entry.value;
                      String qtyDisp = "${it.qty.toInt()}${it.freeQty > 0 ? ' + ${it.freeQty.toInt()}' : ''}";

                      return TableRow(
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10))),
                        children: [
                          _td("${idx + 1}"),
                          _td(it.name, isLeft: true, isBold: true),
                          _td(it.packing),
                          _td(it.batch),
                          _td(it.exp),
                          _td(qtyDisp, isBold: true, color: Colors.cyanAccent),
                          _td("₹${it.rate.toStringAsFixed(2)}"),
                          _td("${it.gstRate.toInt()}%"),
                          _td("₹${it.total.toStringAsFixed(2)}", isBold: true, color: Colors.greenAccent),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (!widget.isReadOnly)
                                IconButton(
                                  icon: const Icon(Icons.edit_note_rounded, size: 16, color: Color(0xFF38BDF8)),
                                  onPressed: () {
                                    final med = webPh.medicines.firstWhere(
                                      (m) => m.id == it.medicineID || m.name == it.name,
                                      orElse: () => Medicine(id: it.medicineID, name: it.name, packing: it.packing),
                                    );
                                    _openItemEntry(med, itemToEdit: it, editIndex: idx);
                                  },
                                ),
                              if (!widget.isReadOnly)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                                  onPressed: () => setState(() => billItems.removeAt(idx)),
                                ),
                              if (widget.isReadOnly)
                                const Icon(Icons.lock_rounded, size: 14, color: Colors.white38)
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

  Widget _buildCustomerCard(PharoahWebManager webPh) {
    final custQuery = customerSearchC.text.trim().toLowerCase();
    final matchingParties = custQuery.isEmpty
        ? <Party>[]
        : webPh.parties
            .where((p) =>
                p.name.toLowerCase().contains(custQuery) ||
                p.city.toLowerCase().contains(custQuery))
            .take(5)
            .toList();

    return Container(
      width: double.infinity,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0x332563EB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded, color: Color(0xFF38BDF8), size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "CUSTOMER / CONSIGNEE",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              if (!widget.isReadOnly)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
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
          const Divider(color: Colors.white10, height: 20),

          if (selectedParty != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x662563EB)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedParty!.name.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "GST: ${selectedParty!.gst} | State: ${selectedParty!.state} | Bal: ₹${selectedParty!.opBal.toStringAsFixed(0)}",
                          style: const TextStyle(color: Colors.white54, fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (!widget.isReadOnly)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: Colors.redAccent),
                      onPressed: () {
                        setState(() => selectedParty = null);
                        _refreshBillNumber(webPh);
                      },
                    ),
                ],
              ),
            )
          else ...[
            TextField(
              controller: customerSearchC,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              decoration: InputDecoration(
                hintText: "Search Customer by Name or City (Default: CASH)...",
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                prefixIcon: const Icon(Icons.person_search, color: Colors.cyanAccent, size: 18),
                suffixIcon: customerSearchC.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54, size: 16),
                        onPressed: () => setState(() => customerSearchC.clear()),
                      )
                    : null,
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onChanged: (v) => setState(() {}),
            ),

            if (matchingParties.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x3338BDF8)),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  itemCount: matchingParties.length,
                  itemBuilder: (context, idx) {
                    final party = matchingParties[idx];
                    return ListTile(
                      dense: true,
                      title: Text(party.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      subtitle: Text("${party.city} | GST: ${party.gst}", style: const TextStyle(color: Colors.white38, fontSize: 9.5)),
                      onTap: () => _handlePartySelected(webPh, party),
                    );
                  },
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildGrandTotalCard(PharoahWebManager webPh) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF19243B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x662563EB), width: 1.2),
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
                  readOnly: widget.isReadOnly,
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
          if (!widget.isReadOnly) ...[
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: isSaving ? null : () => _saveInvoice(webPh, andPrint: false),
                icon: isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_rounded, size: 18),
                label: Text(
                  isSaving ? "SAVING..." : "SAVE & SYNC INVOICE",
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5, letterSpacing: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton.icon(
                style: ElevatedButton.styleFrom(
                  foregroundColor: const Color(0xFF38BDF8),
                  side: const BorderSide(color: Color(0xFF38BDF8), width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isSaving ? null : () => _saveInvoice(webPh, andPrint: true),
                icon: const Icon(Icons.print_rounded, size: 16),
                label: const Text("SAVE & PRINT INVOICE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38BDF8),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () async {
                  final Party activeParty = selectedParty ?? Party(id: 'cash', name: 'CASH', group: 'Cash in Hand');
                  final tempSale = Sale(
                    id: "temp", billNo: billNoC.text.trim(), partyId: activeParty.id, partyName: activeParty.name,
                    partyGstin: activeParty.gst, partyState: activeParty.state, date: billDate, paymentMode: paymentMode,
                    totalAmount: finalGrandTotal, extraDiscount: extraDiscount, roundOff: roundOff,
                    status: "Active", items: List.from(billItems), sourceTag: "WEB-PORTAL",
                  );
                  final shopProfile = CompanyProfile.fromMap(webPh.companyProfile);
                  await WebPdfRouterService.printSaleInvoice(sale: tempSale, party: activeParty, shop: shopProfile, config: webPh.appConfig);
                },
                icon: const Icon(Icons.print_rounded, size: 18),
                label: const Text("PRINT THIS INVOICE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5, letterSpacing: 0.5)),
              ),
            ),
          ]
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
SALEVIEW_EOF

# 4. Compile Web App and Push to Cloudflare & Git
echo -e "${YELLOW}[4/4] Compiling Web Workstation Bundle (#PH-REV-124)...${NC}"
flutter build web -t lib/web_live_sync/web_main.dart --release --base-href "/" --pwa-strategy=none

git add .
git commit -m "Deploy Web Revision #PH-REV-124 with Universal lib imports & normalized dates" || true
git push origin main || true

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${GREEN}  🎉 CODE COMPILED & COMMITTED: #PH-REV-124${NC}"
echo -e "${BLUE}====================================================${NC}"
