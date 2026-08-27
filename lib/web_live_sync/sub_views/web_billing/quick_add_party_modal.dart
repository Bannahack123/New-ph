import 'package:flutter/material.dart';
import '../../pharoah_web_manager.dart';

class QuickAddPartyModal extends StatefulWidget {
  final PharoahWebManager webPh;
  final Function(Map<String, dynamic> newParty) onPartyCreated;

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
  final gstC = TextEditingController();
  final panC = TextEditingController();
  final dlC = TextEditingController();
  final addressC = TextEditingController();
  final cityC = TextEditingController();

  String selectedGroup = "Sundry Debtors";
  String selectedState = "Rajasthan";

  final List<String> states = [
    "Andhra Pradesh", "Assam", "Bihar", "Chhattisgarh", "Goa", "Gujarat", "Haryana",
    "Himachal Pradesh", "Jharkhand", "Karnataka", "Kerala", "Madhya Pradesh",
    "Maharashtra", "Manipur", "Meghalaya", "Mizoram", "Nagaland", "Odisha",
    "Punjab", "Rajasthan", "Sikkim", "Tamil Nadu", "Telangana", "Tripura",
    "Uttar Pradesh", "Uttarakhand", "West Bengal", "Delhi"
  ];

  @override
  void initState() {
    super.initState();
    // Auto-extract PAN from GSTIN (Same as mobile app logic)
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
    gstC.dispose();
    panC.dispose();
    dlC.dispose();
    addressC.dispose();
    cityC.dispose();
    super.dispose();
  }

  void _saveParty() {
    if (nameC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Customer / Firm Name is required!"), backgroundColor: Colors.orange),
      );
      return;
    }

    final newPartyMap = {
      'id': 'WEB-P-${DateTime.now().millisecondsSinceEpoch}',
      'name': nameC.text.trim().toUpperCase(),
      'group': selectedGroup,
      'phone': phoneC.text.trim(),
      'email': '',
      'address': addressC.text.trim(),
      'city': cityC.text.trim().toUpperCase(),
      'state': selectedState,
      'gst': gstC.text.trim().toUpperCase().isEmpty ? 'N/A' : gstC.text.trim().toUpperCase(),
      'pan': panC.text.trim().toUpperCase(),
      'dl': dlC.text.trim().toUpperCase().isEmpty ? 'N/A' : dlC.text.trim().toUpperCase(),
      'opBal': 0.0,
      'creditLimit': 0.0,
      'creditDays': 30,
    };

    // Save to web manager memory
    widget.webPh.addParty(newPartyMap);
    widget.onPartyCreated(newPartyMap);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF38BDF8), size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            "QUICK ADD CUSTOMER",
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _inputField("FIRM / CUSTOMER NAME *", nameC, Icons.business, isCaps: true),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _inputField("MOBILE NUMBER", phoneC, Icons.phone, isNum: true)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedState,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: "STATE (FOR GST)",
                        labelStyle: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                      items: states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) => setState(() => selectedState = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _inputField("GSTIN NUMBER", gstC, Icons.receipt_long, isCaps: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _inputField("DRUG LICENSE (DL)", dlC, Icons.medical_services, isCaps: true)),
                ],
              ),
              const SizedBox(height: 12),
              _inputField("CITY", cityC, Icons.location_city, isCaps: true),
              const SizedBox(height: 12),
              _inputField("OFFICE / SHOP ADDRESS", addressC, Icons.location_on),
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

  Widget _inputField(String label, TextEditingController ctrl, IconData icon, {bool isNum = false, bool isCaps = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
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
}
