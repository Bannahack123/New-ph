import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'drive_sync_service.dart';

class WebPortalGateway extends StatefulWidget {
  const WebPortalGateway({super.key});

  @override
  State<WebPortalGateway> createState() => _WebPortalGatewayState();
}

class _WebPortalGatewayState extends State<WebPortalGateway> {
  bool isLoading = true;
  bool isAccessGranted = false;
  String errorMessage = "";
  
  String companyName = "";
  String financialYear = "";

  @override
  void initState() {
    super.initState();
    _fetchCloudData();
  }

  // Google Drive se live connection verify karna
  Future<void> _fetchCloudData() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      final response = await http.post(
        Uri.parse(DriveSyncService.defaultEndpoint),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "PULL_DATA",
          "companyId": "DEFAULT_COMPANY",
          "fy": "2026-27"
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        var res = jsonDecode(response.body);
        if (res['status'] == "SUCCESS" && res['data'] != null && res['data'].isNotEmpty) {
          var files = res['data'];

          if (files.containsKey('profile.json')) {
            var profile = jsonDecode(files['profile.json']);
            companyName = profile['name'] ?? "PHAROAH STORE";
          } else {
            companyName = "PHAROAH STORE";
          }
          financialYear = "2026-27";

          setState(() {
            isAccessGranted = true;
            isLoading = false;
          });
          return;
        }
      }

      setState(() {
        isAccessGranted = false;
        errorMessage = "No active company broadcast found. Please turn ON 'Live Web' in your Pharoah Mobile App Settings.";
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isAccessGranted = false;
        errorMessage = "Connection error. Please check your internet or App sync status.";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. LOADING STATE
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.cyanAccent),
              SizedBox(height: 20),
              Text("Connecting to Pharoah Cloud Drive...", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    // 2. SCENARIO A: TOGGLE SWITCH OFF (RESTRICTED LOCK)
    if (!isAccessGranted) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Container(
            width: 480,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(35),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.redAccent.withOpacity(0.4), width: 1.5),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 20)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_person_rounded, size: 75, color: Colors.redAccent),
                const SizedBox(height: 20),
                const Text(
                  "ACCESS RESTRICTED",
                  style: TextStyle(color: Colors.redAccent, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
                const SizedBox(height: 12),
                Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
                    onPressed: _fetchCloudData,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text("RETRY CONNECTION", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 3. SCENARIO B: TOGGLE ON -> DIRECT MAIN DASHBOARD (WELCOME TO PHAROAH ERP)
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("PHAROAH WEB WORKSTATION", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
        backgroundColor: const Color(0xFF1E1B4B),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.greenAccent),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                SizedBox(width: 6),
                Text("LIVE CLOUD ACTIVE", style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            tooltip: "Refresh Cloud Data",
            onPressed: _fetchCloudData,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hero Welcome Card
              Container(
                width: 650,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E1B4B), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.stars_rounded, size: 70, color: Colors.cyanAccent),
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      "Welcome to Pharoah ERP",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Your Real-Time Cloud Workstation is Active & Synced.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 25),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 15),
                    if (companyName.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.storefront_rounded, size: 18, color: Colors.cyanAccent),
                          const SizedBox(width: 8),
                          Text(
                            companyName.toUpperCase(),
                            style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
