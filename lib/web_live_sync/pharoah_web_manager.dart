import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'drive_sync_service.dart';

class PharoahWebManager with ChangeNotifier {
  bool isLoading = false;
  bool isAuthenticated = false;
  bool isLiveActive = false;
  String errorMessage = "";
  String userEmail = "";
  
  String companyName = "";
  String financialYear = "2026-27";
  Map<String, dynamic> companyProfile = {};

  // Google Login aur Drive Data Pull (CORS Safe GET Request)
  Future<void> loginAndConnectDrive(String email) async {
    isLoading = true;
    errorMessage = "";
    userEmail = email;
    notifyListeners();

    try {
      // Browser me CORS avoid karne ke liye GET request use hoti hai
      final uri = Uri.parse("${DriveSyncService.defaultEndpoint}?action=PULL_DATA&companyId=DEFAULT_COMPANY&fy=$financialYear");
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        if (res['status'] == "SUCCESS" && res['data'] != null && (res['hasData'] == true || res['data'].isNotEmpty)) {
          var files = res['data'];

          if (files.containsKey('profile.json')) {
            companyProfile = jsonDecode(files['profile.json']);
            companyName = companyProfile['name'] ?? "PHAROAH STORE";
          } else {
            companyName = "PHAROAH STORE";
          }

          isLiveActive = true;
          isAuthenticated = true;
          isLoading = false;
          notifyListeners();
          return;
        }
      }

      isLiveActive = false;
      isAuthenticated = false;
      errorMessage = "No active company broadcast found for this account. Please turn ON 'Live Web' in your Pharoah Mobile App and tap 'Sync Now'.";
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLiveActive = false;
      isAuthenticated = false;
      errorMessage = "Connection error. Make sure Google Drive script is deployed with access 'Anyone'.";
      isLoading = false;
      notifyListeners();
    }
  }

  void logout() {
    isAuthenticated = false;
    isLiveActive = false;
    userEmail = "";
    notifyListeners();
  }
}
