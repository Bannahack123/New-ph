class WebCloudConfig {
  /// 1. Official Web Portal URL
  static const String webPortalUrl = "https://pharoah-erp.pages.dev";

  /// 2. Zero-Cost Cloud Relay Endpoint (Google Apps Script Engine)
  static const String cloudRelayEndpoint =
      "https://script.google.com/macros/s/AKfycbyKFFt9WK-xB1qLRTD7M-b4jSlpCBoBfJ18x8FUP1wFBzbQ-dQgyjm1qPfv12kQmaSl/exec";

  /// 3. Action Protocol Constants
  static const String actionPushStore = "PUSH_STORE_DATA";
  static const String actionPullStore = "PULL_STORE_DATA";
  static const String actionVerifyLogin = "VERIFY_STORE_LOGIN";

  /// 4. CORS-Bypassing Headers (text/plain bypasses browser preflight block)
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Map<String, String> standardHeaders = {
    "Content-Type": "text/plain;charset=utf-8",
  };
}
