// FILE: lib/web_live_sync/sub_views/web_challans/web_challan_to_bill_converter.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../web_models.dart';
import '../../pharoah_web_manager.dart';
import '../../web_app_date_logic.dart';
import '../../web_pharoah_numbering_engine.dart';

class WebChallanToBillConverter extends StatefulWidget {
  final VoidCallback onBack;

  const WebChallanToBillConverter({super.key, required this.onBack});

  @override
  State<WebChallanToBillConverter> createState() => _WebChallanToBillConverterState();
}

class _WebChallanToBillConverterState extends State<WebChallanToBillConverter> {
  Party? selectedParty;
  List<String> selectedChallanIds = [];
  String partySearch = "";
  DateTime billDate = DateTime.now();
  String paymentMode = "CREDIT";

  @override
  void initState() {
    super.initState();
    final webPh = Provider.of<PharoahWebManager>(context, listen: false);
    billDate = WebAppDateLogic.getSmartDate(webPh.financialYear);
  }

  void _finalizeConversion(PharoahWebManager webPh) {
    if (selectedParty == null || selectedChallanIds.isEmpty) return;

    List<BillItem> combinedItems = [];
    for (var id in selectedChallanIds) {
      var ch = webPh.saleChallans.firstWhere((c) => c.id == id);
      for (var it in ch.items) {
        combinedItems.add(it.copyWith(sourceChallanNo: ch.billNo, sourceChallanId: ch.id));
      }
    }

    String prefix = "INV-";
    int start = 101;
    try {
      final defSeries = webPh.numberingSeries.firstWhere((s) => s.type == "SALE" && s.isDefault && s.isActive);
      prefix = defSeries.prefix;
      start = defSeries.startNumber;
    } catch (_) {}

    String billNo = WebPharoahNumberingEngine.getNextNumber(
      prefix: prefix,
      startFrom: start,
      currentList: webPh.sales,
    );

    double total = combinedItems.fold(0.0, (s, i) => s + i.total);

    final newSale = Sale(
      id: "SALE-WEB-${DateTime.now().millisecondsSinceEpoch}-$billNo",
      billNo: billNo,
      partyId: selectedParty!.id,
      partyName: selectedParty!.name,
      partyGstin: selectedParty!.gst,
      partyState: selectedParty!.state,
      partyAddress: selectedParty!.address,
      partyCity: selectedParty!.city,
      partyPhone: selectedParty!.phone,
      partyEmail: selectedParty!.email,
      partyDl: selectedParty!.dl,
      partyPan: selectedParty!.pan,
      date: billDate,
      paymentMode: paymentMode,
      totalAmount: total.roundToDouble(),
      roundOff: double.parse((total.roundToDouble() - total).toStringAsFixed(2)),
      items: List.from(combinedItems),
      linkedChallanIds: List.from(selectedChallanIds),
      sourceTag: "WEB-PORTAL",
    );

    webPh.sales.add(newSale);
    for (var id in selectedChallanIds) {
      int idx = webPh.saleChallans.indexWhere((c) => c.id == id);
      if (idx != -1) {
        webPh.saleChallans[idx].status = "Billed";
      }
    }

    webPh.rebuildInventory();
    webPh.pushUpdatedDataToCloud();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ Invoice $billNo Generated from ${selectedChallanIds.length} Challans!"), backgroundColor: Colors.green),
    );

    widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    final webPh = Provider.of<PharoahWebManager>(context);

    final pendingChallans = selectedParty == null
        ? <SaleChallan>[]
        : webPh.saleChallans.where((c) => c.partyName.trim().toUpperCase() == selectedParty!.name.trim().toUpperCase() && c.status == "Pending").toList();

    double selectedTotal = webPh.saleChallans
        .where((c) => selectedChallanIds.contains(c.id))
        .fold(0.0, (sum, it) => sum + it.totalAmount);

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
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text("BACK", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 15),
              const Icon(Icons.merge_type_rounded, color: Color(0xFF38BDF8), size: 22),
              const SizedBox(width: 10),
              const Text("SINGLE PARTY CHALLAN TO BILL CONVERTER", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
            child: selectedParty == null
                ? Autocomplete<Party>(
                    displayStringForOption: (p) => p.name,
                    optionsBuilder: (textEditingValue) {
                      if (textEditingValue.text.isEmpty) return const Iterable.empty();
                      return webPh.parties.where((p) => p.group == "Sundry Debtors" && p.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                    },
                    onSelected: (p) => setState(() {
                      selectedParty = p;
                      selectedChallanIds.clear();
                    }),
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        decoration: const InputDecoration(
                          hintText: "Type Customer Name to load pending challans...",
                          hintStyle: TextStyle(color: Colors.white38, fontSize: 11.5),
                          prefixIcon: Icon(Icons.search, color: Color(0xFF38BDF8), size: 18),
                          border: InputBorder.none,
                        ),
                      );
                    },
                  )
                : Row(
                    children: [
                      const CircleAvatar(backgroundColor: Color(0x332563EB), child: Icon(Icons.person_rounded, color: Color(0xFF38BDF8))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "${selectedParty!.name.toUpperCase()} (${pendingChallans.length} Pending Challans)",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 18),
                        onPressed: () => setState(() {
                          selectedParty = null;
                          selectedChallanIds.clear();
                        }),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 14),

          Expanded(
            child: selectedParty == null
                ? const Center(child: Text("Select a customer above to view pending challans.", style: TextStyle(color: Colors.white38)))
                : (pendingChallans.isEmpty
                    ? const Center(child: Text("No pending delivery challans for this customer.", style: TextStyle(color: Colors.white38)))
                    : ListView.builder(
                        itemCount: pendingChallans.length,
                        itemBuilder: (c, i) {
                          final ch = pendingChallans[i];
                          final isChecked = selectedChallanIds.contains(ch.id);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10)),
                            child: CheckboxListTile(
                              activeColor: const Color(0xFF2563EB),
                              value: isChecked,
                              title: Text("${ch.billNo} • ${WebAppDateLogic.format(ch.date)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                              subtitle: Text("Items: ${ch.items.length} • Value: ₹${ch.totalAmount.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white54, fontSize: 10.5)),
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    selectedChallanIds.add(ch.id);
                                  } else {
                                    selectedChallanIds.remove(ch.id);
                                  }
                                });
                              },
                            ),
                          );
                        },
                      )),
          ),

          if (selectedChallanIds.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF38BDF8))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${selectedChallanIds.length} Challans Selected", style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                      Text("Total: ₹${selectedTotal.toStringAsFixed(2)}", style: const TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
                    onPressed: () => _finalizeConversion(webPh),
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text("CONVERT TO FINAL GST BILL", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
