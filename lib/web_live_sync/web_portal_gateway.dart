import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pharoah_web_manager.dart';
import 'components/web_top_bar.dart';
import 'components/web_recent_sidebar.dart';
import 'components/web_kpi_strip.dart';
import 'components/web_module_grid.dart';
import 'components/web_invoice_feed.dart';
import 'components/web_login_card.dart';

class WebPortalGateway extends StatefulWidget {
  const WebPortalGateway({super.key});

  @override
  State<WebPortalGateway> createState() => _WebPortalGatewayState();
}

class _WebPortalGatewayState extends State<WebPortalGateway> {
  String currentView = "HOME";
  String currentViewTitle = "MAIN BUSINESS MODULES";
  String searchQuery = "";

  // Dynamic Recent Shortcuts List
  List<Map<String, dynamic>> recentShortcuts = [];

  void _navigateToHub(String hubId, String hubTitle) {
    setState(() {
      currentView = hubId;
      currentViewTitle = hubTitle;
    });
  }

  void _handleActionTap(String actionTitle, IconData icon, String navKey) {
    // Auto-add to Dynamic Recent Shortcuts
    if (!recentShortcuts.any((item) => item['title'] == actionTitle)) {
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("🚀 Opening: $actionTitle"),
        backgroundColor: const Color(0xFF0F766E),
        duration: const Duration(seconds: 2),
      ),
    );
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

    // State 1: Unauthenticated -> Show Isolated Login Form
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

    // State 2: Authenticated -> Master Assembly Shell
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: WebTopBar(
        webPh: webPh,
        onSearchChanged: (v) => setState(() => searchQuery = v),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Dynamic Recent Shortcuts Sidebar
          WebRecentSidebar(
            currentView: currentView,
            recentShortcuts: recentShortcuts,
            onHomeTap: () => _navigateToHub("HOME", "MAIN BUSINESS MODULES"),
            onActionTap: _handleActionTap,
            onRemoveShortcut: _removeShortcut,
            onClearAll: _clearAllRecents,
          ),

          // 2. Main Workspace
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Breadcrumbs & Back Navigation
                  _buildBreadcrumbs(),
                  const SizedBox(height: 20),

                  // 4-Card Live KPI Strip
                  WebKpiStrip(webPh: webPh),
                  const SizedBox(height: 25),

                  // Level 0 / Level 1 Module Grid
                  WebModuleGrid(
                    currentView: currentView,
                    onHubTap: _navigateToHub,
                    onActionTap: _handleActionTap,
                  ),
                  const SizedBox(height: 30),

                  // Live Invoices Feed Table (Only on Home View)
                  if (currentView == "HOME")
                    WebInvoiceFeed(
                      webPh: webPh,
                      onViewBill: (bill) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Viewing Bill: ${bill['billNo'] ?? ''}")),
                        );
                      },
                      onPrintBill: (bill) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Printing Invoice: ${bill['billNo'] ?? ''}")),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs() {
    return Row(
      children: [
        InkWell(
          onTap: () => _navigateToHub("HOME", "MAIN BUSINESS MODULES"),
          child: const Text("Home",
              style: TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        if (currentView != "HOME") ...[
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 16),
          const SizedBox(width: 6),
          Text(currentViewTitle,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
        const Spacer(),
        if (currentView != "HOME")
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
            onPressed: () => _navigateToHub("HOME", "MAIN BUSINESS MODULES"),
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text("Back to All Modules", style: TextStyle(fontSize: 11)),
          ),
      ],
    );
  }
}
