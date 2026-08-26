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

  List<Map<String, dynamic>> recentShortcuts = [];

  void _navigateToHub(String hubId, String hubTitle) {
    setState(() {
      currentView = hubId;
      currentViewTitle = hubTitle;
    });
  }

  void _handleActionTap(String actionTitle, IconData icon, String navKey) {
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

    // Auto-Logging in Splash on Page Reload
    if (webPh.isAutoLoggingIn || webPh.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.cyanAccent),
              SizedBox(height: 25),
              Text(
                "Connecting to Store Cloud Workstation...",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // State 1: Unauthenticated -> Show Login Form (with Auto-Remembered Key)
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
      backgroundColor: const Color(0xFF0B132B),
      appBar: WebTopBar(
        webPh: webPh,
        onSearchChanged: (v) => setState(() => searchQuery = v),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      onViewBill: (bill) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Viewing Invoice: ${bill['billNo'] ?? ''}")),
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
            child: Row(
              children: const [
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
              child: Row(
                children: const [
                  Icon(Icons.arrow_back_rounded, color: Colors.white54, size: 14),
                  SizedBox(width: 4),
                  Text("Back", style: TextStyle(color: Colors.white54, fontSize: 10.5, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
