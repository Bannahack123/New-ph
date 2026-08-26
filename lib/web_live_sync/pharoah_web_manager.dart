import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'web_sync_engine.dart';

class PharoahWebManager with ChangeNotifier {
  bool isLoading = false;
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

  // Live Business Records in Web Memory
  List<dynamic> sales = [];
  List<dynamic> medicines = [];
  List<dynamic> parties = [];
  List<dynamic> purchases = [];
  List<dynamic> vouchers = [];
  List<dynamic> saleChallans = [];
  List<dynamic> purchaseChallans = [];
  List<dynamic> saleReturns = [];
  List<dynamic> purchaseReturns = [];

  /// 1. Login with Store Key, Username & Password (Zero Google Auth Popups)
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

      isAuthenticated = true;
      isLoading = false;
      successMessage = "Store workstation connected successfully!";
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

  /// 2. Refresh store data live from cloud relay
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

  /// 3. Helper to parse JSON files into live lists
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
  }

  /// 4. Disconnect and Logout from Web Workstation
  void signOut() {
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
    notifyListeners();
  }
}
