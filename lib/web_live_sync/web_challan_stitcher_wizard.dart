// FILE: lib/web_live_sync/web_challan_stitcher_wizard.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'web_models.dart';
import 'pharoah_web_manager.dart';
import 'web_app_date_logic.dart';
import 'web_pharoah_numbering_engine.dart';
import 'web_pdf_router_service.dart';
import 'sub_views/web_billing/web_new_sale_view.dart';
import 'web_purchase_entry_view.dart';

class WebChallanStitcherWizard extends StatefulWidget {
  final VoidCallback onBack;

  const WebChallanStitcherWizard({super.key, required this.onBack});

  @override
  State<WebChallanStitcherWizard> createState() => _WebChallanStitcherWizardState();
}

class _WebChallanStitcherWizardState extends State<WebChallanStitcherWizard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String funnelStep = "MODE"; // MODE -> ROUTE -> PARTY -> REVIEW
  String selectionMode = "NONE";
  bool isProcessing = false;
  double progressValue = 0.0;
  String progressText = "";

  DateTime batchBillDate = DateTime.now();
  DateTime fromDate = DateTime.now();
  DateTime toDate = DateTime.now();
  String? selectedRoute;
  List<String> selectedPartyNames = [];
  List<Map<String, dynamic>> draftBills = [];
  String partySearch = "";

  static const String currentTestId = "#PH-REV-116";
  final List<String> fyMonths = ["April", "May", "June", "July", "August", "September", "October", "November", "December", "January", "February", "March"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _resetWizard();
      }
    });
    final webPh = Provider.of<PharoahWebManager>(context, listen: false);
    batchBillDate = WebAppDateLogic.getSmartDate(webPh.financialYear);
    fromDate = WebAppDateLogic.getFYStart(webPh.financialYear);
    toDate = WebAppDateLogic.getSmartDate(webPh.financialYear);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _resetWizard() {
    setState(() {
      funnelStep = "MODE";
      selectedRoute = null;
      selectedPartyNames.clear();
      draftBills.clear();
      selectionMode = "NONE";
    });
  }

  void _generateDrafts(PharoahWebManager webPh) {
    setState(() => isProcessing = true);
    List<Map<String, dynamic>> temp = [];
    bool isSale = _tabController.index == 0;

    for (var pName in selectedPartyNames) {
      Party? pObj;
      try {
        pObj = webPh.parties.firstWhere((p) => p.name == pName);
      } catch (_) {
        pObj = Party(id: 'temp', name: pName);
      }

      var chs = isSale
          ? webPh.saleChallans.where((c) => c.partyName == pName && c.status == "Pending").toList()
          : webPh.purchaseChallans.where((c) => c.distributorName == pName && c.status == "Pending").toList();

      if (chs.isEmpty) continue;

      List<dynamic> combinedItems = [];
      for (var c in chs) {
        if (isSale) {
          SaleChallan act = c as SaleChallan;
          for (var it in act.items) {
            combinedItems.add(it.copyWith(sourceChallanNo: act.billNo, sourceChallanId: act.id));
          }
        } else {
          PurchaseChallan act = c as PurchaseChallan;
          for (var it in act.items) {
            combinedItems.add(it.copyWith(sourceChallanNo: act.billNo, sourceChallanId: act.id));
          }
        }
      }

      double total = combinedItems.fold(0.0, (s, i) => s + (i.total as double));

      temp.add({
        'party': pObj,
        'billNo': 'DRAFT',
        'date': batchBillDate,
        'items': combinedItems,
        'total': total,
        'status': 'DRAFT',
        'isSelected': true,
        'challanIds': chs.map((c) => isSale ? (c as SaleChallan).id : (c as PurchaseChallan).id).toList(),
      });
    }

    setState(() {
      draftBills = temp;
      funnelStep = "REVIEW";
      isProcessing = false;
    });
  }

  Future<void> _handleBatchSave(PharoahWebManager webPh) async {
    var selected = draftBills.where((b) => b['isSelected'] && b['status'] == 'DRAFT').toList();
    if (selected.isEmpty) {
      return;
    }

    setState(() { isProcessing = true; progressText = "Finalizing Batch..."; progressValue = 0.5; });
    bool isSale = _tabController.index == 0;

    if (isSale) {
      String prefix = "INV-";
      int start = 101;
      try {
        final defSeries = webPh.numberingSeries.firstWhere((s) => s.type == "SALE" && s.isDefault && s.isActive);
        prefix = defSeries.prefix;
        start = defSeries.startNumber;
      } catch (_) {}

      for (var b in selected) {
        String finalBillNo = WebPharoahNumberingEngine.getNextNumber(prefix: prefix, startFrom: start, currentList: webPh.sales);
        final Party pRef = b['party'] as Party;
        final newSale = Sale(
          id: "SALE-WEB-${DateTime.now().millisecondsSinceEpoch}-$finalBillNo", billNo: finalBillNo, partyId: pRef.id, partyName: pRef.name, partyGstin: pRef.gst, partyState: pRef.state, partyAddress: pRef.address, partyCity: pRef.city, partyPhone: pRef.phone, partyEmail: pRef.email, partyDl: pRef.dl, partyPan: pRef.pan, date: b['date'], paymentMode: "CREDIT", totalAmount: b['total'], items: (b['items'] as List).cast<BillItem>(), linkedChallanIds: List<String>.from(b['challanIds']), sourceTag: "WEB-PORTAL",
        );
        webPh.sales.add(newSale);
        for (var cId in b['challanIds']) {
          int idx = webPh.saleChallans.indexWhere((c) => c.id == cId);
          if (idx != -1) {
            webPh.saleChallans[idx].status = "Billed";
          }
        }
        b['status'] = 'SAVED'; b['billNo'] = finalBillNo;
      }
    } else {
      for (var b in selected) {
        String finalInternalNo = WebPharoahNumberingEngine.getNextNumber(prefix: "PUR-", startFrom: 1, currentList: webPh.purchases);
        final Party pRef = b['party'] as Party;
        final newPurchase = Purchase(
          id: "PUR-WEB-${DateTime.now().millisecondsSinceEpoch}-$finalInternalNo", internalNo: finalInternalNo, billNo: "CH-CONV-${finalInternalNo.replaceAll('PUR-', '')}", partyId: pRef.id, distributorName: pRef.name, date: b['date'], entryDate: DateTime.now(), paymentMode: "CREDIT", totalAmount: b['total'], items: (b['items'] as List).cast<PurchaseItem>(), linkedChallanIds: List<String>.from(b['challanIds']), sourceTag: "WEB-PORTAL",
        );
        webPh.purchases.add(newPurchase);
        for (var cId in b['challanIds']) {
          int idx = webPh.purchaseChallans.indexWhere((c) => c.id == cId);
          if (idx != -1) {
            webPh.purchaseChallans[idx].status = "Billed";
          }
        }
        b['status'] = 'SAVED'; b['billNo'] = finalInternalNo;
      }
    }

    webPh.rebuildInventory();
    await webPh.pushUpdatedDataToCloud();
    
    if (!mounted) return;
    setState(() => isProcessing = false);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ ${selected.length} Challans Stitched & Generated!"), backgroundColor: Colors.green));
  }

  Future<void> _saveSingle(PharoahWebManager webPh, int i) async {
    var b = draftBills[i];
    if (b['status'] == 'SAVED') {
      return;
    }
    for(var draft in draftBills) {
      draft['isSelected'] = false;
    }
    draftBills[i]['isSelected'] = true;
    await _handleBatchSave(webPh);
    if (!mounted) return;
    setState(() { draftBills[i]['isSelected'] = true; }); 
  }

  void _printSingle(PharoahWebManager webPh, int i) async {
    if (draftBills[i]['status'] == 'DRAFT') {
      await _saveSingle(webPh, i);
    }
    if (!mounted) return;
    
    var b = draftBills[i];
    bool isSale = _tabController.index == 0;
    final shopProfile = CompanyProfile.fromMap(webPh.companyProfile);

    if (isSale) {
      var s = webPh.sales.firstWhere((s) => s.billNo == b['billNo']);
      WebPdfRouterService.printSaleInvoice(sale: s, party: b['party'], shop: shopProfile, config: webPh.appConfig);
    } else {
      var p = webPh.purchases.firstWhere((p) => p.internalNo == b['billNo']);
      WebPdfRouterService.printPurchaseInvoice(purchase: p, party: b['party'], shop: shopProfile);
    }
  }

  void _viewDraft(Map<String, dynamic> b) {
    bool isSale = _tabController.index == 0;
    if (isSale) {
      Navigator.push(context, MaterialPageRoute(builder: (c) => Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: WebNewSaleView(onBack: () => Navigator.pop(c), initialParty: b['party'], initialBillNo: b['status'] == 'SAVED' ? b['billNo'] : "DRAFT", initialDate: b['date'], initialMode: "CREDIT", existingItems: (b['items'] as List).cast<BillItem>(), linkedChallanIds: (b['challanIds'] as List).cast<String>(), isReadOnly: true)
      )));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (c) => Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: WebPurchaseEntryView(onBack: () => Navigator.pop(c), initialSupplier: b['party'], initialInternalNo: b['status'] == 'SAVED' ? b['billNo'] : "DRAFT", initialDate: b['date'], initialMode: "CREDIT", existingItems: (b['items'] as List).cast<PurchaseItem>(), linkedChallanIds: (b['challanIds'] as List).cast<String>(), isReadOnly: true)
      )));
    }
  }

  void _editDraft(Map<String, dynamic> b, int i) async {
    bool isSale = _tabController.index == 0;
    if (isSale) {
      await Navigator.push(context, MaterialPageRoute(builder: (c) => Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: WebNewSaleView(onBack: () => Navigator.pop(c), initialParty: b['party'], initialBillNo: b['status'] == 'SAVED' ? b['billNo'] : "DRAFT", initialDate: b['date'], initialMode: "CREDIT", existingItems: (b['items'] as List).cast<BillItem>(), linkedChallanIds: (b['challanIds'] as List).cast<String>(), isReadOnly: false)
      )));
    } else {
      await Navigator.push(context, MaterialPageRoute(builder: (c) => Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: WebPurchaseEntryView(onBack: () => Navigator.pop(c), initialSupplier: b['party'], initialInternalNo: b['status'] == 'SAVED' ? b['billNo'] : "DRAFT", initialDate: b['date'], initialMode: "CREDIT", existingItems: (b['items'] as List).cast<PurchaseItem>(), linkedChallanIds: (b['challanIds'] as List).cast<String>(), isReadOnly: false)
      )));
    }
    if (!mounted) return;
    setState(() { draftBills[i]['status'] = 'SAVED'; draftBills[i]['billNo'] = "MANUAL-MODIFIED"; });
  }

  void _handleZipExport(PharoahWebManager webPh) async {
    var selected = draftBills.where((b) => b['isSelected']).toList();
    if (selected.isEmpty) {
      return;
    }

    if (selected.any((b) => b['status'] == 'DRAFT')) {
      await _handleBatchSave(webPh);
    }

    if (!mounted) return;
    setState(() { isProcessing = true; progressValue = 0.0; progressText = "Preparing Zip..."; });

    try {
      bool isSale = _tabController.index == 0;
      List<dynamic> documentsToZip = [];

      for (var d in selected) {
        if (isSale) {
          final obj = webPh.sales.firstWhere((s) => s.billNo == d['billNo']);
          documentsToZip.add(obj);
        } else {
          final obj = webPh.purchases.firstWhere((p) => p.internalNo == d['billNo']);
          documentsToZip.add(obj);
        }
      }

      final shopProfile = CompanyProfile.fromMap(webPh.companyProfile);
      
      await WebPdfRouterService.downloadBulkZip(
        documents: documentsToZip,
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

      if (!mounted) return;
      setState(() => isProcessing = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("ZIP Error: $e"), backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    final webPh = Provider.of<PharoahWebManager>(context);
    bool isSale = _tabController.index == 0;
    Color color = isSale ? const Color(0xFF2563EB) : const Color(0xFFD97706);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white12, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                onPressed: funnelStep != "MODE" ? () => setState(() => funnelStep = "MODE") : widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: Text(funnelStep != "MODE" ? "STEP BACK" : "BACK", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 15),
              const Icon(Icons.auto_fix_high_rounded, color: Color(0xFF2DD4BF), size: 22),
              const SizedBox(width: 10),
              const Text("CHALLAN TO BILL STITCHER WIZARD", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              const SizedBox(width: 10),
              Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: const Color(0x332DD4BF), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF2DD4BF))), child: const Text(currentTestId, style: TextStyle(color: Color(0xFF2DD4BF), fontSize: 9, fontWeight: FontWeight.w900))),
            ],
          ),
          const SizedBox(height: 15),

          Container(
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
            child: TabBar(
              controller: _tabController,
              indicatorColor: color,
              labelColor: isSale ? const Color(0xFF38BDF8) : const Color(0xFFFBBF24),
              unselectedLabelColor: Colors.white54,
              tabs: const [
                Tab(text: "OUTWARD (SALE CHALLAN TO INVOICE)", icon: Icon(Icons.local_shipping_rounded, size: 16)),
                Tab(text: "INWARD (PURCHASE CHALLAN TO INWARD)", icon: Icon(Icons.inventory_2_rounded, size: 16)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: isProcessing
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    CircularProgressIndicator(color: color, value: progressValue > 0 ? progressValue : null),
                    const SizedBox(height: 15),
                    Text(progressText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                  ]))
                : _buildFunnelStep(webPh, color),
          ),
        ],
      ),
    );
  }

  Widget _buildFunnelStep(PharoahWebManager webPh, Color color) {
    if (funnelStep == "MODE") return _buildStepMode(webPh, color);
    if (funnelStep == "ROUTE") return _buildStepRoute(webPh, color);
    if (funnelStep == "PARTY") return _buildStepParty(webPh, color);
    if (funnelStep == "REVIEW") return _buildStepReview(webPh, color);
    return const SizedBox();
  }

  Widget _buildStepMode(PharoahWebManager webPh, Color color) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 650),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white10)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("STEP 1: SELECT CONVERSION TIMELINE", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            const Text("Choose whether to stitch challans month-wise or select a custom date range", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _modeCard("MONTHLY BATCH", "Select a financial month (Apr - Mar)", Icons.calendar_month_rounded, color, () => _showMonthPicker(webPh.financialYear))),
                const SizedBox(width: 16),
                Expanded(child: _modeCard("CUSTOM DATE RANGE", "Choose custom From and To dates in FY", Icons.date_range_rounded, const Color(0xFF0F766E), () => _pickCustomRange(webPh.financialYear))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeCard(String title, String subtitle, IconData icon, Color cardColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(14), border: Border.all(color: cardColor.withAlpha(120), width: 1.2)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: cardColor.withAlpha(45), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: cardColor, size: 22)),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  void _showMonthPicker(String fy) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white12)),
        title: const Text("Select Month to Stitch", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        content: SizedBox(width: 320, child: ListView.builder(
            shrinkWrap: true, itemCount: fyMonths.length,
            itemBuilder: (ctx, i) => ListTile(
              dense: true, leading: const Icon(Icons.calendar_today, size: 16, color: Color(0xFF38BDF8)),
              title: Text(fyMonths[i], style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(c);
                int yr = int.parse(fy.split('-')[0]); if (yr < 2000) yr += 2000;
                int tM = i + 4; if (tM > 12) { tM -= 12; yr++; }
                setState(() { fromDate = DateTime(yr, tM, 1); toDate = DateTime(yr, tM + 1, 0); funnelStep = "ROUTE"; selectionMode = "MONTHLY"; });
              },
            ),
          )),
      ),
    );
  }

  void _pickCustomRange(String fy) async {
    final picked = await showDateRangePicker(
      context: context, firstDate: WebAppDateLogic.getFYStart(fy), lastDate: WebAppDateLogic.getFYEnd(fy), initialDateRange: DateTimeRange(start: fromDate, end: toDate),
    );
    if (picked != null) {
      setState(() { fromDate = picked.start; toDate = picked.end; funnelStep = "ROUTE"; selectionMode = "CUSTOM"; });
    }
  }

  Widget _buildStepRoute(PharoahWebManager webPh, Color color) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white10)),
        child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("STEP 2: FILTER BY DELIVERY ROUTE / AREA", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            const Text("Filter parties by area or skip to show all customers with pending challans", style: TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 18),
            ListTile(
              tileColor: Colors.black26, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFF2DD4BF))),
              leading: const Icon(Icons.done_all_rounded, color: Color(0xFF2DD4BF)),
              title: const Text("SKIP & SHOW ALL ROUTES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
              onTap: () => setState(() { selectedRoute = null; funnelStep = "PARTY"; }),
            ),
            const SizedBox(height: 10),
            if (webPh.routes.isNotEmpty) ...[
              const Text("OR CHOOSE SPECIFIC ROUTE:", style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(height: 180, child: ListView.builder(
                  shrinkWrap: true, itemCount: webPh.routes.length,
                  itemBuilder: (c, i) => Container(margin: const EdgeInsets.only(bottom: 6), decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8)), child: ListTile(
                      dense: true, leading: const Icon(Icons.map_rounded, color: Color(0xFF38BDF8), size: 16),
                      title: Text(webPh.routes[i].name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      onTap: () => setState(() { selectedRoute = webPh.routes[i].name; funnelStep = "PARTY"; }),
                    )),
                )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepParty(PharoahWebManager webPh, Color color) {
    bool isSale = _tabController.index == 0;
    final pendingPartiesList = webPh.parties.where((p) {
      bool hasPending = isSale
          ? webPh.saleChallans.any((c) => c.partyName.trim().toUpperCase() == p.name.trim().toUpperCase() && c.status == "Pending")
          : webPh.purchaseChallans.any((c) => c.distributorName.trim().toUpperCase() == p.name.trim().toUpperCase() && c.status == "Pending");
      bool matchesRoute = selectedRoute == null || p.route == selectedRoute;
      bool matchesSearch = p.name.toLowerCase().contains(partySearch.toLowerCase());
      return hasPending && matchesRoute && matchesSearch;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Expanded(child: TextField(style: const TextStyle(color: Colors.white, fontSize: 12), decoration: const InputDecoration(hintText: "Search Party Name in Pending List...", hintStyle: TextStyle(color: Colors.white38, fontSize: 11), prefixIcon: Icon(Icons.search, color: Color(0xFF38BDF8), size: 18), border: InputBorder.none), onChanged: (v) => setState(() => partySearch = v))),
              const SizedBox(width: 10),
              TextButton(onPressed: () { setState(() { if (selectedPartyNames.length == pendingPartiesList.length) { selectedPartyNames.clear(); } else { selectedPartyNames = pendingPartiesList.map((e) => e.name).toList(); } }); }, child: Text(selectedPartyNames.length == pendingPartiesList.length ? "UNSELECT ALL" : "SELECT ALL", style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 11))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(child: pendingPartiesList.isEmpty ? const Center(child: Text("No pending challans found for this selection.", style: TextStyle(color: Colors.white38, fontSize: 12))) : ListView.builder(
                  itemCount: pendingPartiesList.length,
                  itemBuilder: (c, i) {
                    final party = pendingPartiesList[i];
                    final isChecked = selectedPartyNames.contains(party.name);
                    int count = isSale ? webPh.saleChallans.where((ch) => ch.partyName == party.name && ch.status == "Pending").length : webPh.purchaseChallans.where((ch) => ch.distributorName == party.name && ch.status == "Pending").length;
                    return Container(margin: const EdgeInsets.only(bottom: 6), decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10)), child: CheckboxListTile(
                        activeColor: color, value: isChecked,
                        title: Text(party.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text("Pending Challans: $count • City: ${party.city}", style: const TextStyle(color: Colors.white54, fontSize: 10.5)),
                        onChanged: (v) { setState(() { if (v == true) { selectedPartyNames.add(party.name); } else { selectedPartyNames.remove(party.name); } }); },
                      ));
                  },
                )),
        if (selectedPartyNames.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () => _generateDrafts(webPh), icon: const Icon(Icons.auto_fix_high_rounded, size: 18), label: Text("STITCH & GENERATE ${selectedPartyNames.length} INVOICES", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5)))),
        ],
      ],
    );
  }

  Widget _buildStepReview(PharoahWebManager webPh, Color color) {
    bool allSelected = draftBills.every((b) => b['isSelected'] == true);
    double totalBatchVal = draftBills.where((b) => b['isSelected']).fold(0.0, (s, e) => s + e['total']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Checkbox(value: allSelected, activeColor: color, onChanged: (v) { setState(() { for (var b in draftBills) { if (b['status'] == 'DRAFT') { b['isSelected'] = v; } } }); }),
              const Text("SELECT ALL DRAFTS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
              const Spacer(),
              InkWell(onTap: () async { final p = await showDatePicker(context: context, initialDate: batchBillDate, firstDate: WebAppDateLogic.getFYStart(webPh.financialYear), lastDate: WebAppDateLogic.getFYEnd(webPh.financialYear)); if (p != null) { setState(() { batchBillDate = p; for (var b in draftBills) { if (b['status'] == 'DRAFT') { b['date'] = p; } } }); } }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)), child: Row(children: [const Icon(Icons.calendar_month, size: 14, color: Color(0xFF38BDF8)), const SizedBox(width: 6), Text("BILL DATE: ${WebAppDateLogic.format(batchBillDate)}", style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold))]))),
              const SizedBox(width: 12),
              
              // BULK ACTIONS: ZIP PDF & SAVE
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () => _handleZipExport(webPh),
                icon: const Icon(Icons.folder_zip_rounded, size: 16),
                label: const Text("ZIP PDF", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () => _handleBatchSave(webPh),
                icon: const Icon(Icons.save_rounded, size: 16),
                label: const Text("SAVE ALL DRAFTS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: draftBills.length,
            itemBuilder: (c, i) {
              final b = draftBills[i];
              bool isSaved = b['status'] == 'SAVED';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: Border.all(color: isSaved ? Colors.greenAccent : Colors.white10)),
                child: Column(
                  children: [
                    ListTile(
                      leading: Checkbox(value: b['isSelected'], activeColor: color, onChanged: isSaved ? null : (v) { setState(() => b['isSelected'] = v); }),
                      title: Row(children: [Text(b['party'].name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)), const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: isSaved ? const Color(0x3310B981) : const Color(0x33F59E0B), borderRadius: BorderRadius.circular(4)), child: Text(isSaved ? "SAVED: ${b['billNo']}" : "DRAFT", style: TextStyle(color: isSaved ? Colors.greenAccent : Colors.orangeAccent, fontSize: 8.5, fontWeight: FontWeight.bold)))]),
                      subtitle: Text("Stitched Items: ${(b['items'] as List).length} • Date: ${WebAppDateLogic.format(b['date'])}", style: const TextStyle(color: Colors.white54, fontSize: 10.5)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("₹${(b['total'] as double).toStringAsFixed(2)}", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(width: 8),
                          if (!isSaved)
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                              onPressed: () => setState(() => draftBills.removeAt(i)),
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Colors.white10),
                    // THE 5 ICONS BAR
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _iconAct(Icons.visibility_rounded, "VIEW", const Color(0xFF38BDF8), () => _viewDraft(b)),
                          _iconAct(Icons.edit_note_rounded, "EDIT", Colors.orangeAccent, () => _editDraft(b, i)),
                          _iconAct(isSaved ? Icons.verified_rounded : Icons.save_rounded, "SAVE", isSaved ? Colors.greenAccent : Colors.white54, () => _saveSingle(webPh, i)),
                          _iconAct(Icons.print_rounded, "PDF", Colors.cyanAccent, () => _printSingle(webPh, i)),
                          _iconAct(Icons.delete_outline_rounded, "DEL", Colors.redAccent, () => setState(() => draftBills.removeAt(i))),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("TOTAL CONVERTED INVOICES: ${draftBills.where((b) => b['isSelected']).length}", style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
              Text("TOTAL BATCH VALUE: ₹${totalBatchVal.toStringAsFixed(2)}", style: const TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _iconAct(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
