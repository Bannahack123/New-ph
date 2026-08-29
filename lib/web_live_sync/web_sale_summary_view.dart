// FILE: lib/web_live_sync/web_sale_summary_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'web_models.dart';
import 'pharoah_web_manager.dart';
import 'web_app_date_logic.dart';
import 'web_pdf_router_service.dart';
import 'sub_views/web_billing/web_new_sale_view.dart';

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

  // --- SELECTION & PROCESSING STATE ---
  bool isSelectionMode = false;
  List<String> selectedBillIds = [];
  bool isProcessing = false;
  double progressValue = 0.0;
  String progressText = "";

  static const String currentTestId = "#PH-REV-117";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final webPh = Provider.of<PharoahWebManager>(context, listen: false);
      toDate = WebAppDateLogic.getSmartDate(webPh.financialYear);
      DateTime thirtyDaysAgo = toDate.subtract(const Duration(days: 30));
      DateTime fyStart = WebAppDateLogic.getFYStart(webPh.financialYear);
      fromDate = thirtyDaysAgo.isBefore(fyStart) ? fyStart : thirtyDaysAgo;
      _isInit = true;
    }
  }

  // --- BULK ZIP EXPORT LOGIC ---
  Future<void> _handleBatchZipExport(PharoahWebManager webPh) async {
    if (selectedBillIds.isEmpty) return;

    setState(() { 
      isProcessing = true; 
      progressText = "Preparing Audit Bundle..."; 
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
          const SnackBar(content: Text("✅ Audit bundle exported successfully!"), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final webPh = Provider.of<PharoahWebManager>(context);
    final activeShop = CompanyProfile.fromMap(webPh.companyProfile);

    // Filter Logic
    List<Sale> filteredSales = webPh.sales.reversed.where((s) {
      bool dateMatch = s.date.isAfter(fromDate.subtract(const Duration(days: 1))) && 
                       s.date.isBefore(toDate.add(const Duration(days: 1)));
      bool searchMatch = s.billNo.toLowerCase().contains(searchQuery.toLowerCase()) || 
                         s.partyName.toLowerCase().contains(searchQuery.toLowerCase());
      return s.status == "Active" && dateMatch && searchMatch;
    }).toList();

    // Calculations
    double totalTaxable = 0; double totalTax = 0; double netTotal = 0;
    for(var s in filteredSales) {
      double sTax = s.items.fold(0.0, (sum, it) => sum + (it.cgst + it.sgst + it.igst));
      totalTax += sTax; 
      totalTaxable += (s.totalAmount - sTax); 
      netTotal += s.totalAmount;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Stack( // Stack for Progress Overlay
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. HEADER BAR ---
              _buildHeaderBar(webPh, filteredSales.isNotEmpty),

              const SizedBox(height: 16),

              // --- 2. FILTER SECTION ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _dateTile("FROM", fromDate, (d) => setState(()=> fromDate = d), webPh.financialYear)),
                        const SizedBox(width: 10),
                        Expanded(child: _dateTile("TO", toDate, (d) => setState(()=> toDate = d), webPh.financialYear)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: const InputDecoration(
                        hintText: "Search Bill No or Party Name...", 
                        hintStyle: TextStyle(color: Colors.white38),
                        prefixIcon: Icon(Icons.search, color: Color(0xFF38BDF8), size: 18), 
                        border: InputBorder.none,
                        filled: true,
                        fillColor: Colors.black26,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (v) => setState(() => searchQuery = v)
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),

              // --- 3. LIST SECTION ---
              Expanded(
                child: filteredSales.isEmpty 
                ? const Center(child: Text("No records found for selected period.", style: TextStyle(color: Colors.white38)))
                : ListView.builder(
                  itemCount: filteredSales.length,
                  itemBuilder: (c, i) {
                    final s = filteredSales[i];
                    final p = webPh.parties.firstWhere(
                      (x) => x.name == s.partyName, 
                      orElse: () => Party(id: "temp", name: s.partyName, gst: s.partyGstin, state: s.partyState)
                    );

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelectionMode && selectedBillIds.contains(s.id) ? Colors.blueAccent : Colors.white10),
                      ),
                      child: ListTile(
                        dense: true,
                        // --- LEADING CHECKBOX (Audit Mode) ---
                        leading: isSelectionMode 
                          ? Checkbox(
                              value: selectedBillIds.contains(s.id), 
                              activeColor: const Color(0xFF38BDF8),
                              onChanged: (v) => setState(() => v! ? selectedBillIds.add(s.id) : selectedBillIds.remove(s.id))
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(color: const Color(0x3338BDF8), borderRadius: BorderRadius.circular(6)),
                              child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF38BDF8), size: 16),
                            ),

                        title: Text(s.partyName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: _buildSubtitleWidget(s),
                        
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min, 
                          children: [
                            Text(
                              "₹${s.totalAmount.toStringAsFixed(2)}",
                              style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(width: 12),
                            // Action Icons
                            if (!isSelectionMode) ...[
                              IconButton(
                                icon: const Icon(Icons.print_rounded, color: Color(0xFF38BDF8), size: 18), 
                                tooltip: "Print Document",
                                onPressed: () => WebPdfRouterService.printSaleInvoice(sale: s, party: p, shop: activeShop, config: webPh.appConfig),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_note_rounded, color: Colors.orangeAccent, size: 18), 
                                tooltip: "Edit Bill",
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (c) => Scaffold(
                                    backgroundColor: const Color(0xFF0F172A),
                                    body: WebNewSaleView(onBack: () => Navigator.pop(c), initialParty: p, initialBillNo: s.billNo, initialDate: s.date, initialMode: s.paymentMode, existingItems: s.items, linkedChallanIds: s.linkedChallanIds, modifySaleId: s.id, isReadOnly: false),
                                  )));
                                }
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18), 
                                tooltip: "Delete",
                                onPressed: () => _confirmDelete(webPh, s.id)
                              ),
                            ]
                          ]
                        ),
                      ),
                    );
                  },
                )
              ),
              
              const SizedBox(height: 16),

              // --- 4. BOTTOM SUMMARY BAR ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1B4B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF312E81)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                  children: [
                    _botCol("TAXABLE AMOUNT", totalTaxable), 
                    _botCol("TOTAL GST", totalTax), 
                    _botCol("NET TOTAL", netTotal, isNet: true, color: Colors.greenAccent),
                  ]
                ),
              ),

              // --- 5. BATCH ZIP ACTION BAR (Selection Mode Only) ---
              if (isSelectionMode && selectedBillIds.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B), 
                      foregroundColor: Colors.black, 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ),
                    onPressed: () => _handleBatchZipExport(webPh),
                    icon: const Icon(Icons.folder_zip_rounded, size: 18),
                    label: Text("DOWNLOAD ${selectedBillIds.length} BILLS AS ZIP", style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                )
              ],
            ],
          ),

          // --- PROGRESS OVERLAY ---
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

  Widget _buildHeaderBar(PharoahWebManager webPh, bool hasData) {
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
          "SALES REGISTER / HISTORY",
          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0x3310B981),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.greenAccent),
          ),
          child: const Text(
            currentTestId,
            style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.w900),
          ),
        ),
        const Spacer(),
        if (webPh.appConfig.isAuditMode && hasData)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelectionMode ? const Color(0xFFEF4444) : const Color(0xFF38BDF8),
              foregroundColor: isSelectionMode ? Colors.white : Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: Icon(isSelectionMode ? Icons.close_rounded : Icons.checklist_rtl_rounded, size: 16),
            label: Text(isSelectionMode ? "CANCEL" : "SELECT BILLS", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
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
        const SizedBox(height: 4),
        Row(children: [
          Text("Bill: ${s.billNo} | ${WebAppDateLogic.format(s.date)}", style: const TextStyle(fontSize: 10.5, color: Colors.white54)),
          const SizedBox(width: 8),
          if (s.linkedChallanIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: const Color(0x33F59E0B), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFF59E0B))),
              child: const Text("MERGED", style: TextStyle(color: Colors.orangeAccent, fontSize: 7.5, fontWeight: FontWeight.bold)),
            ),
          if (s.sourceTag.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: 5),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: const Color(0x3338BDF8), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFF38BDF8))),
              child: Text("IMPORT: ${s.sourceTag}", style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 7.5, fontWeight: FontWeight.bold)),
            ),
        ]),
      ],
    );
  }

  Widget _dateTile(String l, DateTime d, Function(DateTime) onPick, String fy) {
    return InkWell(
      onTap: () async { 
        DateTime? p = await showDatePicker(
          context: context,
          initialDate: d,
          firstDate: WebAppDateLogic.getFYStart(fy),
          lastDate: WebAppDateLogic.getFYEnd(fy),
        ); 
        if(p != null) onPick(p); 
      },
      child: Container(
        padding: const EdgeInsets.all(10), 
        decoration: BoxDecoration(
          color: Colors.black26, 
          border: Border.all(color: Colors.white12), 
          borderRadius: BorderRadius.circular(8)
        ), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            Text(l, style: const TextStyle(fontSize: 8.5, color: Colors.white54, fontWeight: FontWeight.bold)), 
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_month_rounded, color: Color(0xFF38BDF8), size: 14),
                const SizedBox(width: 6),
                Text(DateFormat('dd/MM/yyyy').format(d), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
              ],
            )
          ]
        )
      ),
    );
  }

  Widget _botCol(String l, double v, {bool isNet = false, Color color = Colors.white}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l, style: const TextStyle(color: Colors.white54, fontSize: 9.5, fontWeight: FontWeight.bold)), 
        const SizedBox(height: 4),
        Text("₹${v.toStringAsFixed(2)}", style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: isNet ? 18 : 13))
      ]
    );
  }

  void _confirmDelete(PharoahWebManager webPh, String id) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white12)),
        title: const Text("Delete Bill?", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to permanently delete this bill? This will reverse the stock levels.", style: TextStyle(color: Colors.white70, fontSize: 11.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("CANCEL", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () { 
              webPh.deleteSale(id); 
              Navigator.pop(c); 
            }, 
            child: const Text("YES, DELETE", style: TextStyle(fontWeight: FontWeight.bold))
          )
        ],
      ),
    );
  }
}
