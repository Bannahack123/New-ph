// FILE: lib/web_live_sync/sub_views/web_billing/quick_add_party_modal.dart

import 'package:flutter/material.dart';
import '../../web_models.dart';
import '../../pharoah_web_manager.dart';

class QuickAddPartyModal extends StatefulWidget {
  final PharoahWebManager webPh;
  final Function(Party newParty) onPartyCreated;

  const QuickAddPartyModal({
    super.key,
    required this.webPh,
    required this.onPartyCreated,
  });

  @override
  State<QuickAddPartyModal> createState() => _QuickAddPartyModalState();
}

class _QuickAddPartyModalState extends State<QuickAddPartyModal> {
  final nameC = TextEditingController();
  final phoneC = TextEditingController();
  final emailC = TextEditingController();
  final addressC = TextEditingController();
  final cityC = TextEditingController();
  final gstC = TextEditingController();
  final panC = TextEditingController();
  final dlC = TextEditingController();
  final dlExpC = TextEditingController();
  final opBalC = TextEditingController(text: "0.0");
  final creditLimitC = TextEditingController(text: "0.0");
  final creditDaysC = TextEditingController(text: "30");

  String selectedGroup = "Sundry Debtors";
  String selectedState = "Rajasthan";
  String selectedPriceLevel = "A";
  String selectedSeriesId = "";

  final List<String> accountGroups = [
    "Sundry Debtors",
    "Sundry Creditors",
    "Bank Accounts",
    "Cash in Hand",
    "Expenses",
  ];

  final List<String> states = [
    "Andhra Pradesh", "Assam", "Bihar", "Chhattisgarh", "Goa", "Gujarat", "Haryana",
    "Himachal Pradesh", "Jharkhand", "Karnataka", "Kerala", "Madhya Pradesh",
    "Maharashtra", "Manipur", "Meghalaya", "Mizoram", "Nagaland", "Odisha",
    "Punjab", "Rajasthan", "Sikkim", "Tamil Nadu", "Telangana", "Tripura",
    "Uttar Pradesh", "Uttarakhand", "West Bengal", "Delhi",
  ];

  @override
  void initState() {
    super.initState();
    gstC.addListener(() {
      if (gstC.text.length >= 12) {
        String extPan = gstC.text.substring(2, 12).toUpperCase();
        if (panC.text != extPan) {
          panC.text = extPan;
        }
      }
    });
  }

  @override
  void dispose() {
    nameC.dispose();
    phoneC.dispose();
    emailC.dispose();
    addressC.dispose();
    cityC.dispose();
    gstC.dispose();
    panC.dispose();
    dlC.dispose();
    dlExpC.dispose();
    opBalC.dispose();
    creditLimitC.dispose();
    creditDaysC.dispose();
    super.dispose();
  }

  void _saveParty() {
    if (nameC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Firm / Customer Name is required!"), backgroundColor: Colors.orange),
      );
      return;
    }

    final newParty = Party(
      id: 'PARTY-WEB-${DateTime.now().millisecondsSinceEpoch}',
      name: nameC.text.trim().toUpperCase(),
      group: selectedGroup,
      phone: phoneC.text.trim(),
      email: emailC.text.trim().toLowerCase(),
      address: addressC.text.trim(),
      city: cityC.text.trim().toUpperCase(),
      state: selectedState,
      gst: gstC.text.trim().toUpperCase().isEmpty ? 'N/A' : gstC.text.trim().toUpperCase(),
      pan: panC.text.trim().toUpperCase(),
      dl: dlC.text.trim().toUpperCase().isEmpty ? 'N/A' : dlC.text.trim().toUpperCase(),
      dlExp: dlExpC.text.trim(),
      opBal: double.tryParse(opBalC.text) ?? 0.0,
      creditLimit: double.tryParse(creditLimitC.text) ?? 0.0,
      creditDays: int.tryParse(creditDaysC.text) ?? 30,
      priceLevel: selectedPriceLevel,
      defaultSeriesId: selectedSeriesId,
    );

    widget.webPh.addParty(newParty);
    Navigator.pop(context);
    widget.onPartyCreated(newParty);
  }

  @override
  Widget build(BuildContext context) {
    final activeSeries = widget.webPh.numberingSeries.where((s) => s.type == "SALE" && s.isActive).toList();

    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.white12),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0x332563EB),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF38BDF8), size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            "QUICK CREATE CUSTOMER / PARTY",
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _inputField("FIRM / CUSTOMER NAME *", nameC, Icons.business, isCaps: true),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedGroup,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      decoration: _dropdownDecor("ACCOUNT GROUP *"),
                      items: accountGroups.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (v) => setState(() => selectedGroup = v!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: states.contains(selectedState) ? selectedState : "Rajasthan",
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      decoration: _dropdownDecor("STATE (FOR GST)"),
                      items: states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) => setState(() => selectedState = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _inputField("MOBILE NUMBER", phoneC, Icons.phone, isPhone: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _inputField("EMAIL ID", emailC, Icons.email)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _inputField("GSTIN NUMBER", gstC, Icons.receipt_long, isCaps: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _inputField("PAN (AUTO FROM GST)", panC, Icons.badge_outlined, isCaps: true)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _inputField("DRUG LICENSE (DL)", dlC, Icons.medical_services, isCaps: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _inputField("DL EXPIRY", dlExpC, Icons.event_busy, isCaps: true)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _inputField("CITY", cityC, Icons.location_city, isCaps: true)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedPriceLevel,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      decoration: _dropdownDecor("PRICING LEVEL"),
                      items: ["A", "B", "C"].map((p) => DropdownMenuItem(value: p, child: Text("Rate $p"))).toList(),
                      onChanged: (v) => setState(() => selectedPriceLevel = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _inputField("OFFICE / SHOP ADDRESS", addressC, Icons.location_on),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _inputField("OPENING BALANCE ₹", opBalC, Icons.account_balance_wallet, isNum: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _inputField("CREDIT LIMIT ₹", creditLimitC, Icons.speed, isNum: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _inputField("CREDIT DAYS", creditDaysC, Icons.timer, isNum: true)),
                ],
              ),
              if (activeSeries.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedSeriesId.isEmpty ? null : selectedSeriesId,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  decoration: _dropdownDecor("DEFAULT BILLING SERIES PREFERENCE"),
                  items: activeSeries.map((s) => DropdownMenuItem(value: s.id, child: Text("${s.name} (${s.prefix})"))).toList(),
                  onChanged: (v) => setState(() => selectedSeriesId = v ?? ""),
                  hint: const Text("Select Default Series (Optional)", style: TextStyle(color: Colors.white38, fontSize: 11)),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("CANCEL", style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _saveParty,
          child: const Text("SAVE & SELECT CUSTOMER", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _inputField(String label, TextEditingController ctrl, IconData icon, {bool isNum = false, bool isPhone = false, bool isCaps = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isPhone ? TextInputType.phone : (isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text),
      textCapitalization: isCaps ? TextCapitalization.characters : TextCapitalization.none,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 8.5, fontWeight: FontWeight.bold),
        prefixIcon: Icon(icon, color: const Color(0xFF38BDF8), size: 16),
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    );
  }

  InputDecoration _dropdownDecor(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54, fontSize: 8.5, fontWeight: FontWeight.bold),
      filled: true,
      fillColor: Colors.black26,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    );
  }
}
