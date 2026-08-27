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
    tryAutoLogin();
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

    medicines = (decodeJson('meds.json') as List?)?.map((e) => Medicine.fromMap(e)).toList() ?? [];
    parties = (decodeJson('parts.json') as List?)?.map((e) => Party.fromMap(e)).toList() ?? [Party(id: 'cash', name: "CASH", group: "Cash in Hand")];
    sales = (decodeJson('sales.json') as List?)?.map((e) => Sale.fromMap(e)).toList() ?? [];
    purchases = (decodeJson('purc.json') as List?)?.map((e) => Purchase.fromMap(e)).toList() ?? [];
    vouchers = (decodeJson('vouc.json') as List?)?.map((e) => Voucher.fromMap(e)).toList() ?? [];
    saleChallans = (decodeJson('s_challan.json') as List?)?.map((e) => SaleChallan.fromMap(e)).toList() ?? [];
    purchaseChallans = (decodeJson('p_challan.json') as List?)?.map((e) => PurchaseChallan.fromMap(e)).toList() ?? [];
    saleReturns = (decodeJson('s_return.json') as List?)?.map((e) => SaleReturn.fromMap(e)).toList() ?? [];
    purchaseReturns = (decodeJson('p_return.json') as List?)?.map((e) => PurchaseReturn.fromMap(e)).toList() ?? [];
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

  // ===========================================================================
  // ⚡ 2-WAY CLOUD PUSH: Web Updates Ko Cloud Drive Par Save Karna
  // ===========================================================================
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
    pushUpdatedDataToCloud(); // Sync to Google Drive
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
    pushUpdatedDataToCloud();
  }

  String getOrCreateCompany(String name) {
    try {
      return companies.firstWhere((c) => c.name.toUpperCase() == name.trim().toUpperCase()).id;
    } catch (_) {
      String id = "CP-${1000 + companies.length + 1}";
      companies.add(Company(id: id, name: name.trim().toUpperCase()));
      pushUpdatedDataToCloud();
      return id;
    }
  }

  String getOrCreateSalt(String name) {
    try {
      return salts.firstWhere((s) => s.name.toUpperCase() == name.trim().toUpperCase()).id;
    } catch (_) {
      String id = "SL-${1000 + salts.length + 1}";
      salts.add(Salt(id: id, name: name.trim().toUpperCase()));
      pushUpdatedDataToCloud();
      return id;
    }
  }

  void addParty(Party newParty) {
    parties.add(newParty);
    notifyListeners();
    pushUpdatedDataToCloud();
  }

  void updateParty(Party updatedParty) {
    int idx = parties.indexWhere((p) => p.id == updatedParty.id);
    if (idx != -1) {
      parties[idx] = updatedParty;
      notifyListeners();
      pushUpdatedDataToCloud();
    }
  }

  void deleteParty(String partyId) {
    parties.removeWhere((p) => p.id == partyId);
    notifyListeners();
    pushUpdatedDataToCloud();
  }

  void addMedicine(Medicine newMed) {
    medicines.add(newMed);
    if (!batchHistory.containsKey(newMed.identityKey)) {
      batchHistory[newMed.identityKey] = [];
    }
    notifyListeners();
    pushUpdatedDataToCloud();
  }

  void updateMedicine(Medicine updatedMed) {
    int idx = medicines.indexWhere((m) => m.id == updatedMed.id);
    if (idx != -1) {
      medicines[idx] = updatedMed;
      notifyListeners();
      pushUpdatedDataToCloud();
    }
  }

  void deleteMedicine(String medId) {
    medicines.removeWhere((item) => item.id == medId);
    notifyListeners();
    pushUpdatedDataToCloud();
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
