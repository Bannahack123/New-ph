// FILE: lib/web_live_sync/sub_views/web_challans/web_purchase_challan_register.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../web_models.dart';
import '../../pharoah_web_manager.dart';
import '../../web_app_date_logic.dart';
import 'web_purchase_challan_view.dart';

class WebPurchaseChallanRegister extends StatefulWidget {
  final VoidCallback onBack;

  const WebPurchaseChallanRegister({super.key, required this.onBack});

  @override
  State<WebPurchaseChallanRegister> createState() => _WebPurchaseChallanRegisterState();
}

class _WebPurchaseChallanRegisterState extends State<WebPurchaseChallanRegister> {
  String searchQuery = "";
  DateTime fromDate = DateTime.now();
  DateTime toDate = DateTime.now();
  String statusFilter = "ALL";

  @override
  void initState() {
    super.initState();
    final webPh = Provider.of<PharoahWebManager>(context, listen: false);
    toDate = WebAppDateLogic.getSmartDate(webPh.financialYear);
    fromDate = toDate.subtract(const Duration(days: 30));
    DateTime fyStart = WebAppDateLogic.getFYStart(webPh.financialYear);
    if (fromDate.isBefore(fyStart)) fromDate = fyStart;
  }

  @override
  Widget build(BuildContext context) {
    final webPh = Provider.of<PharoahWebManager>(context);

    final list = webPh.purchaseChallans.reversed.where((ch) {
      bool matchesSearch = ch.distributorName.toLowerCase().contains(searchQuery.toLowerCase()) ||
                           ch.billNo.toLowerCase().contains(searchQuery.toLowerCase()) ||
                           ch.internalNo.toLowerCase().contains(searchQuery.toLowerCase());
      bool matchesDate = ch.date.isAfter(fromDate.subtract(const Duration(days: 1))) &&
                         ch.date.isBefore(toDate.add(const Duration(days: 1)));
      bool matchesStatus = statusFilter == "ALL" || ch.status == statusFilter;
      return matchesSearch && matchesDate && matchesStatus;
    }).toList();

    double totalVal = list.fold(0.0, (sum, c) => sum + c.totalAmount);

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
              const Icon(Icons.history_edu_rounded, color: Color(0xFFFBBF24), size: 22),
              const SizedBox(width: 10),
              const Text(
                "INWARD CHALLAN AUDIT REGISTER",
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
              const Spacer(),
              Text(
                "TOTAL VALUE: ₹${totalVal.toStringAsFixed(0)}",
                style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 13, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 15),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: "Search by Supplier Name, Ref No or ID...",
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 11),
                      prefixIcon: Icon(Icons.search, color: Color(0xFFFBBF24), size: 16),
                      border: InputBorder.none,
                    ),
                    onChanged: (v) => setState(() => searchQuery = v),
                  ),
                ),
                const SizedBox(width: 10),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: "ALL", label: Text("ALL", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
                    ButtonSegment(value: "Pending", label: Text("PENDING", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
                    ButtonSegment(value: "Billed", label: Text("BILLED", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
                  ],
                  selected: {statusFilter},
                  onSelectionChanged: (v) => setState(() => statusFilter = v.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Expanded(
            child: list.isEmpty
                ? const Center(child: Text("No inward challans found matching filters.", style: TextStyle(color: Colors.white38)))
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (c, i) {
                      final ch = list[i];
                      bool isPending = ch.status == "Pending";

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: ListTile(
                          dense: true,
                          leading: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPending ? const Color(0x33D97706) : const Color(0x3310B981),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              ch.internalNo,
                              style: TextStyle(
                                color: isPending ? const Color(0xFFFBBF24) : Colors.greenAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(ch.distributorName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text(
                            "Supplier Ref: ${ch.billNo} • Date: ${WebAppDateLogic.format(ch.date)} • Status: ${ch.status}",
                            style: const TextStyle(color: Colors.white54, fontSize: 10.5),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "₹${ch.totalAmount.toStringAsFixed(2)}",
                                style: const TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                icon: const Icon(Icons.edit_note_rounded, size: 18, color: Color(0xFF38BDF8)),
                                tooltip: "Edit / Modify",
                                onPressed: ch.status == "Billed"
                                    ? null
                                    : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (ctx) => WebPurchaseChallanView(
                                              onBack: () => Navigator.pop(ctx),
                                              existingRecord: ch,
                                            ),
                                          ),
                                        );
                                      },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                tooltip: "Delete",
                                onPressed: () {
                                  webPh.deletePurchaseChallan(ch.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
