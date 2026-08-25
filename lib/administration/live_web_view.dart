import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LiveWebView extends StatefulWidget {
  const LiveWebView({super.key});

  @override
  State<LiveWebView> createState() => _LiveWebViewState();
}

class _LiveWebViewState extends State<LiveWebView> {
  bool isLiveWebActive = false;
  int serverPort = 8080;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isLiveWebActive = prefs.getBool('is_live_web_active') ?? false;
      serverPort = prefs.getInt('live_web_port') ?? 8080;
      isLoading = false;
    });
  }

  Future<void> _toggleLiveWeb(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_live_web_active', value);
    setState(() {
      isLiveWebActive = value;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? "🟢 Live Web Server Activated!" : "🔴 Live Web Server Stopped!"),
          backgroundColor: value ? Colors.teal.shade800 : Colors.red.shade900,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark Slate Background
      appBar: AppBar(
        title: const Text("Live Web Control Hub", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
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
                  // --- 1. MASTER LIVE WEB SWITCH CARD ---
                  _buildMasterSwitchCard(),
                  const SizedBox(height: 25),

                  // --- 2. STATUS & BROADCAST DETAILS ---
                  if (isLiveWebActive) ...[
                    _buildActiveBroadcastCard(),
                    const SizedBox(height: 25),
                  ],

                  // --- 3. CONFIGURATION & INFORMATION ---
                  _buildConfigGuideCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildMasterSwitchCard() {
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isLiveWebActive ? Colors.cyanAccent.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isLiveWebActive ? Icons.wifi_tethering_rounded : Icons.wifi_tethering_off_rounded,
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
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLiveWebActive ? "Status: ONLINE & BROADCASTING" : "Status: OFFLINE",
                      style: TextStyle(
                        color: isLiveWebActive ? Colors.greenAccent : Colors.white38,
                        fontSize: 11,
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
                onChanged: _toggleLiveWeb,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveBroadcastCard() {
    String liveUrl = "http://localhost:$serverPort";

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
          const Row(
            children: [
              Icon(Icons.sensors_rounded, color: Colors.greenAccent, size: 20),
              SizedBox(width: 10),
              Text("LIVE WEB ACCESS POINT", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
          const Divider(color: Colors.white24, height: 25),
          const Text("Live Web URL for iPad / Browser:", style: TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(liveUrl, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, color: Colors.white70, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: liveUrl));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("URL Copied to Clipboard!")));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Note: Other devices on your local network / codespace port can connect using this link.",
            style: TextStyle(color: Colors.white60, fontSize: 10, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigGuideCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.cyanAccent, size: 18),
              SizedBox(width: 10),
              Text("HOW LIVE WEB WORKS", style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
          const Divider(color: Colors.white10, height: 25),
          _stepBullet("1", "Toggle the switch ON to enable live web server access."),
          _stepBullet("2", "Open the generated link on any browser or iPad."),
          _stepBullet("3", "All billing, reports, and master records sync in real-time."),
          _stepBullet("4", "Toggle OFF anytime to disable external browser access."),
        ],
      ),
    );
  }

  Widget _stepBullet(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 9,
            backgroundColor: Colors.cyanAccent.withOpacity(0.2),
            child: Text(num, style: const TextStyle(fontSize: 9, color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.4))),
        ],
      ),
    );
  }
}
