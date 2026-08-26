import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pharoah_web_manager.dart';

class WebPortalGateway extends StatefulWidget {
  const WebPortalGateway({super.key});

  @override
  State<WebPortalGateway> createState() => _WebPortalGatewayState();
}

class _WebPortalGatewayState extends State<WebPortalGateway> {
  final storeKeyC = TextEditingController();
  final usernameC = TextEditingController();
  final passwordC = TextEditingController();
  bool isObscured = true;

  @override
  void dispose() {
    storeKeyC.dispose();
    usernameC.dispose();
    passwordC.dispose();
    super.dispose();
  }

  void _handleLogin(PharoahWebManager webPh) async {
    final token = storeKeyC.text.trim();
    final user = usernameC.text.trim();
    final pass = passwordC.text.trim();

    if (token.isEmpty || user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All 3 fields (Store Key, User, Password) are required!"), backgroundColor: Colors.orange),
      );
      return;
    }

    await webPh.loginWithStoreKey(
      storeToken: token,
      username: user,
      password: pass,
    );
  }

  @override
  Widget build(BuildContext context) {
    final webPh = Provider.of<PharoahWebManager>(context);

    if (webPh.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.cyanAccent),
              SizedBox(height: 25),
              Text(
                "Connecting to Store Cloud Workstation...",
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ],
          ),
        ),
      );
    }

    if (!webPh.isAuthenticated) {
      return _buildLoginView(webPh);
    }

    return _buildWorkstationDashboard(webPh);
  }

  // --- 1. CLEAN 3-FIELD LOGIN VIEW ---
  Widget _buildLoginView(PharoahWebManager webPh) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 460,
            padding: const EdgeInsets.all(35),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.3), width: 1.5),
              boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 25, offset: Offset(0, 10))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: Colors.cyanAccent.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.storefront_rounded, size: 50, color: Colors.cyanAccent),
                ),
                const SizedBox(height: 20),
                const Text(
                  "PHAROAH WEB WORKSTATION",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Access your live store inventory, billing & ledger",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 25),

                if (webPh.errorMessage.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text(webPh.errorMessage, style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                ],

                _buildField(storeKeyC, "STORE ACCESS KEY", Icons.vpn_key_rounded, hint: "e.g. PH-LIVE-9842-X7K2", isCaps: true),
                const SizedBox(height: 15),
                _buildField(usernameC, "USERNAME", Icons.person_rounded, hint: "e.g. admin"),
                const SizedBox(height: 15),
                _buildField(
                  passwordC, 
                  "PASSWORD", 
                  Icons.lock_rounded, 
                  isPass: true,
                  isObscured: isObscured,
                  onToggleObscure: () => setState(() => isObscured = !isObscured),
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () => _handleLogin(webPh),
                    icon: const Icon(Icons.login_rounded, size: 20),
                    label: const Text("LOGIN TO WORKSTATION", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.8)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Powered by Pharoah ERP • Secure Cloud Relay Engine",
                  style: TextStyle(color: Colors.white24, fontSize: 9),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {bool isPass = false, bool isCaps = false, String hint = "", bool isObscured = false, VoidCallback? onToggleObscure}) {
    return TextField(
      controller: ctrl,
      obscureText: isPass ? isObscured : false,
      textCapitalization: isCaps ? TextCapitalization.characters : TextCapitalization.none,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
        prefixIcon: Icon(icon, color: Colors.cyanAccent, size: 20),
        suffixIcon: isPass ? IconButton(icon: Icon(isObscured ? Icons.visibility_off : Icons.visibility, color: Colors.white54, size: 18), onPressed: onToggleObscure) : null,
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      ),
    );
  }

  // --- 2. WORKSTATION DASHBOARD ---
  Widget _buildWorkstationDashboard(PharoahWebManager webPh) {
    double totalSalesAmt = 0;
    for (var s in webPh.sales) {
      totalSalesAmt += (s['totalAmount'] as num? ?? 0).toDouble();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B4B),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(webPh.companyName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white)),
            Text("Store Key: ${webPh.activeStoreToken} • FY: ${webPh.financialYear}", style: const TextStyle(fontSize: 10, color: Colors.cyanAccent)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: Colors.cyanAccent),
            tooltip: "Refresh Live Data",
            onPressed: () => webPh.refreshStoreData(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: "Sign Out",
            onPressed: () => webPh.signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Metrics
            Row(
              children: [
                Expanded(child: _kpiCard("TOTAL SALES", "₹${totalSalesAmt.toStringAsFixed(0)}", "${webPh.sales.length} Bills", Icons.trending_up_rounded, Colors.greenAccent)),
                const SizedBox(width: 15),
                Expanded(child: _kpiCard("MEDICINES", "${webPh.medicines.length}", "Master Catalog", Icons.medication_rounded, Colors.cyanAccent)),
                const SizedBox(width: 15),
                Expanded(child: _kpiCard("PARTIES", "${webPh.parties.length}", "Ledgers", Icons.people_alt_rounded, Colors.orangeAccent)),
                const SizedBox(width: 15),
                Expanded(child: _kpiCard("PURCHASES", "${webPh.purchases.length}", "Inward Bills", Icons.shopping_bag_rounded, Colors.purpleAccent)),
              ],
            ),
            const SizedBox(height: 30),

            // Live Sales Feed
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long_rounded, color: Colors.cyanAccent, size: 20),
                      const SizedBox(width: 10),
                      const Text("RECENT INVOICES (LIVE CLOUD FEED)", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      const Spacer(),
                      Text("${webPh.sales.length} Records", style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 25),

                  if (webPh.sales.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(30), child: Text("No sales records found in this store.", style: TextStyle(color: Colors.white38, fontSize: 12))))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: webPh.sales.length > 15 ? 15 : webPh.sales.length,
                      itemBuilder: (c, i) {
                        final s = webPh.sales.reversed.toList()[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            dense: true,
                            leading: const CircleAvatar(radius: 14, backgroundColor: Colors.green, child: Text("S", style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold))),
                            title: Text(s['partyName'] ?? 'CASH', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            subtitle: Text("Inv #${s['billNo'] ?? 'N/A'} • ${s['date'] != null ? s['date'].toString().substring(0, 10) : ''}", style: const TextStyle(color: Colors.white54, fontSize: 10)),
                            trailing: Text("₹${(s['totalAmount'] as num? ?? 0).toStringAsFixed(2)}", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard(String title, String value, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 9)),
        ],
      ),
    );
  }
}
