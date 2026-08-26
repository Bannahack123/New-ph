import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'drive_sync_service.dart';

class PharoahWebManager with ChangeNotifier {
  bool isLoading = false;
  bool isAuthenticated = false;
  bool isLiveActive = true;
  String errorMessage = "";
  String userEmail = "";
  String companyName = "PHAROAH STORE";
  String financialYear = "2026-27";
  Map<String, dynamic> companyProfile = {};
  
  List<dynamic> sales = [];
  List<dynamic> medicines = [];
  List<dynamic> parties = [];

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile', 'https://www.googleapis.com/auth/drive.file'],
  );

  // Web par Real Google Popup Sign-In
  Future<void> signInWithGoogle() async {
    isLoading = true;
    errorMessage = "";
    notifyListeners();

    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        isLoading = false;
        errorMessage = "Google Sign-In was cancelled.";
        notifyListeners();
        return;
      }

      userEmail = account.email;
      
      // Google Drive se data pull karna
      final uri = Uri.parse("${DriveSyncService.defaultEndpoint}?action=PULL_DATA&email=$userEmail&t=${DateTime.now().millisecondsSinceEpoch}");
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        if (res['status'] == "SUCCESS") {
          companyName = res['companyName'] ?? "PHAROAH STORE";
          var files = res['data'] ?? {};

          if (files.containsKey('sales.json')) sales = jsonDecode(files['sales.json']);
          if (files.containsKey('meds.json')) medicines = jsonDecode(files['meds.json']);
          if (files.containsKey('parts.json')) parties = jsonDecode(files['parts.json']);
        }
      }

      isAuthenticated = true;
      isLiveActive = true;
      isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint("Web Google Sign-In Error: $e");
      isLoading = false;
      errorMessage = "Google Authentication Failed: $e";
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    isAuthenticated = false;
    userEmail = "";
    notifyListeners();
  }
}
