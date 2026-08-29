// FILE: lib/web_live_sync/web_challan_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'web_models.dart';
import 'pharoah_web_manager.dart';
import 'sub_views/web_challans/web_sale_challan_view.dart';
import 'sub_views/web_challans/web_purchase_challan_view.dart';
import 'sub_views/web_challans/web_challan_to_bill_converter.dart';
import 'sub_views/web_challans/web_sale_challan_register.dart';
import 'sub_views/web_challans/web_purchase_challan_register.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                "DELIVERY CHALLANS & CONVERTER HUB",
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // 5-Tabs Switcher
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF0F766E),
              labelColor: const Color(0xFF2DD4BF),
              unselectedLabelColor: Colors.white54,
              isScrollable: true,
              tabs: const [
                Tab(text: "OUTWARD SALE CHALLAN", icon: Icon(Icons.local_shipping_rounded, size: 15)),
                Tab(text: "INWARD PUR CHALLAN", icon: Icon(Icons.inventory_2_rounded, size: 15)),
                Tab(text: "CHALLAN TO BILL CONVERTER", icon: Icon(Icons.merge_type_rounded, size: 15)),
                Tab(text: "SALE CHALLANS REGISTER", icon: Icon(Icons.format_list_bulleted_rounded, size: 15)),
                Tab(text: "PUR CHALLANS REGISTER", icon: Icon(Icons.history_edu_rounded, size: 15)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                WebSaleChallanView(onBack: widget.onBack),
                WebPurchaseChallanView(onBack: widget.onBack),
                WebChallanToBillConverter(onBack: widget.onBack),
                WebSaleChallanRegister(onBack: widget.onBack),
                WebPurchaseChallanRegister(onBack: widget.onBack),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
