// FILE: lib/web_live_sync/web_returns_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'web_models.dart';
import 'pharoah_web_manager.dart';
import 'web_app_date_logic.dart';
import 'web_pharoah_numbering_engine.dart';
import 'web_pdf_router_service.dart';

class WebReturnsView extends StatefulWidget {
  final VoidCallback onBack;
  final int initialTabIndex;

  const WebReturnsView({super.key, required this.onBack, this.initialTabIndex = 0});

  @override
  State<WebReturnsView> createState() => _WebReturnsViewState();
}

class _WebReturnsViewState extends State<WebReturnsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final cnNumberC = TextEditingController();
  final cnExtraDiscC = TextEditingController(text: "0");
  DateTime cnDate = DateTime.now();
  Party? cnSelectedCustomer;
  List<BillItem> cnItems = [];
  bool cnIsBreakage = false;

  final dnNumberC = TextEditingController();
  final dnExtraDiscC = TextEditingController(text: "0");
  DateTime dnDate = DateTime.now();
  Party? dnSelectedSupplier;
  List<PurchaseItem> dnItems = [];
  bool dnIsBreakage = false;

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
    cnNumberC.text = WebPharoahNumberingEngine.getNextNumber(prefix: "CN-", startFrom: 101, currentList: webPh.saleReturns);
    dnNumberC.text = WebPharoahNumberingEngine.getNextNumber(prefix: "DN-", startFrom: 101, currentList: webPh.purchaseReturns);
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

  @override
  Widget build(BuildContext context) {
    final webPh = Provider.of<PharoahWebManager>(context);
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ElevatedButton.icon(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back_rounded, size: 16), label: const Text("BACK"), style: ElevatedButton.styleFrom(backgroundColor: Colors.white12, foregroundColor: Colors.white)),
              const SizedBox(width: 15),
              const Text("RETURNS & REVERSALS HUB", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
            child: TabBar(
              controller: _tabController, indicatorColor: const Color(0xFFDC2626), labelColor: const Color(0xFFF87171), unselectedLabelColor: Colors.white54,
              tabs: const [Tab(text: "CREDIT NOTE"), Tab(text: "DEBIT NOTE"), Tab(text: "REGISTER")],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: TabBarView(controller: _tabController, children: [
            const Center(child: Text("Credit Note Screen", style: TextStyle(color: Colors.white54))),
            const Center(child: Text("Debit Note Screen", style: TextStyle(color: Colors.white54))),
            _buildRegister(filtered, webPh, activeShop),
          ])),
        ],
      ),
    );
  }

  Widget _buildRegister(List<dynamic> filtered, PharoahWebManager webPh, CompanyProfile activeShop) {
    return Column(
      children: [
        TextField(
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: "Search Register...", filled: true, fillColor: Colors.black26, border: InputBorder.none),
          onChanged: (v) => setState(() => registerSearch = v),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (c, i) {
              final item = filtered[i];
              bool isCn = item is SaleReturn;
              String party = isCn ? item.partyName : (item as PurchaseReturn).distributorName;
              return Card(
                color: const Color(0xFF1E293B),
                child: ListTile(
                  title: Text(party, style: const TextStyle(color: Colors.white)),
                  subtitle: Text("No: ${item.billNo}", style: const TextStyle(color: Colors.white54)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.print, color: Colors.cyanAccent),
                        onPressed: () {
                          final pObj = webPh.parties.firstWhere((p) => p.name == party, orElse: () => Party(id: 'temp', name: party));
                          if (isCn) {
                            WebPdfRouterService.printCreditNote(returnObj: item as SaleReturn, party: pObj, shop: activeShop);
                          } else {
                            WebPdfRouterService.printDebitNote(returnObj: item as PurchaseReturn, party: pObj, shop: activeShop);
                          }
                        }
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
