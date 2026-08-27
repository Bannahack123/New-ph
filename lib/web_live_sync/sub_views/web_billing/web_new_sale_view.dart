// FILE: lib/web_live_sync/sub_views/web_billing/web_new_sale_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../web_models.dart';
import '../../pharoah_web_manager.dart';
import '../../web_app_date_logic.dart';
import 'web_item_entry_card.dart';
import 'quick_add_party_modal.dart';
import 'quick_add_product_modal.dart';

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

  Party? selectedParty;
  List<BillItem> billItems = [];
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final webPh = Provider.of<PharoahWebManager>(context, listen: false);
    billNoC.text = webPh.getNextBillNumber("SALE", "INV-", 101);
    billDate = WebAppDateLogic.getSmartDate(webPh.financialYear);
  }

  @override
  void dispose() {
    billNoC.dispose();
    extraDiscC.dispose();
    super.dispose();
  }

  void _openItemEntry(Medicine med, {BillItem? itemToEdit, int? editIndex}) {
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
    showDialog(
      context: context,
      builder: (c) => QuickAddPartyModal(
        webPh: webPh,
        onPartyCreated: (newPartyMap) {
          final pObj = Party.fromMap(newPartyMap);
          setState(() {
            selectedParty = pObj;
          });
        },
      ),
    );
  }

  void _openQuickAddProduct(PharoahWebManager webPh) {
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

  // Calculations
  double get subTotal => billItems.fold(0.0, (sum, it) => sum + it.total);
  double get totalTaxable => billItems.fold(0.0, (sum, it) => sum + (it.qty * it.rate - it.discountRupees));
  double get totalCGST => billItems.fold(0.0, (sum, it) => sum + it.cgst);
  double get totalSGST => billItems.fold(0.0, (sum, it) => sum + it.sgst);
  double get totalIGST => billItems.fold(0.0, (sum, it) => sum + it.igst);
  double get extraDiscount => double.tryParse(extraDiscC.text) ?? 0.0;
  double get rawGrandTotal => (subTotal - extraDiscount);
  double get finalGrandTotal => rawGrandTotal.roundToDouble();
  double get roundOff => double.parse((finalGrandTotal - rawGrandTotal).toStringAsFixed(2));

  void _saveInvoice(PharoahWebManager webPh) {
    if (billItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot save empty bill! Please add products."), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => isSaving = true);

    final Party activeParty = selectedParty ?? Party(id: 'cash', name: 'CASH', group: 'Cash in Hand');

    final newSale = Sale(
      id: "SALE-WEB-${DateTime.now().millisecondsSinceEpoch}",
      billNo: billNoC.text.trim(),
      partyId: activeParty.id,
      partyName: activeParty.name,
      partyGstin: activeParty.gst,
      partyState: activeParty.state,
      date: billDate,
      paymentMode: paymentMode,
      totalAmount: finalGrandTotal,
      extraDiscount: extraDiscount,
      roundOff: roundOff,
      status: "Active",
      items: List.from(billItems),
      sourceTag: "WEB-PORTAL",
      partyAddress: activeParty.address,
      partyCity: activeParty.city,
      partyPhone: activeParty.phone,
      partyEmail: activeParty.email,
      partyDl: activeParty.dl,
      partyPan: activeParty.pan,
    );

    webPh.addSaleAndSync(newSale);
    setState(() => isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ Invoice ${billNoC.text} Saved & Stock Updated!"), backgroundColor: Colors.green),
    );

    widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    final webPh = Provider.of<PharoahWebManager>(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWideScreen = constraints.maxWidth > 920;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderBar(webPh),
            const SizedBox(height: 18),
            if (isWideScreen)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: Column(
                      children: [
                        _buildProductSearchCard(webPh),
                        const SizedBox(height: 16),
                        _buildCartTable(webPh),
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
                  _buildProductSearchCard(webPh),
                  const SizedBox(height: 16),
                  _buildCartTable(webPh),
                  const SizedBox(height: 16),
                  _buildGrandTotalCard(webPh),
                ],
              ),
          ],
        );
      },
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
            label: const Text("BACK", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 14),
          const Icon(Icons.receipt_long_rounded, color: Color(0xFF38BDF8), size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              "NEW TAX INVOICE (SALE BILLING)",
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 120,
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
          const SizedBox(width: 10),
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

  Widget _buildProductSearchCard(PharoahWebManager webPh) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x662563EB), width: 1.2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Autocomplete<Medicine>(
              displayStringForOption: (m) => "${m.name} (${m.packing}) - Stock: ${m.stock.toInt()}",
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) return const Iterable.empty();
                return webPh.medicines.where((m) =>
                    m.name.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                    m.systemId.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: (med) => _openItemEntry(med),
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: "SEARCH PRODUCT / MEDICINE",
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                    hintText: "Type medicine name (e.g. DOLO 650, PAN 40)...",
                    hintStyle: const TextStyle(color: Colors.white24, fontSize: 11),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF38BDF8), size: 18),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                );
              },
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
    );
  }

  Widget _buildCartTable(PharoahWebManager webPh) {
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
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                                onPressed: () => setState(() => billItems.removeAt(idx)),
                              ),
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
          // Responsive Header that never overflows
          Row(
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
              const Expanded(
                child: Text(
                  "CUSTOMER / CONSIGNEE",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => _openQuickAddCustomer(webPh),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 13),
                      SizedBox(width: 4),
                      Text(
                        "NEW",
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 20),

          // Selected Customer Card or Autocomplete
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
                          "GST: ${selectedParty!.gst} | City: ${selectedParty!.city}",
                          style: const TextStyle(color: Colors.white54, fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
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
            Autocomplete<Party>(
              displayStringForOption: (p) => "${p.name} (${p.city})",
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) return const Iterable.empty();
                return webPh.parties.where((p) =>
                    p.name.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                    p.city.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: (p) => setState(() => selectedParty = p),
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

  Widget _buildGrandTotalCard(PharoahWebManager webPh) {
    return Container(
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
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: isSaving ? null : () => _saveInvoice(webPh),
              icon: isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_rounded, size: 18),
              label: Text(
                isSaving ? "SAVING..." : "SAVE & SYNC INVOICE",
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5, letterSpacing: 0.5),
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
