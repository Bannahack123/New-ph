import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
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
  
  Map<String, dynamic> companyProfile = {};
  List<dynamic> salesList = [];
  List<dynamic> medicinesList = [];
  List<dynamic> partiesList = [];

  final passwordC = TextEditingController();
  bool isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _fetchCloudData();
  }

  // Google Drive se live data pull karna
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
          "companyId": "DEFAULT_COMPANY", // Dynamic per deployment
          "fy": "2026-27"
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        var res = jsonDecode(response.body);
        if (res['status'] == "SUCCESS" && res['data'] != null && res['data'].isNotEmpty) {
          var files = res['data'];

          if (files.containsKey('sales.json')) {
            salesList = jsonDecode(files['sales.json']);
          }
          if (files.containsKey('meds.json')) {
            medicinesList = jsonDecode(files['meds.json']);
          }
          if (files.containsKey('parts.json')) {
            partiesList = jsonDecode(files['parts.json']);
          }

          setState(() {
            isAccessGranted = true;
            isLoading = false;
          });
          return;
        }
      }

      setState(() {
        isAccessGranted = false;
        errorMessage = "No active company broadcast found. Please turn ON 'Live Web' in your Mobile App Settings.";
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

    // SCENARIO 1: SWITCH OFF YA DATA NA MILNE PAR (RED LOCK SCREEN)
    if (!isAccessGranted) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Container(
            width: 480,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.redAccent.withOpacity(0.4), width: 1.5),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 20)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_person_rounded, size: 70, color: Colors.redAccent),
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

    // SCENARIO 2: PASSWORD LOGIN SCREEN
    if (!isAuthenticated) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Container(
            width: 440,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.storefront_rounded, size: 50, color: Colors.cyanAccent),
                const SizedBox(height: 15),
                const Text("PHAROAH WEB STATION", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 5),
                const Text("Enter password to unlock workstation", style: TextStyle(color: Colors.white54, fontSize: 11)),
                const SizedBox(height: 25),
                TextField(
                  controller: passwordC,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Security Password",
                    labelStyle: TextStyle(color: Colors.white54),
                    prefixIcon: Icon(Icons.key, color: Colors.cyanAccent),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
                    onPressed: () {
                      if (passwordC.text.isNotEmpty) {
                        setState(() => isAuthenticated = true);
                      }
                    },
                    child: const Text("UNLOCK WORKSTATION", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // SCENARIO 3: LIVE WEB DASHBOARD
    double totalSalesAmt = salesList.fold(0.0, (sum, s) => sum + (s['totalAmount'] ?? 0.0));

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("PHAROAH WEB WORKSTATION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF1E1B4B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: "Refresh Data",
            onPressed: _fetchCloudData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Lock Station",
            onPressed: () => setState(() => isAuthenticated = false),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Summary Cards
            Row(
              children: [
                _kpiCard("TOTAL INVOICES", "${salesList.length}", Icons.receipt_long, Colors.blueAccent),
                const SizedBox(width: 15),
                _kpiCard("TOTAL SALES VALUE", "₹${totalSalesAmt.toStringAsFixed(0)}", Icons.currency_rupee, Colors.greenAccent),
                const SizedBox(width: 15),
                _kpiCard("ACTIVE PRODUCTS", "${medicinesList.length}", Icons.inventory_2, Colors.orangeAccent),
              ],
            ),
            const SizedBox(height: 30),

            // Live Sales Register on Web
            const Text("LIVE INVOICE FEED (GOOGLE DRIVE SYNCED)", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 15),

            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: salesList.length,
                separatorBuilder: (c, i) => const Divider(color: Colors.white10, height: 1),
                itemBuilder: (c, i) {
                  final s = salesList[i];
                  return ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.white10, child: Icon(Icons.receipt, color: Colors.cyanAccent, size: 20)),
                    title: Text(s['partyName'] ?? 'CASH', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text("Bill: ${s['billNo']} | Items: ${(s['items'] as List?)?.length ?? 0}", style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    trailing: Text("₹${s['totalAmount']}", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 15)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
