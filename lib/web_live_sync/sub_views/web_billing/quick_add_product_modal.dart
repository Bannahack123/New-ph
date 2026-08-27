// FILE: lib/web_live_sync/sub_views/web_billing/quick_add_product_modal.dart

import 'package:flutter/material.dart';
import '../../web_models.dart';
import '../../pharoah_web_manager.dart';

class QuickAddProductModal extends StatefulWidget {
  final PharoahWebManager webPh;
  final Function(Map<String, dynamic> newMed) onProductCreated;

  const QuickAddProductModal({
    super.key,
    required this.webPh,
    required this.onProductCreated,
  });

  @override
  State<QuickAddProductModal> createState() => _QuickAddProductModalState();
}

class _QuickAddProductModalState extends State<QuickAddProductModal> {
  final nameC = TextEditingController();
  final packC = TextEditingController(text: "10 TAB");
  final hsnC = TextEditingController(text: "3004");
  final gstC = TextEditingController(text: "12");
  final mrpC = TextEditingController(text: "0.0");
  final purRateC = TextEditingController(text: "0.0");
  final rateAC = TextEditingController(text: "0.0");
  final rateBC = TextEditingController(text: "0.0");

  String selectedForm = "TAB";
  bool isNarcotic = false;
  bool isScheduleH1 = false;

  final List<String> drugForms = ["TAB", "CAP", "SYP", "INJ", "IV", "PCS", "EXT", "OINT", "DROP"];

  @override
  void dispose() {
    nameC.dispose();
    packC.dispose();
    hsnC.dispose();
    gstC.dispose();
    mrpC.dispose();
    purRateC.dispose();
    rateAC.dispose();
    rateBC.dispose();
    super.dispose();
  }

  void _saveProduct() {
    if (nameC.text.trim().isEmpty || packC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product Name and Packing are required!"), backgroundColor: Colors.orange),
      );
      return;
    }

    double mrp = double.tryParse(mrpC.text) ?? 0.0;
    double pur = double.tryParse(purRateC.text) ?? 0.0;
    double a = double.tryParse(rateAC.text) ?? 0.0;
    double b = double.tryParse(rateBC.text) ?? (a > 0 ? a * 0.95 : 0.0);
    double gst = double.tryParse(gstC.text) ?? 12.0;

    String sysId = "PH-W-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";

    final newMed = Medicine(
      id: sysId,
      systemId: sysId,
      name: nameC.text.trim().toUpperCase(),
      packing: packC.text.trim().toUpperCase(),
      hsnCode: hsnC.text.trim().toUpperCase().isEmpty ? '3004' : hsnC.text.trim().toUpperCase(),
      drugForm: selectedForm,
      gst: gst,
      mrp: mrp,
      purRate: pur,
      rateA: a > 0 ? a : mrp,
      rateB: b,
      rateC: a > 0 ? a * 0.92 : 0.0,
      stock: 0.0,
      isNarcotic: isNarcotic,
      isScheduleH1: isScheduleH1,
      companyId: '',
      saltId: '',
    );

    widget.webPh.addMedicine(newMed);
    
    // 🔑 FIXED: Pehle is modal ko pop karein, fir callback trigger karein
    Navigator.pop(context);
    widget.onProductCreated(newMed.toMap());
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
            decoration: const BoxDecoration(
              color: Color(0x337C3AED),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_box_rounded, color: Color(0xFFA78BFA), size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            "QUICK ADD MEDICINE / PRODUCT",
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: 550,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _inputField("PRODUCT / DRUG NAME *", nameC, Icons.medication, isCaps: true),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(flex: 3, child: _inputField("PACKING *", packC, Icons.inventory, isCaps: true)),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: selectedForm,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: "FORM",
                        labelStyle: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                      items: drugForms.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                      onChanged: (v) => setState(() => selectedForm = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _inputField("HSN CODE", hsnC, Icons.tag, isCaps: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _inputField("GST %", gstC, Icons.percent, isNum: true)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _inputField("MRP ₹", mrpC, Icons.currency_rupee, isNum: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _inputField("PUR. RATE ₹", purRateC, Icons.shopping_cart, isNum: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _inputField("SALE RATE A ₹", rateAC, Icons.sell, isNum: true)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Schedule H1", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                      value: isScheduleH1,
                      activeColor: const Color(0xFF38BDF8),
                      onChanged: (v) => setState(() => isScheduleH1 = v),
                    ),
                  ),
                  Expanded(
                    child: SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Narcotic (NDPS)", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                      value: isNarcotic,
                      activeColor: Colors.redAccent,
                      onChanged: (v) => setState(() => isNarcotic = v),
                    ),
                  ),
                ],
              ),
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
          onPressed: _saveProduct,
          child: const Text("SAVE & SELECT PRODUCT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _inputField(String label, TextEditingController ctrl, IconData icon, {bool isNum = false, bool isCaps = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
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
