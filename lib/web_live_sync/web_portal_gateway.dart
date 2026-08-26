import 'package:flutter/material.dart';

class WebPortalGateway extends StatelessWidget {
  const WebPortalGateway({super.key});

  @override
  Widget build(BuildContext context) {
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
                Text("LIVE CLOUD ACTIVE", style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
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
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.storefront_rounded, size: 18, color: Colors.cyanAccent),
                        SizedBox(width: 8),
                        Text(
                          "PHAROAH STORE",
                          style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 14),
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
