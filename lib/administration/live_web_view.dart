import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../pharoah_manager.dart';
import '../web_live_sync/drive_sync_service.dart';

class LiveWebView extends StatefulWidget {
  const LiveWebView({super.key});

  @override
  State<LiveWebView> createState() => _LiveWebViewState();
}

class _LiveWebViewState extends State<LiveWebView> {
  bool isLiveWebActive = false;
  bool isGoogleConnected = false;
  String googleEmail = "";
  String lastSyncDisplay = "Never";
  bool isSyncing = false;
  bool isLoading = true;

  final String webPortalUrl = "https://pharoah-erp.pages.dev";

  @override
  void initState() {
    super.initState();
    _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    String syncTime = await DriveSyncService.getLastSyncTime();
    String savedEmail = prefs.getString('google_account_email') ?? "";

    setState(() {
      isLiveWebActive = prefs.getBool('is_live_web_active') ?? false;
      googleEmail = savedEmail;
      isGoogleConnected = savedEmail.isNotEmpty;
      lastSyncDisplay = syncTime;
      isLoading = false;
    });
  }

  Future<void> _openBrowserLogin(PharoahManager ph) async {
    final Uri authUri = Uri.parse("${DriveSyncService.defaultEndpoint}?action=AUTH_PAGE");
    if (await canLaunchUrl(authUri)) {
      await launchUrl(authUri, mode: LaunchMode.externalApplication);
      if (mounted) {
        _showAutoFetchDialog(ph);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open browser for authentication.")),
        );
      }
    }
  }

  void _showAutoFetchDialog(PharoahManager ph) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => StatefulBuilder(
        builder: (context, setDialogState) {
          bool fetching = false;
          String statusText = "Complete login in the browser, then tap below to fetch your verified Google ID.";

          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.cyanAccent)),
            title: const Row(
              children: [
                Icon(Icons.g_mobiledata_rounded, color: Colors.cyanAccent, size: 32),
                SizedBox(width: 8),
                Text("Google Verification", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(statusText, style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.4)),
                const SizedBox(height: 20),
                if (fetching)
                  const CircularProgressIndicator(color: Colors.cyanAccent),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c), child: const Text("CANCEL", style: TextStyle(color: Colors.white54))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
                onPressed: fetching ? null : () async {
                  setDialogState(() => fetching = true);
                  try {
                    final uri = Uri.parse("${DriveSyncService.defaultEndpoint}?action=GET_SESSION&t=${DateTime.now().millisecondsSinceEpoch}");
                    final response = await http.get(uri);

                    if (response.statusCode == 200) {
                      var res = jsonDecode(response.body);
                      if (res['status'] == "SUCCESS" && res['email'] != null) {
                        String fetchedEmail = res['email'];
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('google_account_email', fetchedEmail);
                        
                        setState(() {
                          googleEmail = fetchedEmail;
                          isGoogleConnected = true;
                        });

                        Navigator.pop(c);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("✅ Authenticated via Google: $fetchedEmail"), backgroundColor: Colors.green),
                        );
                        return;
                      }
                    }
                    setDialogState(() {
                      fetching = false;
                      statusText = "⚠️ Session not detected yet. Make sure you allowed access in the browser.";
                    });
                  } catch (e) {
                    setDialogState(() {
                      fetching = false;
                      statusText = "Error: $e";
                    });
                  }
                },
                child: const Text("FETCH GOOGLE ID", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _signOutGoogle() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('google_account_email');
    setState(() {
      googleEmail = "";
      isGoogleConnected = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Google Account Disconnected. Status: Not Logged In")),
      );
    }
  }

  Future<void> _toggleLiveWeb(bool value, PharoahManager ph) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_live_web_active', value);
    setState(() => isLiveWebActive = value);

    if (value && isGoogleConnected) {
      _runManualSync(ph);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? "🟢 Live Web Broadcast Activated!" : "🔴 Web Live Offline - 100% Local Storage"),
          backgroundColor: value ? Colors.teal.shade800 : Colors.blueGrey.shade900,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _runManualSync(PharoahManager ph) async {
    if (!isGoogleConnected) {
      _openBrowserLogin(ph);
      return;
    }

    setState(() => isSyncing = true);
    bool success = await DriveSyncService.pushDataToCloud(ph);
    String syncTime = await DriveSyncService.getLastSyncTime();

    if (mounted) {
      setState(() {
        isSyncing = false;
        lastSyncDisplay = syncTime;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? "✅ Data Synced to Google Drive successfully!" : "❌ Sync Failed. Check internet."),
          backgroundColor: success ? Colors.green.shade800 : Colors.red.shade900,
        ),
      );
    }
  }

  Future<void> _openInBrowser(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch browser.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ph = Provider.of<PharoahManager>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("Live Web & Google Drive Hub", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: const Color(0xFF1E1B4B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMasterSwitchCard(ph),
                  const SizedBox(height: 20),
                  _buildGoogleAuthCard(ph),
                  const SizedBox(height: 20),
                  if (isLiveWebActive) ...[
                    _buildActiveBroadcastCard(ph),
                    const SizedBox(height: 20),
                  ],
                  _buildSecurityGuideCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildMasterSwitchCard(PharoahManager ph) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isLiveWebActive ? Colors.cyanAccent : Colors.white10, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isLiveWebActive ? Colors.cyanAccent.withOpacity(0.1) : Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLiveWebActive ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
              color: isLiveWebActive ? Colors.cyanAccent : Colors.white38,
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "WEB LIVE BROADCASTER",
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  isLiveWebActive ? "Status: BROADCASTING ACTIVE" : "Status: 100% OFFLINE (Local)",
                  style: TextStyle(
                    color: isLiveWebActive ? Colors.greenAccent : Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isLiveWebActive,
            activeColor: Colors.cyanAccent,
            activeTrackColor: Colors.cyan.shade900,
            onChanged: (val) => _toggleLiveWeb(val, ph),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleAuthCard(PharoahManager ph) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isGoogleConnected ? Colors.greenAccent : Colors.orangeAccent, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.g_mobiledata_rounded, color: Colors.cyanAccent, size: 28),
              const SizedBox(width: 10),
              const Text("GOOGLE DRIVE ACCOUNT", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isGoogleConnected ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isGoogleConnected ? "SUCCESSFUL LOGIN" : "NOT LOGGED IN",
                  style: TextStyle(color: isGoogleConnected ? Colors.greenAccent : Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 25),

          if (isGoogleConnected) ...[
            const Text("Verified Google Account:", style: TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.verified, color: Colors.greenAccent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(googleEmail, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                ),
                TextButton(
                  onPressed: () => _openBrowserLogin(ph),
                  child: const Text("Re-login", style: TextStyle(color: Colors.cyanAccent, fontSize: 11)),
                ),
                TextButton(
                  onPressed: _signOutGoogle,
                  child: const Text("Disconnect", style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 5),
            const Text("📁 Target Folder: Google Drive > Pharoah_ERP_Cloud", style: TextStyle(color: Colors.cyanAccent, fontSize: 10)),
          ] else ...[
            const Text(
              "Status: Not Logged In. Authenticate securely via browser to link your store with Google Drive.",
              style: TextStyle(color: Colors.orangeAccent, fontSize: 11, height: 1.4, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                onPressed: () => _openBrowserLogin(ph),
                icon: const Icon(Icons.login_rounded, size: 20),
                label: const Text("SIGN IN WITH GOOGLE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveBroadcastCard(PharoahManager ph) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF115E59)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.sensors_rounded, color: Colors.greenAccent, size: 20),
                  SizedBox(width: 8),
                  Text("LIVE WEB ACCESS POINT", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ],
              ),
              if (isSyncing)
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent))
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(6)),
                  child: const Text("READY", style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const Divider(color: Colors.white24, height: 25),

          Text("Company: ${ph.activeCompany?.name ?? 'N/A'}", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          Text("Financial Year: ${ph.currentFY}", style: const TextStyle(color: Colors.white70, fontSize: 11)),
          Text("Last Cloud Sync: $lastSyncDisplay", style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 15),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(webPortalUrl, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, color: Colors.white70, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: webPortalUrl));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Web Link Copied!")));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () => _openInBrowser(webPortalUrl),
              icon: const Icon(Icons.open_in_browser_rounded, size: 20),
              label: const Text("OPEN IN CHROME / SAFARI", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
            ),
          ),
          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: (isSyncing || !isGoogleConnected) ? null : () => _runManualSync(ph),
              icon: const Icon(Icons.sync_rounded, size: 18),
              label: const Text("SYNC NOW TO GOOGLE DRIVE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityGuideCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security_rounded, color: Colors.cyanAccent, size: 18),
              SizedBox(width: 10),
              Text("AUTOMATIC EMAIL DETECTION", style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
          Divider(color: Colors.white10, height: 25),
          Text(
            "• Browser Auth: App opens browser to verify Google login automatically.\n• Auto-Fetch: App fetches your authenticated Gmail ID from Google Drive without manual typing.\n• Re-login / Disconnect: Fully manageable anytime.",
            style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }
}
