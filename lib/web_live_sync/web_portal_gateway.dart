// FILE: lib/web_live_sync/web_portal_gateway.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pharoah_web_manager.dart';
import 'components/web_top_bar.dart';
import 'components/web_recent_sidebar.dart';
import 'components/web_kpi_strip.dart';
import 'components/web_module_grid.dart';
import 'components/web_invoice_feed.dart';
import 'components/web_login_card.dart';

// Sub Views
import 'sub_views/web_billing/web_new_sale_view.dart';
import 'web_sale_summary_view.dart';
import 'web_purchase_entry_view.dart';
import 'web_challan_stitcher_wizard.dart';
import 'web_returns_view.dart';
import 'web_challan_view.dart';
import 'web_voucher_view.dart';
import 'web_product_master.dart';
import 'web_party_master.dart';
import 'web_batch_master.dart';
import 'web_aux_masters.dart';

class WebPortalGateway extends StatefulWidget {
  const WebPortalGateway({super.key});

  @override
  State<WebPortalGateway> createState() => _WebPortalGatewayState();
}

class _WebPortalGatewayState extends State<WebPortalGateway> {
  String currentView = "HOME";
  String currentViewTitle = "MAIN BUSINESS MODULES";
  String searchQuery = "";

  List<Map<String, dynamic>> recentShortcuts = [];

  void _navigateToHub(String hubId, String hubTitle) {
    setState(() {
      currentView = hubId;
      currentViewTitle = hubTitle;
    });
  }

  void _handleActionTap(String actionTitle, IconData icon, String navKey) {
    if (!recentShortcuts.any((item) => item['module'] == navKey)) {
      setState(() {
        recentShortcuts.insert(0, {
          "title": actionTitle,
          "icon": icon,
          "module": navKey,
        });
        if (recentShortcuts.length > 8) {
          recentShortcuts.removeLast();
        }
      });
    }

    _navigateToHub(navKey, actionTitle.toUpperCase());
  }

  void _removeShortcut(int index) {
    setState(() {
      recentShortcuts.removeAt(index);
    });
  }

  void _clearAllRecents() {
    setState(() {
      recentShortcuts.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final webPh = Provider.of<PharoahWebManager>(context);

    if (!webPh.isAuthenticated) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: WebLoginCard(
          errorMessage: webPh.errorMessage,
          isLoading: webPh.isLoading,
          onLogin: (token, user, pass) => webPh.loginWithStoreKey(
            storeToken: token,
            username: user,
            password: pass,
          ),
        ),
      );
    }

    bool isHomeDashboard = currentView == "HOME";

    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      appBar: WebTopBar(
        webPh: webPh,
        onSearchChanged: (v) => setState(() => searchQuery = v),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isHomeDashboard)
            WebRecentSidebar(
              currentView: currentView,
              recentShortcuts: recentShortcuts,
              onHomeTap: () => _navigateToHub("HOME", "MAIN BUSINESS MODULES"),
              onActionTap: _handleActionTap,
              onRemoveShortcut: _removeShortcut,
              onClearAll: _clearAllRecents,
            ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBreadcrumbs(),
                  const SizedBox(height: 16),
                  _buildCurrentView(webPh),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView(PharoahWebManager webPh) {
    // 1. SALES BILLING (NEW INVOICE)
    if (currentView == "GO_SALE") {
      return WebNewSaleView(
        onBack: () => _navigateToHub("HOME", "MAIN BUSINESS MODULES"),
      );
    }

    // 2. SALE REGISTER / HISTORY (CONNECTED!)
    if (currentView == "GO_SALE_REG") {
      return WebSaleSummaryView(
        onBack: () => _navigateToHub("HOME", "MAIN BUSINESS MODULES"),
      );
    }

    // 3. PURCHASE INWARD & PURCHASE REGISTER
    if (currentView == "GO_PURCHASE" || currentView == "GO_PUR_REG") {
      return WebPurchaseEntryView(
        onBack: () => _navigateToHub("HOME", "MAIN BUSINESS MODULES"),
      );
    }

    // 4. CHALLAN TO BILL STITCHER WIZARD
    if (currentView == "GO_STITCHER") {
      return WebChallanStitcherWizard(
        onBack: () => _navigateToHub("HOME", "MAIN BUSINESS MODULES"),
      );
    }

    // 5. RETURNS & REVERSALS (CN / DN / REGISTER)
    if (currentView == "GO_CN" || currentView == "GO_DN" || currentView == "GO_BREAKAGE" || currentView == "GO_RET_REG" || currentView == "RETURNS") {
      int tabIdx = 0;
      if (currentView == "GO_DN") tabIdx = 1;
      if (currentView == "GO_RET_REG") tabIdx = 2;

      return WebReturnsView(
        onBack: () => _navigateToHub("HOME", "MAIN BUSINESS MODULES"),
        initialTabIndex: tabIdx,
      );
    }

    // 6. DELIVERY & INWARD CHALLANS
    if (currentView == "GO_CHALLAN_SALE" || currentView == "GO_CHALLAN_PUR" || currentView == "GO_CHALLAN_SALE_REG" || currentView == "GO_CHALLAN_PUR_REG" || currentView == "CHALLANS") {
      int tabIdx = 0;
      if (currentView == "GO_CHALLAN_PUR" || currentView == "GO_CHALLAN_PUR_REG") tabIdx = 1;

      return WebChallanView(
        onBack: () => _navigateToHub("HOME", "MAIN BUSINESS MODULES"),
        initialTabIndex: tabIdx,
      );
    }

    // 7. ACCOUNTS, DAYBOOK & VOUCHERS
    if (currentView == "GO_RECEIPT" || currentView == "GO_PAYMENT" || currentView == "GO_DAYBOOK" || currentView == "GO_LEDGERS" || currentView == "ACCOUNTS") {
      int tabIdx = 0;
      if (currentView == "GO_PAYMENT") tabIdx = 1;
      if (currentView == "GO_DAYBOOK" || currentView == "GO_LEDGERS") tabIdx = 2;

      return WebVoucherView(
        onBack: () => _navigateToHub("HOME", "MAIN BUSINESS MODULES"),
        initialTabIndex: tabIdx,
      );
    }

    // 8. PRODUCT / ITEM MASTER
    if (currentView == "GO_M_ITEM" || currentView == "GO_STOCK" || currentView == "GO_SHORTAGE" || currentView == "INVENTORY") {
      return WebProductMasterView(
        onBack: () => _navigateToHub("HOME", "MAIN BUSINESS MODULES"),
      );
    }

    // 9. PARTY & CUSTOMER MASTER
    if (currentView == "GO_M_PARTY") {
      return WebPartyMasterView(
        onBack: () => _navigateToHub("HOME", "MAIN BUSINESS MODULES"),
      );
    }

    // 10. CENTRAL BATCH MASTER
    if (currentView == "GO_M_BATCH") {
      return WebBatchMasterView(
        onBack: () => _navigateToHub("HOME", "MAIN BUSINESS MODULES"),
      );
    }

    // 11. AUXILIARY MASTERS (COMPANIES, SALTS, ROUTES)
    if (currentView == "GO_M_COMP" || currentView == "GO_M_SALT" || currentView == "GO_M_ROUTE") {
      int tabIdx = 0;
      if (currentView == "GO_M_SALT") tabIdx = 1;
      if (currentView == "GO_M_ROUTE") tabIdx = 2;

      return WebAuxMastersView(
        onBack: () => _navigateToHub("HOME", "MAIN BUSINESS MODULES"),
        initialTabIndex: tabIdx,
      );
    }

    // DEFAULT: DASHBOARD LEVEL 0 / LEVEL 1 HUBS GRID
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WebKpiStrip(webPh: webPh),
        const SizedBox(height: 20),
        WebModuleGrid(
          currentView: currentView,
          onHubTap: _navigateToHub,
          onActionTap: _handleActionTap,
          onBackToHome: () => _navigateToHub("HOME", "MAIN BUSINESS MODULES"),
        ),
        const SizedBox(height: 25),
        if (currentView == "HOME")
          WebInvoiceFeed(
            webPh: webPh,
          ),
      ],
    );
  }

  Widget _buildBreadcrumbs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => _navigateToHub("HOME", "MAIN BUSINESS MODULES"),
            child: const Row(
              children: [
                Icon(Icons.home_rounded, color: Color(0xFF38BDF8), size: 15),
                SizedBox(width: 6),
                Text("Home", style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (currentView != "HOME") ...[
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 15),
            const SizedBox(width: 8),
            Text(currentViewTitle, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
          ],
          const Spacer(),
          if (currentView != "HOME")
            InkWell(
              onTap: () => _navigateToHub("HOME", "MAIN BUSINESS MODULES"),
              child: const Row(
                children: [
                  Icon(Icons.arrow_back_rounded, color: Colors.white54, size: 14),
                  SizedBox(width: 4),
                  Text("Back to Hubs", style: TextStyle(color: Colors.white54, fontSize: 10.5, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
