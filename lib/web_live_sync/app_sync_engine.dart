// FILE: lib/web_live_sync/app_sync_engine.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../pharoah_manager.dart';
import '../models.dart';
import 'weblivetoken.dart';
import 'web_cloud_config.dart';

class AppSyncEngine {
  static const List<String> _coreFiles = [
    'meds.json', 'parts.json', 'sales.json', 'purc.json',
    'bats.json', 'vouc.json', 's_challan.json', 'p_challan.json',
    's_return.json', 'p_return.json', 'banks.json', 'config.json',
    'series.json', 'shortage.json', 'routs.json', 'comps.json', 'salts.json'
  ];

  /// 🔄 BULLETPROOF 2-WAY SYNC ENGINE (TIMESTAMP + DELETION AWARE)
  static Future<bool> pushStoreData(PharoahManager ph) async {
    try {
      if (ph.activeCompany == null || ph.currentFY.isEmpty) return false;
      final workingDir = await ph.getWorkingPath();
      if (workingDir.isEmpty) return false;

      final prefs = await SharedPreferences.getInstance();
      final companyId = ph.activeCompany!.id;
      final storeToken = await WebLiveToken.getOrCreateToken(companyId);

      // Read last sync time to distinguish NEW web entries from LOCALLY DELETED entries
      final String? lastSyncStr = prefs.getString('last_cloud_sync_time');
      final DateTime lastSyncTime = lastSyncStr != null && lastSyncStr.isNotEmpty
          ? DateTime.tryParse(lastSyncStr) ?? DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.fromMillisecondsSinceEpoch(0);

      // Track set of known imported web IDs
      final String syncHistoryKey = 'all_imported_web_sales_$companyId';
      final Set<String> importedHistory = (prefs.getStringList(syncHistoryKey) ?? []).toSet();

      // Current IDs in App
      final Set<String> currentAppSaleIds = ph.sales.map((s) => s.id).toSet();
      final Set<String> currentAppSaleBillNos = ph.sales.map((s) => s.billNo).toSet();

      // -----------------------------------------------------------------------
      // STEP 1: SMART PULL & DELTA MERGE
      // -----------------------------------------------------------------------
      try {
        final pullUri = Uri.parse(
          "${WebCloudConfig.cloudRelayEndpoint}?action=PULL_STORE_DATA"
          "&storeToken=${Uri.encodeComponent(storeToken)}"
          "&username=${Uri.encodeComponent(ph.activeCompany!.adminUser.toLowerCase())}"
          "&password=${Uri.encodeComponent(ph.activeCompany!.password)}"
        );

        final pullRes = await http.get(pullUri).timeout(const Duration(seconds: 15));
        if (pullRes.statusCode == 200 && !pullRes.body.contains("ERROR")) {
          final Map<String, dynamic> cloudData = jsonDecode(pullRes.body);
          if (cloudData['status'] == 'SUCCESS' && cloudData['files'] != null) {
            final Map<String, dynamic> cloudFiles = cloudData['files'];

            // 1. Merge Web Sales
            if (cloudFiles['sales.json'] != null) {
              List<dynamic> cloudSalesList = jsonDecode(cloudFiles['sales.json'].toString());
              bool hasNewSales = false;

              for (var rawSale in cloudSalesList) {
                final saleMap = rawSale as Map<String, dynamic>;
                String sId = saleMap['id'] ?? '';
                String bNo = saleMap['billNo'] ?? '';
                String tag = saleMap['sourceTag'] ?? '';
                bool isWebBill = tag == 'WEB-PORTAL' || sId.startsWith('SALE-WEB');

                if (isWebBill) {
                  // If this bill was already imported in the past OR created before last sync,
                  // and is missing from App -> User DELETED it on App! DO NOT RE-IMPORT!
                  if (importedHistory.contains(sId) && !currentAppSaleIds.contains(sId)) {
                    continue; // Skip deleted bill
                  }

                  // Check creation timestamp from ID (e.g. SALE-WEB-1772183920000)
                  if (!importedHistory.contains(sId) && !currentAppSaleIds.contains(sId)) {
                    int? billEpoch;
                    if (sId.startsWith('SALE-WEB-')) {
                      billEpoch = int.tryParse(sId.replaceFirst('SALE-WEB-', ''));
                    }
                    if (billEpoch != null && lastSyncTime.millisecondsSinceEpoch > 0) {
                      DateTime billCreatedAt = DateTime.fromMillisecondsSinceEpoch(billEpoch);
                      // If bill was created BEFORE last sync and is not in App -> It was deleted
                      if (billCreatedAt.isBefore(lastSyncTime)) {
                        importedHistory.add(sId);
                        continue;
                      }
                    }

                    // Genuine NEW bill from Web!
                    if (!currentAppSaleBillNos.contains(bNo)) {
                      ph.sales.add(Sale.fromMap(saleMap));
                      importedHistory.add(sId);
                      currentAppSaleIds.add(sId);
                      currentAppSaleBillNos.add(bNo);
                      hasNewSales = true;
                    }
                  } else {
                    importedHistory.add(sId);
                  }
                }
              }

              if (hasNewSales) {
                await ph.save();
              }
            }

            // 2. Merge Web Parties
            if (cloudFiles['parts.json'] != null) {
              List<dynamic> cloudPartsList = jsonDecode(cloudFiles['parts.json'].toString());
              Set<String> appPartNames = ph.parties.map((p) => p.name.toUpperCase().trim()).toSet();
              bool hasNewParts = false;

              for (var rawPart in cloudPartsList) {
                final partMap = rawPart as Map<String, dynamic>;
                String pName = (partMap['name'] ?? '').toString().toUpperCase().trim();
                String pId = partMap['id'] ?? '';

                if ((pId.startsWith('PARTY-WEB') || !appPartNames.contains(pName)) && pName.isNotEmpty) {
                  ph.parties.add(Party.fromMap(partMap));
                  appPartNames.add(pName);
                  hasNewParts = true;
                }
              }

              if (hasNewParts) {
                await ph.save();
              }
            }

            // 3. Merge Web Products
            if (cloudFiles['meds.json'] != null) {
              List<dynamic> cloudMedsList = jsonDecode(cloudFiles['meds.json'].toString());
              Set<String> appMedNames = ph.medicines.map((m) => m.name.toUpperCase().trim()).toSet();
              bool hasNewMeds = false;

              for (var rawMed in cloudMedsList) {
                final medMap = rawMed as Map<String, dynamic>;
                String mName = (medMap['name'] ?? '').toString().toUpperCase().trim();
                String mId = medMap['id'] ?? '';

                if ((mId.startsWith('PH-W') || !appMedNames.contains(mName)) && mName.isNotEmpty) {
                  ph.medicines.add(Medicine.fromMap(medMap));
                  appMedNames.add(mName);
                  hasNewMeds = true;
                }
              }

              if (hasNewMeds) {
                await ph.save();
              }
            }

            await ph.loadAllData();
          }
        }
      } catch (e) {
        debugPrint("Smart pull error: $e");
      }

      // -----------------------------------------------------------------------
      // STEP 2: PUSH CONSOLIDATED LOCAL APP DATABASE TO CLOUD
      // -----------------------------------------------------------------------
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

      final client = http.Client();
      final request = http.Request('POST', Uri.parse(WebCloudConfig.cloudRelayEndpoint))
        ..headers.addAll(WebCloudConfig.standardHeaders)
        ..body = jsonEncode(payload)
        ..followRedirects = true;

      final streamedResponse = await client.send(request).timeout(WebCloudConfig.networkTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 400) {
        await prefs.setStringList(syncHistoryKey, importedHistory.toList());
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
