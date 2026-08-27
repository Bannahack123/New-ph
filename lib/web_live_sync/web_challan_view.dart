// FILE: lib/web_live_sync/web_challan_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'web_models.dart';
import 'pharoah_web_manager.dart';
import 'web_app_date_logic.dart';
import 'web_pharoah_numbering_engine.dart';

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
  Party? scSelectedCustomer;
  List<BillItem> scItems = [];

  // Purchase Challan State
  final pcInternalNoC = TextEditingController();
  final pcSupplierRefC = TextEditingController();
  final pcRemarksC = TextEditingController();
  Party? pcSelectedSupplier;
  List<PurchaseItem> pcItems = [];

  String registerSearch = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
    final webPh = Provider.of<PharoahWebManager>(context, listen: false);

    scNumberC.text = WebPharoahNumberingEngine.getNextNumber(
      prefix: "SCH-",
      startFrom: 101,
      currentList: webPh.saleChallans,
    );

    pcInternalNoC.text = WebPharoahNumberingEngine.getNextNumber(
      prefix: "PCH-",
      startFrom: 1,
      currentList: webPh.purchaseChallans,
    );
  }

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
  // 1. SALE CHALLAN ITEM DIALOG
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
                        Expanded(flex: 3, child: _input("BATCH NO *", batchC, isCaps: true)),
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
                          const Text("ESTIMATED VALUE", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                          Text("₹${itemTotal.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFF0F766E), fontSize: 18, fontWeight: FontWeight.w900)),
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
      date: DateTime.now(),
      items: List.from(scItems),
      totalAmount: total,
      status: "Pending",
      remarks: scRemarksC.text.trim(),
    );

    webPh.saleChallans.add(newChallan);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Delivery Challan ${scNumberC.text} Saved!"), backgroundColor: Colors.green));
    widget.onBack();
  }

  // ===========================================================================
  // 2. PURCHASE CHALLAN ITEM DIALOG
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
            title: Text("INWARD CHALLAN ITEM • ${med.name}", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(flex: 3, child: _input("BATCH NO *", batchC, isCaps: true)),
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
                          Text("₹${itemTotal.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFFD97706), fontSize: 18, fontWeight: FontWeight.w900)),
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
      date: DateTime.now(),
      items: List.from(pcItems),
      totalAmount: total,
      status: "Pending",
      remarks: pcRemarksC.text.trim(),
    );

    webPh.purchaseChallans.add(newChallan);

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
          // Header
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
              tabs: const [
                Tab(text: "OUTWARD SALE CHALLAN", icon: Icon(Icons.local_shipping_rounded, size: 16)),
                Tab(text: "INWARD PURCHASE CHALLAN", icon: Icon(Icons.inventory_2_rounded, size: 16)),
                Tab(text: "CHALLANS REGISTER", icon: Icon(Icons.list_alt_rounded, size: 16)),
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
                        displayStringForOption: (m) => "${m.name} (${m.packing})",
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
                              hintText: "Search Product to add in delivery challan...",
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
                            subtitle: Text("Batch: ${scItems[i].batch} | Qty: ${scItems[i].qty.toInt()} | Rate: ₹${scItems[i].rate}", style: const TextStyle(color: Colors.white54, fontSize: 10)),
                            trailing: Text("₹${scItems[i].total.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFF2DD4BF), fontWeight: FontWeight.bold, fontSize: 12)),
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
                Autocomplete<Party>(
                  displayStringForOption: (p) => p.name,
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
                        hintText: "Select Customer...",
                        hintStyle: TextStyle(color: Colors.white38, fontSize: 11),
                        prefixIcon: Icon(Icons.person, color: Color(0xFF38BDF8), size: 16),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _input("DISPATCH REMARKS / VEHICLE", scRemarksC),
                const Spacer(),
                Text("TOTAL CHALLAN VALUE: ₹${total.toStringAsFixed(0)}", style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
                    onPressed: () => _saveSaleChallan(webPh),
                    child: const Text("SAVE DELIVERY CHALLAN", style: TextStyle(fontWeight: FontWeight.bold)),
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
                              hintText: "Search Product to add in inward challan...",
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
                            subtitle: Text("Batch: ${pcItems[i].batch} | Qty: ${pcItems[i].qty.toInt()} | Pur Rate: ₹${pcItems[i].purchaseRate}", style: const TextStyle(color: Colors.white54, fontSize: 10)),
                            trailing: Text("₹${pcItems[i].total.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.bold, fontSize: 12)),
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
                Autocomplete<Party>(
                  displayStringForOption: (p) => p.name,
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
                        hintText: "Select Supplier...",
                        hintStyle: TextStyle(color: Colors.white38, fontSize: 11),
                        prefixIcon: Icon(Icons.business, color: Color(0xFFF59E0B), size: 16),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _input("INWARD REMARKS", pcRemarksC),
                const Spacer(),
                Text("TOTAL INWARD VALUE: ₹${total.toStringAsFixed(0)}", style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white),
                    onPressed: () => _savePurchaseChallan(webPh),
                    child: const Text("SAVE INWARD CHALLAN", style: TextStyle(fontWeight: FontWeight.bold)),
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
    List<dynamic> all = [...webPh.saleChallans, ...webPh.purchaseChallans];
    all.sort((a, b) => (b.date as DateTime).compareTo(a.date as DateTime));

    final list = all.where((c) {
      String name = c is SaleChallan ? c.partyName : (c as PurchaseChallan).distributorName;
      return name.toLowerCase().contains(registerSearch.toLowerCase()) || c.billNo.toLowerCase().contains(registerSearch.toLowerCase());
    }).toList();

    return Column(
      children: [
        Container(
          height: 38,
          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(8)),
          child: TextField(
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: const InputDecoration(
              hintText: "Search in Challans Register...",
              hintStyle: TextStyle(color: Colors.white38, fontSize: 11),
              prefixIcon: Icon(Icons.search, color: Color(0xFF0F766E), size: 16),
              border: InputBorder.none,
            ),
            onChanged: (v) => setState(() => registerSearch = v),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text("No challans found.", style: TextStyle(color: Colors.white38)))
              : ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (c, i) {
                    final item = list[i];
                    bool isSc = item is SaleChallan;
                    String party = isSc ? item.partyName : (item as PurchaseChallan).distributorName;
                    bool isPending = item.status == "Pending";

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        dense: true,
                        leading: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSc ? const Color(0x330F766E) : const Color(0x33D97706),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(isSc ? "SALE CH" : "PUR CH",
                              style: TextStyle(color: isSc ? const Color(0xFF2DD4BF) : const Color(0xFFFBBF24), fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(party, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        subtitle: Text("No: ${item.billNo} • ${WebAppDateLogic.format(item.date)} • Status: ${item.status}",
                            style: const TextStyle(color: Colors.white38, fontSize: 10)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isPending ? const Color(0x33F59E0B) : const Color(0x3310B981),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "₹${item.totalAmount.toStringAsFixed(0)}",
                            style: TextStyle(color: isPending ? Colors.orangeAccent : Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
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
