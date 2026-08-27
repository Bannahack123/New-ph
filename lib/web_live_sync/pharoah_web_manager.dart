import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models.dart';
import 'web_sync_engine.dart';

class PharoahWebManager with ChangeNotifier {
  bool isLoading = false;
  bool isAutoLoggingIn = true;
  bool isAuthenticated = false;
  String errorMessage = "";
  String successMessage = "";

  // Store & Session Metadata
  String activeStoreToken = "";
  String activeUsername = "";
  String activePassword = "";
  String companyName = "PHAROAH STORE";
  String financialYear = "2026-27";
  Map<String, dynamic> companyProfile = {};
  Map<String, dynamic> appConfig = {};

  // Live Business Records
  List<dynamic> sales = [];
  List<dynamic> medicines = [];
  List<dynamic> parties = [];
  List<dynamic> purchases = [];
  List<dynamic> vouchers = [];
  List<dynamic> saleChallans = [];
  List<dynamic> purchaseChallans = [];
  List<dynamic> saleReturns = [];
  List<dynamic> purchaseReturns = [];
  List<dynamic> companies = [];
  List<dynamic> salts = [];
  List<dynamic> routes = [];
  List<dynamic> banks = [];
  List<dynamic> numberingSeries = [];
  Map<String, List<BatchInfo>> batchHistory = {};

  PharoahWebManager() {
    tryAutoLogin();
  }

  /// 1. Silent Auto-Login on Page Reload / Re-open
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
          activeStoreToken = savedToken.trim().toUpperCase();
          activeUsername = savedUser.trim();
          activePassword = savedPass.trim();
          companyName = result['companyName'] ?? 'STORE WORKSTATION';
          financialYear = result['fy'] ?? '2026-27';
          companyProfile = result['profile'] ?? {};

          final Map<String, dynamic> files = result['files'] ?? {};
          _parseDownloadedFiles(files);

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

  /// 2. Login with Store Key, Username & Password
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
      activeStoreToken = storeToken.trim().toUpperCase();
      activeUsername = username.trim();
      activePassword = password.trim();
      companyName = result['companyName'] ?? 'STORE WORKSTATION';
      financialYear = result['fy'] ?? '2026-27';
      companyProfile = result['profile'] ?? {};

      final Map<String, dynamic> files = result['files'] ?? {};
      _parseDownloadedFiles(files);

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

  /// 3. Add newly created sale and update memory
  void addSaleAndSync(Map<String, dynamic> newSale) {
    sales.add(newSale);
    if (newSale['items'] != null && newSale['items'] is List) {
      for (var it in (newSale['items'] as List)) {
        int idx = medicines.indexWhere((m) => (m['id'] == it['medicineID'] || m['name'] == it['name']));
        if (idx != -1) {
          double curStock = (medicines[idx]['stock'] as num? ?? 0).toDouble();
          double decr = (it['qty'] as num? ?? 0).toDouble() + (it['freeQty'] as num? ?? 0).toDouble();
          medicines[idx]['stock'] = curStock - decr;
        }

        // Decrement in batch history
        String medKey = (it['medicineID'] ?? '').toString();
        String batchNo = (it['batch'] ?? '').toString().trim().toUpperCase();
        if (batchHistory.containsKey(medKey)) {
          int bIdx = batchHistory[medKey]!.indexWhere((b) => b.batch.trim().toUpperCase() == batchNo);
          if (bIdx != -1) {
            double decr = (it['qty'] as num? ?? 0).toDouble() + (it['freeQty'] as num? ?? 0).toDouble();
            batchHistory[medKey]![bIdx].qty -= decr;
          }
        }
      }
    }
    notifyListeners();
  }

  /// 4. Quick-Add Party (Customer / Supplier)
  void addParty(Map<String, dynamic> newParty) {
    parties.add(newParty);
    notifyListeners();
  }

  /// 5. Quick-Add Medicine / Product
  void addMedicine(Map<String, dynamic> newMed) {
    medicines.add(newMed);
    String key = newMed['systemId'] ?? newMed['id'] ?? '';
    if (key.isNotEmpty && !batchHistory.containsKey(key)) {
      batchHistory[key] = [];
    }
    notifyListeners();
  }

  /// 6. Refresh Store Data Live
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
      successMessage = "Data refreshed live!";
    } else {
      errorMessage = result['message'] ?? 'Live Refresh failed.';
    }

    isLoading = false;
    notifyListeners();
  }

  /// 7. Parse All 16 Store JSON Files
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

    sales = decodeJson('sales.json') as List? ?? [];
    medicines = decodeJson('meds.json') as List? ?? [];
    parties = decodeJson('parts.json') as List? ?? [];
    purchases = decodeJson('purc.json') as List? ?? [];
    vouchers = decodeJson('vouc.json') as List? ?? [];
    saleChallans = decodeJson('s_challan.json') as List? ?? [];
    purchaseChallans = decodeJson('p_challan.json') as List? ?? [];
    saleReturns = decodeJson('s_return.json') as List? ?? [];
    purchaseReturns = decodeJson('p_return.json') as List? ?? [];
    companies = decodeJson('comps.json') as List? ?? [];
    salts = decodeJson('salts.json') as List? ?? [];
    routes = decodeJson('routs.json') as List? ?? [];
    banks = decodeJson('banks.json') as List? ?? [];
    numberingSeries = decodeJson('series.json') as List? ?? [];
    appConfig = decodeJson('config.json') as Map<String, dynamic>? ?? {};

    // Parse bats.json into batchHistory map
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

  /// 8. Explicit Sign Out
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('web_auth_logged_in', false);
    await prefs.remove('web_auth_password');

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
    notifyListeners();
  }
}
