// FILE: lib/web_live_sync/app_sync_engine.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../pharoah_manager.dart';
import 'weblivetoken.dart';
import 'web_cloud_config.dart';

class AppSyncEngine {
  static const List<String> _coreFiles = [
    'meds.json', 'parts.json', 'sales.json', 'purc.json',
    'bats.json', 'vouc.json', 's_challan.json', 'p_challan.json',
    's_return.json', 'p_return.json', 'banks.json', 'config.json',
    'series.json', 'shortage.json', 'routs.json', 'comps.json', 'salts.json'
  ];

  /// 🔄 TRUE 2-WAY SYNC: Pehle Cloud se Web ka data download karta hai, App me save karta hai, fir push karta hai
  static Future<bool> pushStoreData(PharoahManager ph) async {
    try {
      if (ph.activeCompany == null || ph.currentFY.isEmpty) return false;
      final workingDir = await ph.getWorkingPath();
      if (workingDir.isEmpty) return false;

      final storeToken = await WebLiveToken.getOrCreateToken(ph.activeCompany!.id);

      // STEP 1: PULL FROM CLOUD (Check if Web created bills/customers)
      try {
        final pullUri = Uri.parse(
          "${WebCloudConfig.cloudRelayEndpoint}?action=PULL_STORE_DATA"
          "&storeToken=${Uri.encodeComponent(storeToken)}"
          "&username=${Uri.encodeComponent(ph.activeCompany!.adminUser.toLowerCase())}"
          "&password=${Uri.encodeComponent(ph.activeCompany!.password)}"
        );

        final pullRes = await http.get(pullUri).timeout(const Duration(seconds: 15));
        if (pullRes.statusCode == 200) {
          final Map<String, dynamic> cloudData = jsonDecode(pullRes.body);
          if (cloudData['status'] == 'SUCCESS' && cloudData['files'] != null) {
            final Map<String, dynamic> cloudFiles = cloudData['files'];

            // Save cloud files into App local folder
            for (var entry in cloudFiles.entries) {
              final localFile = File('$workingDir/${entry.key}');
              if (entry.value != null && entry.value.toString().isNotEmpty) {
                await localFile.writeAsString(entry.value.toString());
              }
            }

            // Reload App Memory immediately
            await ph.loadAllData();
          }
        }
      } catch (e) {
        debugPrint("Pull before push error: $e");
      }

      // STEP 2: PUSH LOCAL APP DATABASE BACK TO CLOUD
      Map<String, String> filesPayload = {};
      for (var name in _coreFiles) {
        final file = File('$workingDir/$name');
        if (await file.exists()) {
          filesPayload[name] = await file.readAsString();
        }
      }

      final payload = {
        "action": WebCloudConfig.actionPushStore,
        "storeToken": storeToken,
        "companyId": ph.activeCompany!.id,
        "companyName": ph.activeCompany!.name,
        "adminUser": ph.activeCompany!.adminUser,
        "adminPassword": ph.activeCompany!.password,
        "fy": ph.currentFY,
        "registryProfile": ph.activeCompany!.toMap(),
        "files": filesPayload,
        "syncedAt": DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse(WebCloudConfig.cloudRelayEndpoint),
        headers: WebCloudConfig.standardHeaders,
        body: jsonEncode(payload),
      ).timeout(WebCloudConfig.networkTimeout);

      if (response.statusCode == 200 || response.body.contains("SUCCESS")) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_cloud_sync_time', DateTime.now().toIso8601String());
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("AppSyncEngine Error: $e");
      return false;
    }
  }

  static Future<String> getLastSyncFormattedTime() async {
    final prefs = await SharedPreferences.getInstance();
    String? timeStr = prefs.getString('last_cloud_sync_time');
    if (timeStr == null || timeStr.isEmpty) return "Never";
    try {
      DateTime dt = DateTime.parse(timeStr);
      String pad(int n) => n.toString().padLeft(2, '0');
      return "${pad(dt.day)}/${pad(dt.month)}/${dt.year} at ${pad(dt.hour)}:${pad(dt.minute)}";
    } catch (_) {
      return "Never";
    }
  }
}
