// FILE: lib/web_live_sync/web_returns_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'web_models.dart';
import 'pharoah_web_manager.dart';
import 'web_app_date_logic.dart';
import 'web_pharoah_numbering_engine.dart';

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
  Party? cnSelectedCustomer;
  List<BillItem> cnItems = [];
  bool cnIsBreakage = false;

  // Debit Note Form State
  final dnNumberC = TextEditingController();
  final dnExtraDiscC = TextEditingController(text: "0");
  Party? dnSelectedSupplier;
  List<PurchaseItem> dnItems = [];
  bool dnIsBreakage = false;

  String registerSearch = "";

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
  }

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
            title: Text("RETURN ITEM • ${med.name}", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
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
                        Expanded(child: _input("RETURN RATE ₹ *", rateC, isNum: true, isHighlight: true, onChanged: (_) => setDialogState(() {}))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _input("RETURN QTY *", qtyC, isNum: true, isHighlight: true, onChanged: (_) => setDialogState(() {}))),
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
                          const Text("CREDIT ITEM VALUE", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                          Text("₹${itemTotal.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFFDC2626), fontSize: 18, fontWeight: FontWeight.w900)),
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
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
                onPressed: () {
                  if (batchC.text.trim().isEmpty || q <= 0 || r <= 0) return;
                  final newItem = BillItem(
                    id: "CNITM-${DateTime.now().millisecondsSinceEpoch}",
                    srNo: cnItems.length + 1,
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
                    isBreakage: cnIsBreakage,
                  );
                  setState(() => cnItems.add(newItem));
                  Navigator.pop(c);
                },
                child: const Text("ADD TO CREDIT NOTE", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
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
      date: DateTime.now(),
      items: List.from(cnItems),
      totalAmount: finalTotal,
      extraDiscount: extraD,
      roundOff: rOff,
      returnType: cnIsBreakage ? "Breakage" : "Sellable",
      status: "Active",
    );

    webPh.saleReturns.add(newReturn);
    webPh.rebuildInventory();

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
      date: DateTime.now(),
      items: List.from(dnItems),
      totalAmount: finalTotal,
      extraDiscount: extraD,
      roundOff: rOff,
      returnType: dnIsBreakage ? "Breakage" : "Sellable",
      status: "Active",
    );

    webPh.purchaseReturns.add(newReturn);
    webPh.rebuildInventory();

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Debit Note ${dnNumberC.text} Saved!"), backgroundColor: Colors.green));
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
          // Top Header
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
              const Icon(Icons.assignment_return_rounded, color: Color(0xFFDC2626), size: 22),
              const SizedBox(width: 10),
              const Text(
                "RETURNS & REVERSALS HUB",
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
              indicatorColor: const Color(0xFFDC2626),
              labelColor: const Color(0xFFF87171),
              unselectedLabelColor: Colors.white54,
              tabs: const [
                Tab(text: "CREDIT NOTE (SALE RETURN)", icon: Icon(Icons.assignment_return_rounded, size: 16)),
                Tab(text: "DEBIT NOTE (PURCHASE RETURN)", icon: Icon(Icons.remove_shopping_cart_rounded, size: 16)),
                Tab(text: "RETURNS AUDIT REGISTER", icon: Icon(Icons.format_list_bulleted_rounded, size: 16)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab Views
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
        // Left Table
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
                        onSelected: (med) => _openCnItemDialog(webPh, med),
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            decoration: const InputDecoration(
                              hintText: "Search Product to return from customer...",
                              hintStyle: TextStyle(color: Colors.white38, fontSize: 11),
                              prefixIcon: Icon(Icons.search, color: Color(0xFFDC2626), size: 18),
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
                            trailing: Text("₹${cnItems[i].total.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFFF87171), fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Right Summary
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
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Breakage / Expiry Mode", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  subtitle: const Text("Will NOT add to sellable stock", style: TextStyle(color: Colors.white54, fontSize: 9)),
                  value: cnIsBreakage,
                  activeColor: Colors.orangeAccent,
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
                const Spacer(),
                Text("NET CREDIT VALUE: ₹${netTotal.toStringAsFixed(0)}", style: const TextStyle(color: Color(0xFFF87171), fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
                    onPressed: () => _saveCreditNote(webPh),
                    child: const Text("SAVE CREDIT NOTE", style: TextStyle(fontWeight: FontWeight.bold)),
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
                          return webPh.medicines.where((m) =>
                              m.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                        },
                        onSelected: (med) => _openDnItemDialog(webPh, med),
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            decoration: const InputDecoration(
                              hintText: "Search Product to return to supplier...",
                              hintStyle: TextStyle(color: Colors.white38, fontSize: 11),
                              prefixIcon: Icon(Icons.search, color: Color(0xFF92400E), size: 18),
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
                child: dnItems.isEmpty
                    ? const Center(child: Text("No items in debit note.", style: TextStyle(color: Colors.white38)))
                    : ListView.builder(
                        itemCount: dnItems.length,
                        itemBuilder: (c, i) => Card(
                          color: const Color(0xFF1E293B),
                          margin: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            dense: true,
                            title: Text(dnItems[i].name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            subtitle: Text("Batch: ${dnItems[i].batch} | Qty: ${dnItems[i].qty.toInt()} | Pur Rate: ₹${dnItems[i].purchaseRate}", style: const TextStyle(color: Colors.white54, fontSize: 10)),
                            trailing: Text("₹${dnItems[i].total.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.bold, fontSize: 12)),
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
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Breakage / Expiry Mode", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  subtitle: const Text("Outward from non-sellable stock", style: TextStyle(color: Colors.white54, fontSize: 9)),
                  value: dnIsBreakage,
                  activeColor: Colors.orangeAccent,
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
                const Spacer(),
                Text("NET DEBIT VALUE: ₹${netTotal.toStringAsFixed(0)}", style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF92400E), foregroundColor: Colors.white),
                    onPressed: () => _saveDebitNote(webPh),
                    child: const Text("SAVE DEBIT NOTE", style: TextStyle(fontWeight: FontWeight.bold)),
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
    List<dynamic> all = [...webPh.saleReturns, ...webPh.purchaseReturns];
    all.sort((a, b) => (b.date as DateTime).compareTo(a.date as DateTime));

    final list = all.where((r) {
      String name = r is SaleReturn ? r.partyName : (r as PurchaseReturn).distributorName;
      return name.toLowerCase().contains(registerSearch.toLowerCase()) || r.billNo.toLowerCase().contains(registerSearch.toLowerCase());
    }).toList();

    return Column(
      children: [
        Container(
          height: 38,
          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(8)),
          child: TextField(
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: const InputDecoration(
              hintText: "Search in Returns Register...",
              hintStyle: TextStyle(color: Colors.white38, fontSize: 11),
              prefixIcon: Icon(Icons.search, color: Color(0xFFDC2626), size: 16),
              border: InputBorder.none,
            ),
            onChanged: (v) => setState(() => registerSearch = v),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text("No return records found.", style: TextStyle(color: Colors.white38)))
              : ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (c, i) {
                    final item = list[i];
                    bool isCn = item is SaleReturn;
                    String party = isCn ? item.partyName : (item as PurchaseReturn).distributorName;
                    Color color = isCn ? const Color(0xFFDC2626) : const Color(0xFFF59E0B);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        dense: true,
                        leading: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: color.withAlpha(50), borderRadius: BorderRadius.circular(4)),
                          child: Text(isCn ? "CN" : "DN", style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(party, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        subtitle: Text("No: ${item.billNo} • ${WebAppDateLogic.format(item.date)}", style: const TextStyle(color: Colors.white38, fontSize: 10)),
                        trailing: Text("₹${item.totalAmount.toStringAsFixed(2)}", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
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
        fillColor: isHighlight ? const Color(0x33DC2626) : Colors.black26,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    );
  }
}
