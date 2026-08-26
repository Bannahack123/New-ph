import 'package:flutter/material.dart';
import '../pharoah_web_manager.dart';

class WebKpiStrip extends StatelessWidget {
  final PharoahWebManager webPh;

  const WebKpiStrip({super.key, required this.webPh});

  @override
  Widget build(BuildContext context) {
    // Today calculations
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

    // Estimated Stock Valuation
    double totalStockVal = 0.0;
    for (var m in webPh.medicines) {
      double stock = (m['stock'] as num? ?? 0).toDouble();
      double purRate = (m['purRate'] as num? ?? (m['rate'] as num? ?? 0)).toDouble();
      totalStockVal += (stock * purRate);
    }

    // Outstanding Balances
    double totalOutstanding = 0.0;
    int debtorsCount = 0;
    for (var p in webPh.parties) {
      double bal = (p['opBal'] as num? ?? 0).toDouble();
      if (bal > 0) {
        totalOutstanding += bal;
        debtorsCount++;
      }
    }

    // Dynamic Display formatters
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
        ? "$todayPurCount Inward Today" 
        : "${webPh.purchases.length} Total Inwards";

    String stockDisplay = totalStockVal > 0 
        ? "₹${totalStockVal.toStringAsFixed(0)}" 
        : "${webPh.medicines.length} Items";
    String stockSub = "${webPh.medicines.length} Catalog Products";

    String outDisplay = totalOutstanding > 0 
        ? "₹${totalOutstanding.toStringAsFixed(0)}" 
        : "${webPh.parties.length} Parties";
    String outSub = "$debtorsCount Active Debtors";

    return Row(
      children: [
        Expanded(child: _kpiCard("TODAY SALES", salesDisplay, salesSub, Icons.trending_up_rounded, Colors.greenAccent)),
        const SizedBox(width: 14),
        Expanded(child: _kpiCard("TODAY PURCHASES", purDisplay, purSub, Icons.shopping_cart_rounded, Colors.orangeAccent)),
        const SizedBox(width: 14),
        Expanded(child: _kpiCard("STOCK VALUATION", stockDisplay, stockSub, Icons.inventory_2_rounded, Colors.cyanAccent)),
        const SizedBox(width: 14),
        Expanded(child: _kpiCard("MARKET OUTSTANDING", outDisplay, outSub, Icons.account_balance_wallet_rounded, Colors.purpleAccent)),
      ],
    );
  }

  double _totalSales(PharoahWebManager ph) {
    return ph.sales.fold(0.0, (sum, s) => sum + (s['totalAmount'] as num? ?? 0).toDouble());
  }

  double _totalPur(PharoahWebManager ph) {
    return ph.purchases.fold(0.0, (sum, p) => sum + (p['totalAmount'] as num? ?? 0).toDouble());
  }

  Widget _kpiCard(String title, String value, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(color: Colors.white38, fontSize: 9),
          ),
        ],
      ),
    );
  }
}
