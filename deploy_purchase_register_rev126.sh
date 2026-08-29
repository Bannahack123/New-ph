#!/bin/bash

export PATH="$HOME/flutter/bin:$PATH"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}   🚀 DEPLOYING PURCHASE REGISTER (#PH-REV-126)   ${NC}"
echo -e "${BLUE}====================================================${NC}\n"

# 1. Update Top Bar Badge to #PH-REV-126
echo -e "${YELLOW}[1/4] Updating Top Bar Badge to #PH-REV-126...${NC}"
cat << 'TOPBAR_EOF' > lib/web_live_sync/components/web_top_bar.dart
// FILE: lib/web_live_sync/components/web_top_bar.dart

import 'package:flutter/material.dart';
import '../pharoah_web_manager.dart';

class WebTopBar extends StatelessWidget implements PreferredSizeWidget {
  final PharoahWebManager webPh;
  final ValueChanged<String>? onSearchChanged;

  const WebTopBar({
    super.key,
    required this.webPh,
    this.onSearchChanged,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
              color: Color(0x332563EB),
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: const Icon(Icons.storefront_rounded, color: Color(0xFF38BDF8), size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                webPh.companyName.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              Row(
                children: [
                  Text(
                    "FY: ${webPh.financialYear}",
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: Color(0xFF38BDF8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0x2610B981),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.greenAccent, width: 0.5),
                    ),
                    child: const Text(
                      "#PH-REV-126",
                      style: TextStyle(color: Colors.greenAccent, fontSize: 8, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Container(
              height: 36,
              constraints: const BoxConstraints(maxWidth: 380),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: TextField(
                onChanged: onSearchChanged,
                style: const TextStyle(color: Colors.white, fontSize: 11.5),
                decoration: const InputDecoration(
                  hintText: "Search Medicines, Customers, Invoices...",
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 11),
                  prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF38BDF8), size: 16),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 9),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0x1F10B981),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x4D10B981)),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, color: Colors.greenAccent, size: 7),
                SizedBox(width: 6),
                Text(
                  "LIVE CLOUD",
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: Colors.white70, size: 20),
            tooltip: "Refresh Live Data",
            onPressed: () {
              webPh.refreshStoreData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("🔄 Live Cloud Database Refreshed!"),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
            tooltip: "Sign Out",
            onPressed: () => _confirmSignOut(context, webPh),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, PharoahWebManager webPh) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Colors.white10),
        ),
        title: const Text("Sign Out Workstation?", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text(
          "Are you sure you want to disconnect from this store workstation?",
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("CANCEL", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(c);
              webPh.signOut();
            },
            child: const Text("SIGN OUT", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
TOPBAR_EOF

# 2. Update web_portal_gateway.dart to route GO_PUR_REG to WebPurchaseSummaryView
echo -e "${YELLOW}[2/4] Linking GO_PUR_REG in Web Gateway...${NC}"
cat << 'GATEWAY_EOF' > lib/web_live_sync/web_portal_gateway.dart
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
import 'web_purchase_summary_view.dart';
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

    // 2. SALE REGISTER / HISTORY
    if (currentView == "GO_SALE_REG") {
      return WebSaleSummaryView(
        onBack: () => _navigateToHub("HOME", "MAIN BUSINESS MODULES"),
      );
    }

    // 3. PURCHASE INWARD ENTRY
    if (currentView == "GO_PURCHASE") {
      return WebPurchaseEntryView(
        onBack: () => _navigateToHub("HOME", "MAIN BUSINESS MODULES"),
      );
    }

    // 4. PURCHASE REGISTER / AUDIT (CONNECTED!)
    if (currentView == "GO_PUR_REG") {
      return WebPurchaseSummaryView(
        onBack: () => _navigateToHub("HOME", "MAIN BUSINESS MODULES"),
      );
    }

    // 5. CHALLAN TO BILL STITCHER WIZARD
    if (currentView == "GO_STITCHER") {
      return WebChallanStitcherWizard(
        onBack: () => _navigateToHub("HOME", "MAIN BUSINESS MODULES"),
      );
    }

    // 6. RETURNS & REVERSALS (CN / DN / REGISTER)
    if (currentView == "GO_CN" || currentView == "GO_DN" || currentView == "GO_BREAKAGE" || currentView == "GO_RET_REG" || currentView == "RETURNS") {
      int tabIdx = 0;
      if (currentView == "GO_DN") tabIdx = 1;
      if (currentView == "GO_RET_REG") tabIdx = 2;

      return WebReturnsView(
        onBack: () => _navigateToHub("HOME", "MAIN BUSINESS MODULES"),
        initialTabIndex: tabIdx,
      );
    }

    // 7. DELIVERY & INWARD CHALLANS
    if (currentView == "GO_CHALLAN_SALE" || currentView == "GO_CHALLAN_PUR" || currentView == "GO_CHALLAN_SALE_REG" || currentView == "GO_CHALLAN_PUR_REG" || currentView == "CHALLANS") {
      int tabIdx = 0;
      if (currentView == "GO_CHALLAN_PUR" || currentView == "GO_CHALLAN_PUR_REG") tabIdx = 1;

      return WebChallanView(
        onBack: () => _navigateToHub("HOME", "MAIN BUSINESS MODULES"),
        initialTabIndex: tabIdx,
      );
    }

    // 8. ACCOUNTS, DAYBOOK & VOUCHERS
    if (currentView == "GO_RECEIPT" || currentView == "GO_PAYMENT" || currentView == "GO_DAYBOOK" || currentView == "GO_LEDGERS" || currentView == "ACCOUNTS") {
      int tabIdx = 0;
      if (currentView == "GO_PAYMENT") tabIdx = 1;
      if (currentView == "GO_DAYBOOK" || currentView == "GO_LEDGERS") tabIdx = 2;

      return WebVoucherView(
        onBack: () => _navigateToHub("HOME", "MAIN BUSINESS MODULES"),
        initialTabIndex: tabIdx,
      );
    }

    // 9. PRODUCT / ITEM MASTER
    if (currentView == "GO_M_ITEM" || currentView == "GO_STOCK" || currentView == "GO_SHORTAGE" || currentView == "INVENTORY") {
      return WebProductMasterView(
        onBack: () => _navigateToHub("HOME", "MAIN BUSINESS MODULES"),
      );
    }

    // 10. PARTY & CUSTOMER MASTER
    if (currentView == "GO_M_PARTY") {
      return WebPartyMasterView(
        onBack: () => _navigateToHub("HOME", "MAIN BUSINESS MODULES"),
      );
    }

    // 11. CENTRAL BATCH MASTER
    if (currentView == "GO_M_BATCH") {
      return WebBatchMasterView(
        onBack: () => _navigateToHub("HOME", "MAIN BUSINESS MODULES"),
      );
    }

    // 12. AUXILIARY MASTERS (COMPANIES, SALTS, ROUTES)
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
GATEWAY_EOF

# 3. Flush RAM and compile web bundle
echo -e "${YELLOW}[3/4] Flushing RAM & Compiling Web Bundle...${NC}"
pkill -f "analysis_server" 2>/dev/null || true
pkill -f "dart_language_server" 2>/dev/null || true
sync
echo 3 | sudo tee /proc/sys/vm/drop_caches 2>/dev/null || true

flutter build web -t lib/web_live_sync/web_main.dart --release --base-href "/" --pwa-strategy=none --no-tree-shake-icons --dart2js-optimization=O1

if [ ! -f "build/web/main.dart.js" ]; then
    echo -e "${RED}✖ Build failed.${NC}"
    exit 1
fi
echo -e "  ${GREEN}✔ Web compilation successful!${NC}\n"

# 4. Upload to Cloudflare Pages and Git Push
echo -e "${YELLOW}[4/4] Uploading to Cloudflare Pages & Syncing Git...${NC}"
npx wrangler pages deploy build/web --project-name=pharoah-erp --commit-dirty=true

git add .
git commit -m "Deploy Live Revision #PH-REV-126 with Dedicated Purchase Register" || true
git push origin main || true

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${GREEN}  🎉 DEPLOYED SUCCESSFULLY: #PH-REV-126 LIVE!${NC}"
echo -e "${BLUE}====================================================${NC}"
