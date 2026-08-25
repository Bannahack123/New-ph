import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../pharoah_manager.dart';
import '../web_live_sync/drive_sync_service.dart';

class LiveWebView extends StatefulWidget {
  const LiveWebView({super.key});

  @override
  State<LiveWebView> createState() => _LiveWebViewState();
}

class _LiveWebViewState extends State<LiveWebView> {
  bool isLiveWebActive = false;
  String lastSyncDisplay = "Loading...";
  bool isSyncing = false;
  bool isLoading = true;

  // Cloudflare Web Portal Target (Jab banega toh direct yahi khulega)
  final String webPortalUrl = "https://pharoah-erp.pages.dev"; 

  @override
  void initState() {
    super.initState();
    _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    String syncTime = await DriveSyncService.getLastSyncTime();
    setState(() {
      isLiveWebActive = prefs.getBool('is_live_web_active') ?? false;
      lastSyncDisplay = syncTime;
      isLoading = false;
    });
  }

  Future<void> _toggleLiveWeb(bool value, PharoahManager ph) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_live_web_active', value);
    setState(() {
      isLiveWebActive = value;
    });

    if (value) {
      // Switch ON hote hi automatic cloud sync trigger karein
      _runManualSync(ph);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? "🟢 Live Web Broadcast Activated!" : "🔴 Web Live Offline - All data is 100% Local"),
          backgroundColor: value ? Colors.teal.shade800 : Colors.blueGrey.shade900,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _runManualSync(PharoahManager ph) async {
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
          content: Text(success ? "✅ Data Synced to Google Drive Successfully!" : "❌ Sync Failed. Check Internet Connection."),
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
          const SnackBar(content: Text("Could not launch browser. Please check connection.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ph = Provider.of<PharoahManager>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark Slate Background
      appBar: AppBar(
        title: const Text("Live Web & Cloud Hub", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
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
                  // --- 1. MASTER TOGGLE SWITCH ---
                  _buildMasterSwitchCard(ph),
                  const SizedBox(height: 25),

                  // --- 2. JAB SWITCH ON HO TABHI YE SECTION DIKHEGA ---
                  if (isLiveWebActive) ...[
                    _buildActiveBroadcastCard(ph),
                    const SizedBox(height: 25),
                  ],

                  // --- 3. INFORMATION & SECURITY RULES ---
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
        boxShadow: [
          BoxShadow(
            color: isLiveWebActive ? Colors.cyanAccent.withOpacity(0.15) : Colors.black26,
            blurRadius: 15,
            offset: const Offset(0, 6),
          )
        ],
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
                  isLiveWebActive ? "Status: BROADCASTING TO CLOUD" : "Status: 100% OFFLINE (Local)",
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

          Text("Target Company: ${ph.activeCompany?.name ?? 'N/A'}", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          Text("Financial Year: ${ph.currentFY}", style: const TextStyle(color: Colors.white70, fontSize: 11)),
          Text("Last Cloud Sync: $lastSyncDisplay", style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 15),

          // Link Display Card
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

          // 🔥 USER REQUIREMENT: DIRECT OPEN IN BROWSER / CHROME BUTTON
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

          // MANUAL SYNC BUTTON
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isSyncing ? null : () => _runManualSync(ph),
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
              Text("DATA PRIVACY & RULES", style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
          Divider(color: Colors.white10, height: 25),
          Text(
            "• Switch OFF: App 100% offline rahegi, koi bhi data internet par nahi jayega.\n• Switch ON: Data aapki apni Google Drive me encrypted folder me sync hoga.\n• Website se koi nayi company create nahi ho sakti, company sirf Mobile App se create hogi.",
            style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
