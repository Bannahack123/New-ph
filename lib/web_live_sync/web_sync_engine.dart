import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'web_cloud_config.dart';

class WebSyncEngine {
  /// 1. Fetch store data and verify credentials from Cloud Relay
  static Future<Map<String, dynamic>> fetchStoreData({
    required String storeToken,
    required String username,
    required String password,
  }) async {
    try {
      final cleanToken = storeToken.trim().toUpperCase();
      final cleanUser = username.trim().toLowerCase();
      final cleanPass = password.trim();

      final payload = {
        "action": WebCloudConfig.actionPullStore,
        "storeToken": cleanToken,
        "username": cleanUser,
        "password": cleanPass,
      };

      final response = await http.post(
        Uri.parse(WebCloudConfig.cloudRelayEndpoint),
        headers: WebCloudConfig.standardHeaders,
        body: jsonEncode(payload),
      ).timeout(WebCloudConfig.networkTimeout);

      if (response.statusCode == 200 || response.statusCode == 302) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        if (result['status'] == 'SUCCESS') {
          return {
            'success': true,
            'companyName': result['companyName'] ?? 'STORE WORKSTATION',
            'fy': result['fy'] ?? '',
            'profile': result['registryProfile'] ?? {},
            'files': result['files'] ?? {},
            'message': 'Store connected successfully!',
          };
        } else {
          return {
            'success': false,
            'message': result['message'] ?? 'Invalid Store Key or Credentials.',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Cloud Relay responded with HTTP ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint("WebSyncEngine Fetch Error: $e");
      return {
        'success': false,
        'message': 'Connection Error: Please check Store Key & internet.',
      };
    }
  }
}
