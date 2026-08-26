import 'package:flutter/material.dart';
import '../pharoah_web_manager.dart';

class WebInvoiceFeed extends StatelessWidget {
  final PharoahWebManager webPh;
  final Function(Map<String, dynamic> bill)? onViewBill;
  final Function(Map<String, dynamic> bill)? onPrintBill;

  const WebInvoiceFeed({
    super.key,
    required this.webPh,
    this.onViewBill,
    this.onPrintBill,
  });

  @override
  Widget build(BuildContext context) {
    final List<dynamic> salesList = webPh.sales.reversed.toList();
    final int displayCount = salesList.length > 10 ? 10 : salesList.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded, color: Colors.cyanAccent, size: 20),
              const SizedBox(width: 10),
              const Text(
                "LIVE STORE INVOICES FEED",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                "${salesList.length} Total Bills Recorded",
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 25),

          if (salesList.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(35),
                child: Text(
                  "No invoices recorded in this store database yet.",
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 750),
                child: Table(
                  columnWidths: const {
                    0: FixedColumnWidth(90),
                    1: FixedColumnWidth(120),
                    2: FlexColumnWidth(3),
                    3: FixedColumnWidth(110),
                    4: FixedColumnWidth(130),
                    5: FixedColumnWidth(130),
                  },
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.white10)),
                      ),
                      children: [
                        _th("TYPE"),
                        _th("BILL NO"),
                        _th("PARTY / CUSTOMER", isLeft: true),
                        _th("DATE"),
                        _th("AMOUNT"),
                        _th("ACTIONS"),
                      ],
                    ),
                    ...List.generate(displayCount, (index) {
                      final bill = salesList[index] as Map<String, dynamic>;
                      final String type = (bill['paymentMode'] ?? 'SALE').toString().toUpperCase();
                      final String billNo = (bill['billNo'] ?? 'N/A').toString();
                      final String party = (bill['partyName'] ?? 'CASH').toString();
                      final String date = (bill['date'] != null)
                          ? bill['date'].toString().substring(0, 10)
                          : '-';
                      final double amt = (bill['totalAmount'] as num? ?? 0).toDouble();

                      return TableRow(
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.white10)),
                        ),
                        children: [
                          _tdBadge(type),
                          _td(billNo, isBold: true),
                          _td(party, isLeft: true, isBold: true),
                          _td(date),
                          _td("₹${amt.toStringAsFixed(2)}", isBold: true, color: Colors.greenAccent),
                          _tdActions(bill, context),
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

  Widget _th(String text, {bool isLeft = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
    child: Text(
      text,
      textAlign: isLeft ? TextAlign.left : TextAlign.center,
      style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
    ),
  );

  Widget _td(String text, {bool isLeft = false, bool isBold = false, Color color = Colors.white}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    child: Text(
      text,
      textAlign: isLeft ? TextAlign.left : TextAlign.center,
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      ),
      overflow: TextOverflow.ellipsis,
    ),
  );

  Widget _tdBadge(String type) {
    Color bg = Colors.green.withOpacity(0.15);
    Color fg = Colors.greenAccent;

    if (type.contains("CREDIT")) {
      bg = Colors.blue.withOpacity(0.15);
      fg = Colors.blueAccent;
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Text(type, style: TextStyle(color: fg, fontSize: 9, fontWeight: FontWeight.w900)),
      ),
    );
  }

  Widget _tdActions(Map<String, dynamic> bill, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.visibility_outlined, size: 16, color: Colors.cyanAccent),
          tooltip: "View Bill",
          onPressed: () {
            if (onViewBill != null) {
              onViewBill!(bill);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Viewing Bill: ${bill['billNo'] ?? ''}")),
              );
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.print_outlined, size: 16, color: Colors.white70),
          tooltip: "Print PDF",
          onPressed: () {
            if (onPrintBill != null) {
              onPrintBill!(bill);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Printing Invoice: ${bill['billNo'] ?? ''}")),
              );
            }
          },
        ),
      ],
    );
  }
}
