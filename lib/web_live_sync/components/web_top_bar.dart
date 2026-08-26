import 'package:flutter/material.dart';
import '../pharoah_web_manager.dart';

class WebTopBar extends StatelessWidget implements PreferredSizeWidget {
  final PharoahWebManager webPh;
  final ValueChanged<String>? onSearchChanged;

  const WebTopBar({
    super.key,
    required this.webPh,
    this.onSearchChanged,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A), // Executive Deep Navy Black
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          // Store Icon Badge
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.storefront_rounded, color: Color(0xFF38BDF8), size: 20),
          ),
          const SizedBox(width: 12),

          // Store Name & FY
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                webPh.companyName.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                "Financial Year: ${webPh.financialYear}",
                style: const TextStyle(
                  fontSize: 9.5,
                  color: Color(0xFF38BDF8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 25),

          // Global Search Bar
          Expanded(
            child: Container(
              height: 36,
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: TextField(
                onChanged: onSearchChanged,
                style: const TextStyle(color: Colors.white, fontSize: 11.5),
                decoration: const InputDecoration(
                  hintText: "Search Medicines, Customers, Invoices...",
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 11),
                  prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF38BDF8), size: 16),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 9),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Live Cloud Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
            ),
            child: Row(
              children: const [
                Icon(Icons.circle, color: Colors.greenAccent, size: 7),
                SizedBox(width: 6),
                Text(
                  "LIVE CLOUD",
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Refresh Button
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: Colors.white70, size: 20),
            tooltip: "Refresh Live Data",
            onPressed: () {
              webPh.refreshStoreData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("🔄 Live Cloud Database Refreshed!"),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),

          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
            tooltip: "Sign Out",
            onPressed: () => _confirmSignOut(context),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Colors.white10),
        ),
        title: const Text("Sign Out Workstation?", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text(
          "Are you sure you want to disconnect from this store workstation?",
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("CANCEL", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(c);
              webPh.signOut();
            },
            child: const Text("SIGN OUT", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
