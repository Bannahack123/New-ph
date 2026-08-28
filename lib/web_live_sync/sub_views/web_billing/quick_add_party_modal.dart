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
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5),
              _ipadInput("FIRM / CUSTOMER NAME *", nameC, Icons.business, isCaps: true),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _ipadDropdown(
                      "ACCOUNT GROUP *",
                      selectedGroup,
                      accountGroups.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      (v) => setState(() => selectedGroup = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ipadDropdown(
                      "STATE (FOR GST)",
                      states.contains(selectedState) ? selectedState : "Rajasthan",
                      states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      (v) => setState(() => selectedState = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _ipadInput("MOBILE NUMBER", phoneC, Icons.phone, isPhone: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _ipadInput("EMAIL ID", emailC, Icons.email)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _ipadInput("GSTIN NUMBER", gstC, Icons.receipt_long, isCaps: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _ipadInput("PAN (AUTO FROM GST)", panC, Icons.badge_outlined, isCaps: true)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _ipadInput("DRUG LICENSE (DL)", dlC, Icons.medical_services, isCaps: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _ipadInput("DL EXPIRY", dlExpC, Icons.event_busy, isCaps: true)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _ipadInput("CITY", cityC, Icons.location_city, isCaps: true)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ipadDropdown(
                      "PRICING LEVEL",
                      selectedPriceLevel,
                      ["A", "B", "C"].map((p) => DropdownMenuItem(value: p, child: Text("Rate $p"))).toList(),
                      (v) => setState(() => selectedPriceLevel = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _ipadInput("OFFICE / SHOP ADDRESS", addressC, Icons.location_on),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _ipadInput("OPENING BALANCE ₹", opBalC, Icons.account_balance_wallet, isNum: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _ipadInput("CREDIT LIMIT ₹", creditLimitC, Icons.speed, isNum: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _ipadInput("CREDIT DAYS", creditDaysC, Icons.timer, isNum: true)),
                ],
              ),
              if (activeSeries.isNotEmpty) ...[
                const SizedBox(height: 14),
                _ipadDropdown(
                  "DEFAULT BILLING SERIES PREFERENCE",
                  selectedSeriesId.isEmpty ? null : selectedSeriesId,
                  activeSeries.map((s) => DropdownMenuItem(value: s.id, child: Text("${s.name} (${s.prefix})"))).toList(),
                  (v) => setState(() => selectedSeriesId = v ?? ""),
                  hint: "Select Default Series (Optional)",
                ),
              ],
              const SizedBox(height: 10),
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _saveParty,
          child: const Text("SAVE & SELECT CUSTOMER", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _ipadInput(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    bool isNum = false,
    bool isPhone = false,
    bool isCaps = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        const SizedBox(height: 5),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF38BDF8), size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: ctrl,
                  keyboardType: isPhone ? TextInputType.phone : (isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text),
                  textCapitalization: isCaps ? TextCapitalization.characters : TextCapitalization.none,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _ipadDropdown<T>(
    String label,
    T? value,
    List<DropdownMenuItem<T>> items,
    ValueChanged<T?> onChanged, {
    String hint = "",
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        const SizedBox(height: 5),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              items: items,
              onChanged: onChanged,
              hint: hint.isNotEmpty ? Text(hint, style: const TextStyle(color: Colors.white38, fontSize: 11)) : null,
            ),
          ),
        ),
      ],
    );
  }
}
