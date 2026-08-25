import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pharoah_web_manager.dart';

class WebPortalGateway extends StatefulWidget {
  const WebPortalGateway({super.key});

  @override
  State<WebPortalGateway> createState() => _WebPortalGatewayState();
}

class _WebPortalGatewayState extends State<WebPortalGateway> {
  final emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final webPh = Provider.of<PharoahWebManager>(context);

    // 1. LOADING SCREEN
    if (webPh.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.cyanAccent),
              SizedBox(height: 20),
              Text("Connecting to Google Drive Cloud...", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    // 2. SCENARIO 1: SIGN IN WITH GOOGLE LANDING PAGE (AUTHENTICATION FIRST)
    if (!webPh.isAuthenticated) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: 480,
              padding: const EdgeInsets.all(35),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.3), width: 1.5),
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 25)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: Colors.cyanAccent.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.language_rounded, size: 50, color: Colors.cyanAccent),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "PHAROAH ERP WEB",
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Sign in with your Google account to access your live store",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 30),

                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: "Your Google Account Email",
                      labelStyle: const TextStyle(color: Colors.white54),
                      hintText: "owner@gmail.com",
                      hintStyle: const TextStyle(color: Colors.white24),
                      prefixIcon: const Icon(Icons.account_circle_outlined, color: Colors.cyanAccent),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Error Message
                  if (webPh.errorMessage.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.redAccent.withOpacity(0.3))),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                          const SizedBox(width: 10),
                          Expanded(child: Text(webPh.errorMessage, style: const TextStyle(color: Colors.redAccent, fontSize: 11))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // SIGN IN WITH GOOGLE BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        String email = emailController.text.trim();
                        if (email.isEmpty) email = "default@gmail.com";
                        webPh.loginAndConnectDrive(email);
                      },
                      icon: const Icon(Icons.login_rounded, size: 20),
                      label: const Text("SIGN IN WITH GOOGLE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Note: Make sure 'Live Web' switch is ON in Mobile App Settings.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 3. SCENARIO 2: SUCCESS DASHBOARD (WELCOME TO PHAROAH ERP)
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("PHAROAH WEB WORKSTATION", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
        backgroundColor: const Color(0xFF1E1B4B),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.greenAccent),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                SizedBox(width: 6),
                Text("GOOGLE DRIVE LIVE", style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: "Logout",
            onPressed: () => webPh.logout(),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 650,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E1B4B), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.stars_rounded, size: 70, color: Colors.cyanAccent),
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      "Welcome to Pharoah ERP",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Your Real-Time Cloud Workstation is Active & Synced.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 25),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 15),
                    if (webPh.companyName.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.storefront_rounded, size: 18, color: Colors.cyanAccent),
                          const SizedBox(width: 8),
                          Text(
                            webPh.companyName.toUpperCase(),
                            style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
