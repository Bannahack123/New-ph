import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../pharoah_manager.dart';

class DriveSyncService {
  static const String defaultEndpoint = "https://script.google.com/home/projects/1a0SQ7IB7ICGuoULjKCoPzwgCMI9xSgRrGhkmPb08LYZ0K9hDz6cF7xRV/edit%20https://accounts.google.com/signin/oauth/v2/consentsummary?as=S-46525969%3A1787736666908096&authuser=1&client_id=1072944905499-vm2v2i5dvn0a0d2o4ca36i1vge8cvbn0.apps.googleusercontent.com&flowName=GeneralOAuthFlow&part=AJi8hAOT1xFN_y1Bgclp7EFI298Xzc039W02vNcaNl4J3VSjkiDsSQCTGeuhbQlfxDXlADVzYlCgcgSZfX-QJkjo60L9y7PacHnkEnWjXAmLw7R7hTsIPR1-0sgtzPD2kTEUkylafCy0xu4_CJ_9n4ln7abdppxR0sMC59RJHh24x0qpROwMH66on1Lxsl2qYIG0ua6oKAKa82AwsFh7tFksSTqEoWV8L3kxXtKvq4lmd6cIk9569pOKZymlDSCaqJ58VOea9IlEUd02bazhvBqUMC_fr0czeOm_gE--wZ_Vrut6lyovSMY5GZWCI6uzIZkWUVGJx72aLpwlKMmMsN2NhxKVtNkNC8TXl3CFZRnsTeo8I-q6u-CmZj7EGEHw5BuCVhsTJI3KY1um5Nv0uzlUqrqHzeTTVIowzFFw8tpJhALh06-EkkoCdSRQJhMmUBO_6U9EHrIsJ46xZbfjHJH9raski_TaqQ_Sky4SEw4ds-FYTSxE26t__Ro_8uBy-DxHZc_FYvJ5FqBNmHMpjOrh8KMCURXp1max9A3bwQKouNH95I7xwOtDo6IBOC8gWRkgcgKmqVdrmYkSgovwOotFVWLn1RuhUmMptj4ARH48xIhC7o9ytjyOqWURzyj1qrJWvG1cqwk8Hk8e_JJBTwO1WHg6-mLPu7N8d5BCJgmRczJ4RFgnk6VS3zoSYj8PvvSQrfO0gRk4BSz1ILzZFNouiKk6FSlEvfGu89o5chB21vQTiA8PgXHQM-SXlXj2V-F0PfZiQFoUcXwL6fG6iDbAprOPn44dj51YAW2-VFdtQlY-6VZpRT4KDxwX872-um0hE2tNIiudhZFb0ubzDXapMeMqdM1TST_vgoaDmJ--BBJr1XrSzdp_7OBZ_RHxHXaHaKMcoAhKCP_FSU8KMGSoeb28sTeMXcXY9qxCsIYnqUq9AO2enHAkYeCdl_VzH4-bLd53vIcTDTk4YYrfBDm9zMXt_tLGpYhfM0EyrpEDuPeVjDQUAgIZpsSSNeB5CFzSK4pLREgqF3Z9t6QvBjlqBYZBEhsKMA5YwIxYeh_4cxjDPx2Z2H6M8fRT3l2VupVdlLHa76QC9_HCy15dlvabJuHBskuIwc5SjBrcAO3psxxFgEOvc3P5zmUjJ9MIfJrdlnh852bOilgIf-vidpo6OzVaQnQ41rCbwGNfAyv6EfEKQGgYLyW1D_hQLuBv7MbUF1baH2KB9k0pe13gLJBjCJwnYjiXBydYO4fgikhC7pXEh0IiX9TXOF6iQasmdmckyLZTJSq3a6h4HetGN8ewi0INdoEqqz8kvPP3wmDmZ3oZCF9lsNGNHR2Nh_zg_X9VROY8oEMrjoHWsnIjStUH43r3L67YYmS9ln0gJ7iyetTFW7p2FdpW336R9vH0cUKkg9BVflToM8qIuT4wq4TRzoFFWyLKlxJ1YmZKeDilX6oivxz0zzG4N52GWdylvg6kQqHrFQi1yZiWA_aihGHNpmjkV0XB5w&rapt=AEjHL4PGp4Ly0XNgUM68TGLHaj-HF3Mjfto0uYDGGEOxPWeoxYmco3ZGO-x9SYXKmvlZ-jL-YL9uWYZaceCoL_OwC9A377szSltaRbG0SSLivAngU6xXESk&xsrf=AGiTF92Q0drLWFMwlZ0GghTVYCux%3A1787736672188%20https://accounts.google.com/signin/oauth/v2/consentsummary?as=S-46525969%3A1787736666908096&authuser=1&client_id=1072944905499-vm2v2i5dvn0a0d2o4ca36i1vge8cvbn0.apps.googleusercontent.com&flowName=GeneralOAuthFlow&part=AJi8hAOT1xFN_y1Bgclp7EFI298Xzc039W02vNcaNl4J3VSjkiDsSQCTGeuhbQlfxDXlADVzYlCgcgSZfX-QJkjo60L9y7PacHnkEnWjXAmLw7R7hTsIPR1-0sgtzPD2kTEUkylafCy0xu4_CJ_9n4ln7abdppxR0sMC59RJHh24x0qpROwMH66on1Lxsl2qYIG0ua6oKAKa82AwsFh7tFksSTqEoWV8L3kxXtKvq4lmd6cIk9569pOKZymlDSCaqJ58VOea9IlEUd02bazhvBqUMC_fr0czeOm_gE--wZ_Vrut6lyovSMY5GZWCI6uzIZkWUVGJx72aLpwlKMmMsN2NhxKVtNkNC8TXl3CFZRnsTeo8I-q6u-CmZj7EGEHw5BuCVhsTJI3KY1um5Nv0uzlUqrqHzeTTVIowzFFw8tpJhALh06-EkkoCdSRQJhMmUBO_6U9EHrIsJ46xZbfjHJH9raski_TaqQ_Sky4SEw4ds-FYTSxE26t__Ro_8uBy-DxHZc_FYvJ5FqBNmHMpjOrh8KMCURXp1max9A3bwQKouNH95I7xwOtDo6IBOC8gWRkgcgKmqVdrmYkSgovwOotFVWLn1RuhUmMptj4ARH48xIhC7o9ytjyOqWURzyj1qrJWvG1cqwk8Hk8e_JJBTwO1WHg6-mLPu7N8d5BCJgmRczJ4RFgnk6VS3zoSYj8PvvSQrfO0gRk4BSz1ILzZFNouiKk6FSlEvfGu89o5chB21vQTiA8PgXHQM-SXlXj2V-F0PfZiQFoUcXwL6fG6iDbAprOPn44dj51YAW2-VFdtQlY-6VZpRT4KDxwX872-um0hE2tNIiudhZFb0ubzDXapMeMqdM1TST_vgoaDmJ--BBJr1XrSzdp_7OBZ_RHxHXaHaKMcoAhKCP_FSU8KMGSoeb28sTeMXcXY9qxCsIYnqUq9AO2enHAkYeCdl_VzH4-bLd53vIcTDTk4YYrfBDm9zMXt_tLGpYhfM0EyrpEDuPeVjDQUAgIZpsSSNeB5CFzSK4pLREgqF3Z9t6QvBjlqBYZBEhsKMA5YwIxYeh_4cxjDPx2Z2H6M8fRT3l2VupVdlLHa76QC9_HCy15dlvabJuHBskuIwc5SjBrcAO3psxxFgEOvc3P5zmUjJ9MIfJrdlnh852bOilgIf-vidpo6OzVaQnQ41rCbwGNfAyv6EfEKQGgYLyW1D_hQLuBv7MbUF1baH2KB9k0pe13gLJBjCJwnYjiXBydYO4fgikhC7pXEh0IiX9TXOF6iQasmdmckyLZTJSq3a6h4HetGN8ewi0INdoEqqz8kvPP3wmDmZ3oZCF9lsNGNHR2Nh_zg_X9VROY8oEMrjoHWsnIjStUH43r3L67YYmS9ln0gJ7iyetTFW7p2FdpW336R9vH0cUKkg9BVflToM8qIuT4wq4TRzoFFWyLKlxJ1YmZKeDilX6oivxz0zzG4N52GWdylvg6kQqHrFQi1yZiWA_aihGHNpmjkV0XB5w&rapt=AEjHL4PGp4Ly0XNgUM68TGLHaj-HF3Mjfto0uYDGGEOxPWeoxYmco3ZGO-x9SYXKmvlZ-jL-YL9uWYZaceCoL_OwC9A377szSltaRbG0SSLivAngU6xXESk&xsrf=AGiTF92Q0drLWFMwlZ0GghTVYCux%3A1787736672188";

  static Future<bool> pushDataToCloud(PharoahManager ph) async {
    try {
      if (ph.activeCompany == null || ph.currentFY.isEmpty) return false;

      final workingDir = await ph.getWorkingPath();
      if (workingDir.isEmpty) return false;

      List<String> fileNames = [
        'meds.json', 'parts.json', 'sales.json', 'purc.json',
        'bats.json', 'vouc.json', 's_challan.json', 'p_challan.json',
        's_return.json', 'p_return.json', 'banks.json', 'config.json',
        'series.json', 'shortage.json', 'routs.json', 'comps.json'
      ];

      Map<String, String> filesPayload = {};

      for (var name in fileNames) {
        final f = File('$workingDir/$name');
        if (await f.exists()) {
          filesPayload[name] = await f.readAsString();
        }
      }

      final payload = {
        "action": "PUSH_DATA",
        "companyId": ph.activeCompany!.id,
        "fy": ph.currentFY,
        "registryProfile": ph.activeCompany!.toMap(),
        "files": filesPayload,
      };

      final response = await http.post(
        Uri.parse(defaultEndpoint),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_cloud_sync_time', DateTime.now().toIso8601String());
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Drive Sync Push Error: $e");
      return false;
    }
  }

  static Future<String> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    String? timeStr = prefs.getString('last_cloud_sync_time');
    if (timeStr == null) return "Never";
    try {
      DateTime dt = DateTime.parse(timeStr);
      return "${dt.day}/${dt.month}/${dt.year} at ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return "Never";
    }
  }
}
