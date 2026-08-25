import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'drive_sync_service.dart';

class PharoahWebManager with ChangeNotifier {
  bool isLoading = true;
  bool isLiveActive = false;
  String errorMessage = "";
  
  String companyName = "";
  String companyId = "";
  String financialYear = "";
  Map<String, dynamic> companyProfile = {};
  
  List<dynamic> sales = [];
  List<dynamic> medicines = [];
  List<dynamic> parties = [];

  // Google Drive se cloud data verify aur fetch karna
  Future<void> checkCloudHandshake() async {
    isLoading = true;
    errorMessage = "";
    notifyListeners();

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
            companyProfile = jsonDecode(files['profile.json']);
            companyName = companyProfile['name'] ?? "PHAROAH STORE";
            companyId = companyProfile['id'] ?? "";
          } else {
            companyName = "PHAROAH STORE";
          }
          financialYear = "2026-27";

          if (files.containsKey('sales.json')) sales = jsonDecode(files['sales.json']);
          if (files.containsKey('meds.json')) medicines = jsonDecode(files['meds.json']);
          if (files.containsKey('parts.json')) parties = jsonDecode(files['parts.json']);

          isLiveActive = true;
          isLoading = false;
          notifyListeners();
          return;
        }
      }

      isLiveActive = false;
      errorMessage = "No active company broadcast found. Please turn ON 'Live Web' in your Pharoah Mobile App Settings.";
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLiveActive = false;
      errorMessage = "Cloud connection error. Check internet or Mobile App sync status.";
      isLoading = false;
      notifyListeners();
    }
  }
}
