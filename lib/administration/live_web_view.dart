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
  String googleEmail = "";
  bool isGoogleConnected = false;
  String lastSyncDisplay = "Never";
  bool isSyncing = false;
  bool isLoading = true;

  // Cloudflare Web Portal Target URL
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

  // Google Login / Account Connect Dialog
  void _showGoogleSignInDialog(PharoahManager ph) {
    final emailController = TextEditingController(text: googleEmail.isNotEmpty ? googleEmail : "");
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.cyanAccent)),
        title: const Row(
          children: [
            Icon(Icons.account_circle, color: Colors.cyanAccent, size: 28),
            SizedBox(width: 10),
            Text("Google Drive Sign-In", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter the Gmail account linked to your Google Drive to enable cloud backup & live web access.",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: "Your Gmail Address",
                labelStyle: const TextStyle(color: Colors.white54),
                hintText: "example@gmail.com",
                hintStyle: const TextStyle(color: Colors.white24),
                prefixIcon: const Icon(Icons.email_outlined, color: Colors.cyanAccent),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("CANCEL", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              String entered = emailController.text.trim();
              if (entered.isNotEmpty && entered.contains("@")) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('google_account_email', entered);
                setState(() {
                  googleEmail = entered;
                  isGoogleConnected = true;
                });
                Navigator.pop(c);
                // Instant Sync on login
                _runManualSync(ph);
              }
            },
            icon: const Icon(Icons.login_rounded),
            label: const Text("CONNECT ACCOUNT", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _disconnectGoogle() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('google_account_email');
    setState(() {
      googleEmail = "";
      isGoogleConnected = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Google Account Disconnected.")),
      );
    }
  }

  Future<void> _toggleLiveWeb(bool value, PharoahManager ph) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_live_web_active', value);
    setState(() {
      isLiveWebActive = value;
    });

    if (value && isGoogleConnected) {
      _runManualSync(ph);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? "🟢 Live Web Broadcaster Activated!" : "🔴 Web Live Offline - 100% Local Storage"),
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
          content: Text(success ? "✅ Synced to Google Drive successfully!" : "❌ Sync Failed. Check internet."),
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
          const SnackBar(content: Text("Could not launch browser. Check connection.")),
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
                  // 1. MASTER TOGGLE SWITCH CARD
                  _buildMasterSwitchCard(ph),
                  const SizedBox(height: 20),

                  // 2. JAB SWITCH ON HO: GOOGLE AUTH & DRIVE CARD
                  if (isLiveWebActive) ...[
                    _buildGoogleAuthCard(ph),
                    const SizedBox(height: 20),
                    _buildActiveBroadcastCard(ph),
                    const SizedBox(height: 20),
                  ],

                  // 3. SECURITY & PRIVACY CARD
                  _buildSecurityGuideCard(),
                ],
              ),
            ),
    );
  }

  // SWITCH CARD
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

  // 🛡️ NAYA: GOOGLE AUTHENTICATION & DRIVE CONNECTION CARD
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
              Image.network(
                "https://cdn-icons-png.flaticon.com/512/2991/2991148.png", // Google Icon
                width: 22, height: 22,
                errorBuilder: (c, o, s) => const Icon(Icons.account_circle, color: Colors.cyanAccent, size: 22),
              ),
              const SizedBox(width: 10),
              const Text("GOOGLE DRIVE ACCOUNT", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isGoogleConnected ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isGoogleConnected ? "LINKED" : "NOT LINKED",
                  style: TextStyle(color: isGoogleConnected ? Colors.greenAccent : Colors.orangeAccent, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 25),

          if (isGoogleConnected) ...[
            Text("Connected Account:", style: const TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.verified, color: Colors.greenAccent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(googleEmail, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                ),
                TextButton(
                  onPressed: _disconnectGoogle,
                  child: const Text("Disconnect", style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 5),
            const Text("📁 Target Folder: Google Drive > Pharoah_ERP_Cloud", style: TextStyle(color: Colors.cyanAccent, fontSize: 10)),
          ] else ...[
            const Text(
              "Sign in with your Google account to automatically create and sync the cloud database folder on your Drive.",
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showGoogleSignInDialog(ph),
                icon: const Icon(Icons.login, color: Colors.blueAccent, size: 20),
                label: const Text("SIGN IN WITH GOOGLE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ACTIVE BROADCAST & OPEN IN BROWSER CARD
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

          // Link Box
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

          // 🚀 DIRECT OPEN IN BROWSER BUTTON
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

          // SYNC BUTTON
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
              Text("PRIVACY & DATA ISOLATION", style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
          Divider(color: Colors.white10, height: 25),
          Text(
            "• Switch OFF: App 100% offline rahegi, koi bhi data cloud par nahi jayega.\n• Switch ON: Data sirf aapki linked Google Drive me sync hoga.\n• Nayi company sirf Mobile App se banegi, web station sirf authorized mirror rahega.",
            style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
