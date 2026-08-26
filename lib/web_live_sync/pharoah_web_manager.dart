import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'drive_sync_service.dart';

class PharoahWebManager with ChangeNotifier {
  bool isLoading = false;
  bool isLiveActive = true;
  String companyName = "PHAROAH STORE";
  String financialYear = "2026-27";
  Map<String, dynamic> companyProfile = {};
  
  List<dynamic> sales = [];
  List<dynamic> medicines = [];
  List<dynamic> parties = [];

  Future<void> checkCloudHandshake() async {
    isLoading = true;
    notifyListeners();

    try {
      final uri = Uri.parse("${DriveSyncService.defaultEndpoint}?action=PULL_DATA&t=${DateTime.now().millisecondsSinceEpoch}");
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        if (res['status'] == "SUCCESS") {
          companyName = res['companyName'] ?? "PHAROAH STORE";
          var files = res['data'] ?? {};

          if (files.containsKey('sales.json')) sales = jsonDecode(files['sales.json']);
          if (files.containsKey('meds.json')) medicines = jsonDecode(files['meds.json']);
          if (files.containsKey('parts.json')) parties = jsonDecode(files['parts.json']);

          isLiveActive = true;
          isLoading = false;
          notifyListeners();
          return;
        }
      }
    } catch (_) {}

    isLiveActive = true;
    isLoading = false;
    notifyListeners();
  }
}
