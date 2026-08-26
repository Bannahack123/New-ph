import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  bool isGoogleConnected = false;
  String googleEmail = "";
  String lastSyncDisplay = "Never";
  bool isSyncing = false;
  bool isLoading = true;

  // Cloudflare Web Portal Live URL
  final String webPortalUrl = "https://pharoah-erp.pages.dev";

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile', 'https://www.googleapis.com/auth/drive.file'],
  );

  @override
  void initState() {
    super.initState();
    _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    String syncTime = await DriveSyncService.getLastSyncTime();
    String savedEmail = prefs.getString('google_account_email') ?? "";
    
    // Check if google sign in is already active
    var currentUser = _googleSignIn.currentUser;
    if (currentUser != null && savedEmail.isEmpty) {
      savedEmail = currentUser.email;
      await prefs.setString('google_account_email', savedEmail);
    }

    setState(() {
      isLiveWebActive = prefs.getBool('is_live_web_active') ?? false;
      googleEmail = savedEmail;
      isGoogleConnected = savedEmail.isNotEmpty || currentUser != null;
      lastSyncDisplay = syncTime;
      isLoading = false;
    });
  }

  // REAL GOOGLE OAUTH POPUP LOGIN
  Future<void> _signInWithGoogle(PharoahManager ph) async {
    setState(() => isLoading = true);
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('google_account_email', account.email);
        setState(() {
          googleEmail = account.email;
          isGoogleConnected = true;
          isLoading = false;
        });

        // Auto push initial data to Google Drive upon successful login
        if (isLiveWebActive) {
          _runManualSync(ph);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("✅ Connected with Google: ${account.email}"), backgroundColor: Colors.green.shade800),
          );
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Google Sign-In Error: $e"), backgroundColor: Colors.red.shade900),
        );
      }
    }
  }

  Future<void> _signOutGoogle() async {
    await _googleSignIn.signOut();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please connect with Google first!"), backgroundColor: Colors.orange),
      );
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
                  // 1. MASTER TOGGLE SWITCH
                  _buildMasterSwitchCard(ph),
                  const SizedBox(height: 20),

                  // 2. GOOGLE AUTH & DRIVE LINKING CARD
                  _buildGoogleAuthCard(ph),
                  const SizedBox(height: 20),

                  // 3. JAB SWITCH ON HO: WEB ACCESS POINT
                  if (isLiveWebActive) ...[
                    _buildActiveBroadcastCard(ph),
                    const SizedBox(height: 20),
                  ],

                  // 4. SECURITY & RULES GUIDE
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
                  onPressed: _signOutGoogle,
                  child: const Text("Disconnect", style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 5),
            const Text("📁 Target Folder: Google Drive > Pharoah_ERP_Cloud", style: TextStyle(color: Colors.cyanAccent, fontSize: 10)),
          ] else ...[
            const Text(
              "Tap below to securely sign in with your Google account. This links your store database directly to your personal Google Drive.",
              style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                onPressed: () => _signInWithGoogle(ph),
                icon: const Icon(Icons.login_rounded, color: Colors.blueAccent, size: 20),
                label: const Text("CONNECT WITH GOOGLE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
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
              Text("PRIVACY & GOOGLE AUTH", style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
          Divider(color: Colors.white10, height: 25),
          Text(
            "• Real Google Sign-In: Only authentic Google accounts can link and sync store databases.\n• Switch OFF: App is 100% offline and local.\n• Switch ON: Real-time encrypted sync with your personal Google Drive.",
            style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
