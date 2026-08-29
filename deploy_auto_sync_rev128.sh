#!/bin/bash
set -e

export PATH="$HOME/flutter/bin:$PATH"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}   ⚡ SILENT AUTO-SYNC ENGINE & DEPLOY (#128)      ${NC}"
echo -e "${BLUE}====================================================${NC}\n"

# 1. Create Standalone Auto Sync Service (lib/web_live_sync/pharoah_auto_sync_service.dart)
echo -e "${YELLOW}[1/4] Creating standalone pharoah_auto_sync_service.dart...${NC}"
cat << 'AUTOSYNC_EOF' > lib/web_live_sync/pharoah_auto_sync_service.dart
// FILE: lib/web_live_sync/pharoah_auto_sync_service.dart
// Live Revision: #PH-REV-128

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'pharoah_web_manager.dart';

class PharoahAutoSyncService {
  final PharoahWebManager webManager;
  Timer? _debounceTimer;
  Timer? _heartbeatTimer;
  bool _isSyncing = false;

  PharoahAutoSyncService({required this.webManager}) {
    _startPeriodicHeartbeat();
  }

  /// 🔄 1. DEBOUNCED AUTO-PUSH (Triggered on any Transaction / Master update)
  /// Rapid clicks or multiple line items won't spam the network;
  /// it waits 2 seconds after the last action and silently syncs to Cloud.
  void triggerAutoSync() {
    if (!webManager.isAuthenticated || webManager.activeStoreToken.isEmpty) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () async {
      if (_isSyncing) return;
      _isSyncing = true;
      try {
        await webManager.pushUpdatedDataToCloud();
        debugPrint("⚡ [AutoSync] Background delta pushed to cloud successfully.");
      } catch (e) {
        debugPrint("⚠ [AutoSync] Background push error: $e");
      } finally {
        _isSyncing = false;
      }
    });
  }

  /// 💓 2. PERIODIC BACKGROUND HEARTBEAT (Silent Pull & Merge every 2 minutes)
  void _startPeriodicHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 2), (_) async {
      if (!webManager.isAuthenticated || webManager.activeStoreToken.isEmpty || _isSyncing) return;
      _isSyncing = true;
      try {
        await webManager.refreshStoreData();
        debugPrint("💓 [AutoSync] Periodic cloud heartbeat sync completed.");
      } catch (e) {
        debugPrint("⚠ [AutoSync] Heartbeat pull error: $e");
      } finally {
        _isSyncing = false;
      }
    });
  }

  void dispose() {
    _debounceTimer?.cancel();
    _heartbeatTimer?.cancel();
  }
}
AUTOSYNC_EOF

# 2. Update pharoah_web_manager.dart to integrate Auto-Sync Service
echo -e "${YELLOW}[2/4] Hooking Auto-Sync into pharoah_web_manager.dart...${NC}"
cat << 'MGR_EOF' > lib/web_live_sync/pharoah_web_manager.dart
// FILE: lib/web_live_sync/pharoah_web_manager.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'web_models.dart';
import 'web_inventory_logic_center.dart';
import 'web_sync_engine.dart';
import 'web_pharoah_numbering_engine.dart';
import 'web_app_date_logic.dart';
import 'web_cloud_config.dart';
import 'pharoah_auto_sync_service.dart';

class PharoahWebManager with ChangeNotifier {
  bool isLoading = false;
  bool isAutoLoggingIn = true;
  bool isAuthenticated = false;
  String errorMessage = "";
  String successMessage = "";

  // Session & Store Metadata
  String activeStoreToken = "";
  String activeUsername = "";
  String activePassword = "";
  String companyName = "PHAROAH STORE";
  String financialYear = "2026-27";
  Map<String, dynamic> companyProfile = {};
  AppConfig appConfig = AppConfig();

  // 🛡️ TOMBSTONE DELETION REGISTRY
  Set<String> deletedRecordIds = {};

  // Auto-Sync Background Watchdog
  late final PharoahAutoSyncService _autoSyncService;

  // Strongly-Typed Business Models
  List<Medicine> medicines = [];
  List<Party> parties = [];
  List<Sale> sales = [];
  List<Purchase> purchases = [];
  List<Voucher> vouchers = [];
  List<SaleChallan> saleChallans = [];
  List<PurchaseChallan> purchaseChallans = [];
  List<SaleReturn> saleReturns = [];
  List<PurchaseReturn> purchaseReturns = [];
  List<Company> companies = [];
  List<Salt> salts = [];
  List<RouteArea> routes = [];
  List<Bank> banks = [];
  List<NumberingSeries> numberingSeries = [];
  Map<String, List<BatchInfo>> batchHistory = {};

  PharoahWebManager() {
    _autoSyncService = PharoahAutoSyncService(webManager: this);
    _loadLocalTombstones();
    tryAutoLogin();
  }

  Future<void> _loadLocalTombstones() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('web_tombstone_ids') ?? [];
      deletedRecordIds = list.toSet();
    } catch (_) {}
  }

  Future<void> _saveLocalTombstones() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('web_tombstone_ids', deletedRecordIds.toList());
    } catch (_) {}
  }

  Future<bool> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool wasLoggedIn = prefs.getBool('web_auth_logged_in') ?? false;
      String? savedToken = prefs.getString('web_auth_store_token');
      String? savedUser = prefs.getString('web_auth_username');
      String? savedPass = prefs.getString('web_auth_password');

      if (wasLoggedIn && savedToken != null && savedUser != null && savedPass != null) {
        isLoading = true;
        notifyListeners();

        final result = await WebSyncEngine.fetchStoreData(
          storeToken: savedToken,
          username: savedUser,
          password: savedPass,
        );

        if (result['success'] == true) {
          _populateDataFromCloud(savedToken, savedUser, savedPass, result);
          isAuthenticated = true;
          isLoading = false;
          isAutoLoggingIn = false;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint("Auto-login Error: $e");
    }
    isAutoLoggingIn = false;
    isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> loginWithStoreKey({
    required String storeToken,
    required String username,
    required String password,
  }) async {
    isLoading = true;
    errorMessage = "";
    successMessage = "";
    notifyListeners();

    final result = await WebSyncEngine.fetchStoreData(
      storeToken: storeToken,
      username: username,
      password: password,
    );

    if (result['success'] == true) {
      _populateDataFromCloud(storeToken, username, password, result);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('web_auth_logged_in', true);
      await prefs.setString('web_auth_store_token', activeStoreToken);
      await prefs.setString('web_auth_username', activeUsername);
      await prefs.setString('web_auth_password', activePassword);

      isAuthenticated = true;
      isLoading = false;
      successMessage = "Store connected successfully!";
      notifyListeners();
      return true;
    } else {
      isLoading = false;
      isAuthenticated = false;
      errorMessage = result['message'] ?? 'Authentication failed.';
      notifyListeners();
      return false;
    }
  }

  void _populateDataFromCloud(String token, String user, String pass, Map<String, dynamic> result) {
    activeStoreToken = token.trim().toUpperCase();
    activeUsername = user.trim();
    activePassword = pass.trim();
    companyName = result['companyName'] ?? 'STORE WORKSTATION';
    financialYear = result['fy'] ?? WebAppDateLogic.getCurrentFYString();
    companyProfile = result['profile'] ?? {};

    final Map<String, dynamic> files = result['files'] ?? {};
    _parseDownloadedFiles(files);

    rebuildInventory();
  }

  void _parseDownloadedFiles(Map<String, dynamic> files) {
    dynamic decodeJson(String fileName) {
      if (files.containsKey(fileName) && files[fileName] != null) {
        try {
          return jsonDecode(files[fileName]);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    var tData = decodeJson('tombstones.json');
    if (tData != null && tData is List) {
      deletedRecordIds.addAll(tData.map((e) => e.toString()));
      _saveLocalTombstones();
    }

    medicines = (decodeJson('meds.json') as List?)
        ?.map((e) => Medicine.fromMap(e))
        .where((m) => !deletedRecordIds.contains(m.id))
        .toList() ?? [];

    parties = (decodeJson('parts.json') as List?)
        ?.map((e) => Party.fromMap(e))
        .where((p) => !deletedRecordIds.contains(p.id))
        .toList() ?? [Party(id: 'cash', name: "CASH", group: "Cash in Hand")];

    sales = (decodeJson('sales.json') as List?)
        ?.map((e) => Sale.fromMap(e))
        .where((s) => !deletedRecordIds.contains(s.id))
        .toList() ?? [];

    purchases = (decodeJson('purc.json') as List?)
        ?.map((e) => Purchase.fromMap(e))
        .where((p) => !deletedRecordIds.contains(p.id))
        .toList() ?? [];

    vouchers = (decodeJson('vouc.json') as List?)
        ?.map((e) => Voucher.fromMap(e))
        .where((v) => !deletedRecordIds.contains(v.id))
        .toList() ?? [];

    saleChallans = (decodeJson('s_challan.json') as List?)
        ?.map((e) => SaleChallan.fromMap(e))
        .where((c) => !deletedRecordIds.contains(c.id))
        .toList() ?? [];

    purchaseChallans = (decodeJson('p_challan.json') as List?)
        ?.map((e) => PurchaseChallan.fromMap(e))
        .where((c) => !deletedRecordIds.contains(c.id))
        .toList() ?? [];

    saleReturns = (decodeJson('s_return.json') as List?)
        ?.map((e) => SaleReturn.fromMap(e))
        .where((r) => !deletedRecordIds.contains(r.id))
        .toList() ?? [];

    purchaseReturns = (decodeJson('p_return.json') as List?)
        ?.map((e) => PurchaseReturn.fromMap(e))
        .where((r) => !deletedRecordIds.contains(r.id))
        .toList() ?? [];

    companies = (decodeJson('comps.json') as List?)?.map((e) => Company.fromMap(e)).toList() ?? [];
    salts = (decodeJson('salts.json') as List?)?.map((e) => Salt.fromMap(e)).toList() ?? [];
    routes = (decodeJson('routs.json') as List?)?.map((e) => RouteArea.fromMap(e)).toList() ?? [];
    banks = (decodeJson('banks.json') as List?)?.map((e) => Bank.fromMap(e)).toList() ?? [];
    numberingSeries = (decodeJson('series.json') as List?)?.map((e) => NumberingSeries.fromMap(e)).toList() ?? [];

    var cData = decodeJson('config.json');
    if (cData != null && cData is Map<String, dynamic>) {
      appConfig = AppConfig.fromMap(cData);
    }

    var bData = decodeJson('bats.json');
    batchHistory.clear();
    if (bData != null && bData is Map) {
      bData.forEach((k, v) {
        if (v is List) {
          batchHistory[k.toString()] = v.map((b) => BatchInfo.fromMap(b as Map<String, dynamic>)).toList();
        }
      });
    }
  }

  void rebuildInventory() {
    WebInventoryLogicCenter.rebuildWebInventory(
      medicines: medicines,
      batchHistory: batchHistory,
      purchases: purchases,
      sales: sales,
      saleReturns: saleReturns,
      purchaseReturns: purchaseReturns,
    );
  }

  void registerBatchActivity({
    required String productKey,
    required String batchNo,
    required String exp,
    required String packing,
    required double mrp,
    required double rate,
    double rateA = 0.0,
    double rateB = 0.0,
    double rateC = 0.0,
    double rateCFormula = 0.0,
    String appliedRateType = "A",
    double qtyChange = 0.0,
    String status = "Active",
  }) {
    if (!batchHistory.containsKey(productKey)) {
      batchHistory[productKey] = [];
    }

    List<BatchInfo> history = batchHistory[productKey]!;
    int existingIdx = history.indexWhere((b) => b.batch.trim() == batchNo.trim());

    double finalRateA = rateA == 0.0 ? mrp : rateA;
    double finalRateB = rateB == 0.0 ? (rateA == 0.0 ? mrp * 0.95 : rateA * 0.95) : rateB;
    double finalRateC = rateC == 0.0 ? (rateA == 0.0 ? mrp * 0.92 : rateA * 0.92) : rateC;

    if (existingIdx != -1) {
      history[existingIdx].exp = exp;
      history[existingIdx].mrp = mrp;
      history[existingIdx].rate = rate;
      history[existingIdx].packing = packing;
      history[existingIdx].purRate = rate;
      history[existingIdx].rateA = finalRateA;
      history[existingIdx].rateB = finalRateB;
      history[existingIdx].rateC = finalRateC;
      history[existingIdx].rateCFormula = rateCFormula;
      history[existingIdx].appliedRateType = appliedRateType;
      history[existingIdx].status = status;
      if (qtyChange != 0.0) {
        history[existingIdx].qty += qtyChange;
      }
    } else {
      history.add(BatchInfo(
        batch: batchNo.trim(),
        exp: exp,
        packing: packing,
        mrp: mrp,
        rate: rate,
        qty: qtyChange,
        openingQty: qtyChange,
        isShell: false,
        purRate: rate,
        rateA: finalRateA,
        rateB: finalRateB,
        rateC: finalRateC,
        rateCFormula: rateCFormula,
        appliedRateType: appliedRateType,
        status: status,
      ));
    }
  }

  Future<bool> pushUpdatedDataToCloud() async {
    try {
      if (!isAuthenticated || activeStoreToken.isEmpty) return false;

      Map<String, String> filesPayload = {
        'meds.json': jsonEncode(medicines.map((e) => e.toMap()).toList()),
        'parts.json': jsonEncode(parties.map((e) => e.toMap()).toList()),
        'sales.json': jsonEncode(sales.map((e) => e.toMap()).toList()),
        'purc.json': jsonEncode(purchases.map((e) => e.toMap()).toList()),
        'vouc.json': jsonEncode(vouchers.map((e) => e.toMap()).toList()),
        's_challan.json': jsonEncode(saleChallans.map((e) => e.toMap()).toList()),
        'p_challan.json': jsonEncode(purchaseChallans.map((e) => e.toMap()).toList()),
        's_return.json': jsonEncode(saleReturns.map((e) => e.toMap()).toList()),
        'p_return.json': jsonEncode(purchaseReturns.map((e) => e.toMap()).toList()),
        'comps.json': jsonEncode(companies.map((e) => e.toMap()).toList()),
        'salts.json': jsonEncode(salts.map((e) => e.toMap()).toList()),
        'routs.json': jsonEncode(routes.map((e) => e.toMap()).toList()),
        'banks.json': jsonEncode(banks.map((e) => e.toMap()).toList()),
        'series.json': jsonEncode(numberingSeries.map((e) => e.toMap()).toList()),
        'config.json': jsonEncode(appConfig.toMap()),
        'bats.json': jsonEncode(batchHistory.map((k, v) => MapEntry(k, v.map((b) => b.toMap()).toList()))),
        'tombstones.json': jsonEncode(deletedRecordIds.toList()),
      };

      final payload = {
        "action": WebCloudConfig.actionPushStore,
        "storeToken": activeStoreToken,
        "companyId": companyProfile['id'] ?? 'STORE',
        "companyName": companyName,
        "adminUser": activeUsername,
        "adminPassword": activePassword,
        "fy": financialYear,
        "registryProfile": companyProfile,
        "files": filesPayload,
        "syncedAt": DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse(WebCloudConfig.cloudRelayEndpoint),
        headers: WebCloudConfig.standardHeaders,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 25));

      return response.statusCode == 200 || response.body.contains("SUCCESS");
    } catch (e) {
      debugPrint("Web push error: $e");
      return false;
    }
  }

  void addSaleAndSync(Sale sale) {
    sales.add(sale);
    for (var item in sale.items) {
      String resolvedKey = item.medicineID;
      try {
        final med = medicines.firstWhere((m) => m.id == item.medicineID);
        resolvedKey = med.identityKey;
      } catch (_) {}

      registerBatchActivity(
        productKey: resolvedKey,
        batchNo: item.batch,
        exp: item.exp,
        packing: item.packing,
        mrp: item.mrp,
        rate: item.rate,
        rateA: item.appliedRateType == "A" ? item.rate : 0.0,
        rateB: item.appliedRateType == "B" ? item.rate : 0.0,
        rateC: item.appliedRateType == "C" ? item.rate : 0.0,
        rateCFormula: item.rateCFormula,
        appliedRateType: item.appliedRateType,
      );
    }
    rebuildInventory();
    notifyListeners();
    _autoSyncService.triggerAutoSync(); // ⚡ Silent Debounced Push
  }

  void deleteSale(String saleId) {
    try {
      final s = sales.firstWhere((x) => x.id == saleId);
      if (s.linkedChallanIds.isNotEmpty) {
        for (var cid in s.linkedChallanIds) {
          int idx = saleChallans.indexWhere((c) => c.id == cid);
          if (idx != -1) {
            saleChallans[idx].status = "Pending";
          }
        }
      }
    } catch (_) {}

    deletedRecordIds.add(saleId);
    _saveLocalTombstones();

    sales.removeWhere((s) => s.id == saleId);
    rebuildInventory();
    notifyListeners();
    _autoSyncService.triggerAutoSync(); // ⚡ Silent Debounced Push
  }

  void addPurchaseAndSync(Purchase purchase) {
    purchases.add(purchase);
    for (var item in purchase.items) {
      String resolvedKey = item.medicineID;
      try {
        final med = medicines.firstWhere((m) => m.id == item.medicineID);
        resolvedKey = med.identityKey;
      } catch (_) {}

      registerBatchActivity(
        productKey: resolvedKey,
        batchNo: item.batch,
        exp: item.exp,
        packing: item.packing,
        mrp: item.mrp,
        rate: item.purchaseRate,
        rateA: item.rateA,
        rateB: item.rateB,
        rateC: item.rateC,
        rateCFormula: item.rateCFormula,
        appliedRateType: item.appliedRateType,
      );
    }
    rebuildInventory();
    notifyListeners();
    _autoSyncService.triggerAutoSync(); // ⚡ Silent Debounced Push
  }

  void deletePurchase(String purId) {
    try {
      final p = purchases.firstWhere((x) => x.id == purId);
      if (p.linkedChallanIds.isNotEmpty) {
        for (var cid in p.linkedChallanIds) {
          int idx = purchaseChallans.indexWhere((c) => c.id == cid);
          if (idx != -1) {
            purchaseChallans[idx].status = "Pending";
          }
        }
      }
    } catch (_) {}

    deletedRecordIds.add(purId);
    _saveLocalTombstones();

    purchases.removeWhere((p) => p.id == purId);
    rebuildInventory();
    notifyListeners();
    _autoSyncService.triggerAutoSync(); // ⚡ Silent Debounced Push
  }

  void deleteVoucher(String voucherId) {
    deletedRecordIds.add(voucherId);
    _saveLocalTombstones();

    vouchers.removeWhere((v) => v.id == voucherId);
    notifyListeners();
    _autoSyncService.triggerAutoSync();
  }

  void deleteSaleChallan(String challanId) {
    deletedRecordIds.add(challanId);
    _saveLocalTombstones();

    saleChallans.removeWhere((c) => c.id == challanId);
    notifyListeners();
    _autoSyncService.triggerAutoSync();
  }

  void deletePurchaseChallan(String challanId) {
    deletedRecordIds.add(challanId);
    _saveLocalTombstones();

    purchaseChallans.removeWhere((c) => c.id == challanId);
    notifyListeners();
    _autoSyncService.triggerAutoSync();
  }

  void deleteSaleReturn(String returnId) {
    deletedRecordIds.add(returnId);
    _saveLocalTombstones();

    saleReturns.removeWhere((r) => r.id == returnId);
    rebuildInventory();
    notifyListeners();
    _autoSyncService.triggerAutoSync();
  }

  void deletePurchaseReturn(String returnId) {
    deletedRecordIds.add(returnId);
    _saveLocalTombstones();

    purchaseReturns.removeWhere((r) => r.id == returnId);
    rebuildInventory();
    notifyListeners();
    _autoSyncService.triggerAutoSync();
  }

  String getOrCreateCompany(String name) {
    try {
      return companies.firstWhere((c) => c.name.toUpperCase() == name.trim().toUpperCase()).id;
    } catch (_) {
      String id = "CP-${1000 + companies.length + 1}";
      companies.add(Company(id: id, name: name.trim().toUpperCase()));
      _autoSyncService.triggerAutoSync();
      return id;
    }
  }

  String getOrCreateSalt(String name) {
    try {
      return salts.firstWhere((s) => s.name.toUpperCase() == name.trim().toUpperCase()).id;
    } catch (_) {
      String id = "SL-${1000 + salts.length + 1}";
      salts.add(Salt(id: id, name: name.trim().toUpperCase()));
      _autoSyncService.triggerAutoSync();
      return id;
    }
  }

  void addParty(Party newParty) {
    parties.add(newParty);
    notifyListeners();
    _autoSyncService.triggerAutoSync();
  }

  void updateParty(Party updatedParty) {
    int idx = parties.indexWhere((p) => p.id == updatedParty.id);
    if (idx != -1) {
      parties[idx] = updatedParty;
      notifyListeners();
      _autoSyncService.triggerAutoSync();
    }
  }

  void deleteParty(String partyId) {
    deletedRecordIds.add(partyId);
    _saveLocalTombstones();

    parties.removeWhere((p) => p.id == partyId);
    notifyListeners();
    _autoSyncService.triggerAutoSync();
  }

  void addMedicine(Medicine newMed) {
    medicines.add(newMed);
    if (!batchHistory.containsKey(newMed.identityKey)) {
      batchHistory[newMed.identityKey] = [];
    }
    notifyListeners();
    _autoSyncService.triggerAutoSync();
  }

  void updateMedicine(Medicine updatedMed) {
    int idx = medicines.indexWhere((m) => m.id == updatedMed.id);
    if (idx != -1) {
      medicines[idx] = updatedMed;
      notifyListeners();
      _autoSyncService.triggerAutoSync();
    }
  }

  void deleteMedicine(String medId) {
    deletedRecordIds.add(medId);
    _saveLocalTombstones();

    medicines.removeWhere((item) => item.id == medId);
    notifyListeners();
    _autoSyncService.triggerAutoSync();
  }

  String getNextBillNumber(String type, String defaultPrefix, int defaultStart) {
    NumberingSeries? s;
    try {
      s = numberingSeries.firstWhere((ser) => ser.type == type && ser.isDefault && ser.isActive);
    } catch (_) {
      try {
        s = numberingSeries.firstWhere((ser) => ser.type == type && ser.isActive);
      } catch (_) {
        s = null;
      }
    }

    String prefix = s?.prefix ?? defaultPrefix;
    int start = s?.startNumber ?? defaultStart;

    List<dynamic> targetList;
    if (type == "SALE") {
      targetList = sales;
    } else if (type == "PURCHASE") {
      targetList = purchases;
    } else if (type == "CHALLAN") {
      targetList = saleChallans;
    } else if (type == "RETURN") {
      targetList = saleReturns;
    } else {
      targetList = vouchers;
    }

    return WebPharoahNumberingEngine.getNextNumber(
      prefix: prefix,
      startFrom: start,
      currentList: targetList,
    );
  }

  Future<void> refreshStoreData() async {
    if (!isAuthenticated || activeStoreToken.isEmpty) return;
    isLoading = true;
    notifyListeners();

    final result = await WebSyncEngine.fetchStoreData(
      storeToken: activeStoreToken,
      username: activeUsername,
      password: activePassword,
    );

    if (result['success'] == true) {
      final Map<String, dynamic> files = result['files'] ?? {};
      _parseDownloadedFiles(files);
      rebuildInventory();
      successMessage = "Data refreshed live!";
    } else {
      errorMessage = result['message'] ?? 'Live Refresh failed.';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('web_auth_logged_in', false);
    await prefs.remove('web_auth_password');

    _autoSyncService.dispose();
    isAuthenticated = false;
    activeStoreToken = "";
    activeUsername = "";
    activePassword = "";
    sales.clear();
    medicines.clear();
    parties.clear();
    purchases.clear();
    vouchers.clear();
    saleChallans.clear();
    purchaseChallans.clear();
    saleReturns.clear();
    purchaseReturns.clear();
    batchHistory.clear();
    deletedRecordIds.clear();
    notifyListeners();
  }
}
MGR_EOF

# 3. Update Top Bar Badge to #PH-REV-128
echo -e "${YELLOW}[3/4] Updating Top Bar Badge to #PH-REV-128...${NC}"
cat << 'TOPBAR_EOF' > lib/web_live_sync/components/web_top_bar.dart
// FILE: lib/web_live_sync/components/web_top_bar.dart

import 'package:flutter/material.dart';
import '../pharoah_web_manager.dart';

class WebTopBar extends StatelessWidget implements PreferredSizeWidget {
  final PharoahWebManager webPh;
  final ValueChanged<String>? onSearchChanged;

  const WebTopBar({
    super.key,
    required this.webPh,
    this.onSearchChanged,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
              color: Color(0x332563EB),
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: const Icon(Icons.storefront_rounded, color: Color(0xFF38BDF8), size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                webPh.companyName.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              Row(
                children: [
                  Text(
                    "FY: ${webPh.financialYear}",
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: Color(0xFF38BDF8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0x2610B981),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.greenAccent, width: 0.5),
                    ),
                    child: const Text(
                      "#PH-REV-128",
                      style: TextStyle(color: Colors.greenAccent, fontSize: 8, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Container(
              height: 36,
              constraints: const BoxConstraints(maxWidth: 380),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: TextField(
                onChanged: onSearchChanged,
                style: const TextStyle(color: Colors.white, fontSize: 11.5),
                decoration: const InputDecoration(
                  hintText: "Search Medicines, Customers, Invoices...",
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 11),
                  prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF38BDF8), size: 16),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 9),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0x1F10B981),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x4D10B981)),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, color: Colors.greenAccent, size: 7),
                SizedBox(width: 6),
                Text(
                  "LIVE CLOUD",
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: Colors.white70, size: 20),
            tooltip: "Refresh Live Data",
            onPressed: () {
              webPh.refreshStoreData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("🔄 Live Cloud Database Refreshed!"),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
            tooltip: "Sign Out",
            onPressed: () => _confirmSignOut(context, webPh),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, PharoahWebManager webPh) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Colors.white10),
        ),
        title: const Text("Sign Out Workstation?", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text(
          "Are you sure you want to disconnect from this store workstation?",
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("CANCEL", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(c);
              webPh.signOut();
            },
            child: const Text("SIGN OUT", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
TOPBAR_EOF

# 4. Verify with Analyzer and Deploy to Cloudflare Pages
echo -e "${YELLOW}[4/4] Running Analyzer & Deploying #PH-REV-128...${NC}"
flutter analyze lib/web_live_sync/

# Flush memory
pkill -f "analysis_server" 2>/dev/null || true
pkill -f "dart_language_server" 2>/dev/null || true
sync
echo 3 | sudo tee /proc/sys/vm/drop_caches 2>/dev/null || true

flutter build web -t lib/web_live_sync/web_main.dart --release --base-href "/" --pwa-strategy=none --no-tree-shake-icons --dart2js-optimization=O1

npx wrangler pages deploy build/web --project-name=pharoah-erp --commit-dirty=true

git add .
git commit -m "Deploy Live Revision #PH-REV-128 with Silent Auto-Sync Engine" || true
git push origin main || true

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${GREEN}  🎉 DEPLOYED SUCCESSFULLY: https://pharoah-erp.pages.dev${NC}"
echo -e "${BLUE}====================================================${NC}"
