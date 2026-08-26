import 'package:flutter/material.dart';
import '../pharoah_web_manager.dart';

class WebKpiStrip extends StatelessWidget {
  final PharoahWebManager webPh;

  const WebKpiStrip({super.key, required this.webPh});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    double todaySales = 0.0;
    int todaySalesCount = 0;
    for (var s in webPh.sales) {
      String sDate = (s['date'] ?? '').toString();
      if (sDate.startsWith(todayStr) || sDate.contains(todayStr)) {
        todaySales += (s['totalAmount'] as num? ?? 0).toDouble();
        todaySalesCount++;
      }
    }

    double todayPurchases = 0.0;
    int todayPurCount = 0;
    for (var p in webPh.purchases) {
      String pDate = (p['date'] ?? '').toString();
      if (pDate.startsWith(todayStr) || pDate.contains(todayStr)) {
        todayPurchases += (p['totalAmount'] as num? ?? 0).toDouble();
        todayPurCount++;
      }
    }

    double totalStockVal = 0.0;
    for (var m in webPh.medicines) {
      double stock = (m['stock'] as num? ?? 0).toDouble();
      double purRate = (m['purRate'] as num? ?? (m['rate'] as num? ?? 0)).toDouble();
      totalStockVal += (stock * purRate);
    }

    double totalOutstanding = 0.0;
    int debtorsCount = 0;
    for (var p in webPh.parties) {
      double bal = (p['opBal'] as num? ?? 0).toDouble();
      if (bal > 0) {
        totalOutstanding += bal;
        debtorsCount++;
      }
    }

    String salesDisplay = todaySales > 0 
        ? "₹${todaySales.toStringAsFixed(0)}" 
        : (webPh.sales.isNotEmpty ? "₹${_totalSales(webPh).toStringAsFixed(0)}" : "₹0");
    String salesSub = todaySalesCount > 0 
        ? "$todaySalesCount Bills Today" 
        : "${webPh.sales.length} Total Bills";

    String purDisplay = todayPurchases > 0 
        ? "₹${todayPurchases.toStringAsFixed(0)}" 
        : (webPh.purchases.isNotEmpty ? "₹${_totalPur(webPh).toStringAsFixed(0)}" : "₹0");
    String purSub = todayPurCount > 0 
        ? "$todayPurCount Inwards Today" 
        : "${webPh.purchases.length} Total Inwards";

    String stockDisplay = totalStockVal > 0 
        ? "₹${totalStockVal.toStringAsFixed(0)}" 
        : "${webPh.medicines.length} Items";
    String stockSub = "${webPh.medicines.length} Catalog Items";

    String outDisplay = totalOutstanding > 0 
        ? "₹${totalOutstanding.toStringAsFixed(0)}" 
        : "${webPh.parties.length} Parties";
    String outSub = "$debtorsCount Debtors";

    return Row(
      children: [
        Expanded(child: _kpiCard("TODAY SALES", salesDisplay, salesSub, Icons.trending_up_rounded, Colors.greenAccent)),
        const SizedBox(width: 12),
        Expanded(child: _kpiCard("TODAY PURCHASES", purDisplay, purSub, Icons.shopping_cart_rounded, Colors.orangeAccent)),
        const SizedBox(width: 12),
        Expanded(child: _kpiCard("STOCK VALUATION", stockDisplay, stockSub, Icons.inventory_2_rounded, const Color(0xFF38BDF8))),
        const SizedBox(width: 12),
        Expanded(child: _kpiCard("OUTSTANDING", outDisplay, outSub, Icons.account_balance_wallet_rounded, const Color(0xFFA78BFA))),
      ],
    );
  }

  double _totalSales(PharoahWebManager ph) => ph.sales.fold(0.0, (sum, s) => sum + (s['totalAmount'] as num? ?? 0).toDouble());
  double _totalPur(PharoahWebManager ph) => ph.purchases.fold(0.0, (sum, p) => sum + (p['totalAmount'] as num? ?? 0).toDouble());

  Widget _kpiCard(String title, String value, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white54, fontSize: 8.5, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 8.5)),
        ],
      ),
    );
  }
}
