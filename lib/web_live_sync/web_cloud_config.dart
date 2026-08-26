class WebCloudConfig {
  /// 1. Official Web Portal URL (Cloudflare Pages)
  static const String webPortalUrl = "https://pharoah-erp.pages.dev";

  /// 2. Zero-Cost Serverless Relay API Endpoint (100% Free Tier)
  static const String cloudRelayEndpoint =
      "https://script.google.com/macros/s/AKfycbyKFFt9WK-xB1qLRTD7M-b4jSlpCBoBfJ18x8FUP1wFBzbQ-dQgyjm1qPfv12kQmaSl/exec";

  /// 3. Action Protocol Constants (Store Token Based)
  static const String actionPushStore = "PUSH_STORE_DATA";
  static const String actionPullStore = "PULL_STORE_DATA";
  static const String actionVerifyLogin = "VERIFY_STORE_LOGIN";

  /// 4. Network Timeouts & Headers
  static const Duration networkTimeout = Duration(seconds: 25);
  static const Map<String, String> standardHeaders = {
    "Content-Type": "application/json",
    "Accept": "application/json",
  };
}
