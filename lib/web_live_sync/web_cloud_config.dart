class WebCloudConfig {
  static const String webPortalUrl = "https://pharoah-erp.pages.dev";
  static const String cloudRelayEndpoint = "https://script.google.com/macros/s/AKfycbwWnfrBEGlf9yp_aD08_UQtNXxINmtJVNsCusc70-yBtr8otvAsUBNbzJw5yCiCg-C7/exec";
  static const String actionPushStore = "PUSH_STORE_DATA";
  static const String actionPullStore = "PULL_STORE_DATA";
  static const String actionVerifyLogin = "VERIFY_STORE_LOGIN";
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Map<String, String> standardHeaders = {
    "Content-Type": "text/plain;charset=utf-8",
  };
}
