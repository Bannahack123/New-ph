// FILE: lib/web_live_sync/sub_views/web_challans/web_challan_signature_view.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../web_models.dart';
import '../../pharoah_web_manager.dart';
import '../../web_app_date_logic.dart';

class WebChallanSignatureView extends StatefulWidget {
  final SaleChallan challan;
  final Party party;
  final VoidCallback onBack;

  const WebChallanSignatureView({
    super.key,
    required this.challan,
    required this.party,
    required this.onBack,
  });

  @override
  State<WebChallanSignatureView> createState() => _WebChallanSignatureViewState();
}

class _WebChallanSignatureViewState extends State<WebChallanSignatureView> {
  List<Offset?> points = [];
  String uniqueSealCode = "";

  @override
  void initState() {
    super.initState();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    uniqueSealCode = "VR-${List.generate(5, (_) => chars[Random().nextInt(chars.length)]).join()}";
  }

  void _handleSealFinalize(PharoahWebManager webPh) {
    if (points.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please draw customer signature on canvas!"), backgroundColor: Colors.orange),
      );
      return;
    }

    double totalQty = widget.challan.items.fold(0.0, (sum, it) => sum + it.qty + it.freeQty);

    final sig = ChallanSignature(
      id: "SIG-${DateTime.now().millisecondsSinceEpoch}",
      imagePath: "web_canvas_signature.png",
      verificationCode: uniqueSealCode,
      signedAmount: widget.challan.totalAmount,
      signedQty: totalQty,
      signDate: DateTime.now(),
      signX: 0.1,
      signY: 0.8,
    );

    widget.challan.sigHistory = [sig];
    widget.challan.isSigned = true;

    webPh.pushUpdatedDataToCloud();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ Challan Locked & Sealed with Code: $uniqueSealCode!"), backgroundColor: Colors.green),
    );

    widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    final webPh = Provider.of<PharoahWebManager>(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white12,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text("CANCEL", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 15),
              const Icon(Icons.verified_user_rounded, color: Colors.cyanAccent, size: 22),
              const SizedBox(width: 10),
              Text(
                "DIGITAL TOUCH SEAL • ${widget.challan.billNo}",
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x3310B981),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.greenAccent),
                ),
                child: Text(
                  "SEAL: $uniqueSealCode",
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Receiver / Customer: ${widget.party.name.toUpperCase()}",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(
                  "Total Value: ₹${widget.challan.totalAmount.toStringAsFixed(2)}",
                  style: const TextStyle(color: Color(0xFF2DD4BF), fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 15)],
              ),
              child: GestureDetector(
                onPanUpdate: (d) {
                  RenderBox box = context.findRenderObject() as RenderBox;
                  Offset local = box.globalToLocal(d.globalPosition);
                  setState(() => points.add(local));
                },
                onPanEnd: (_) => setState(() => points.add(null)),
                child: CustomPaint(
                  painter: WebSignaturePainter(points: points),
                  child: Center(
                    child: points.isEmpty
                        ? const Text(
                            "Draw Customer Signature Here (Mouse / iPad Apple Pencil)",
                            style: TextStyle(color: Colors.black26, fontSize: 14, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white54,
                  side: const BorderSide(color: Colors.white24),
                ),
                onPressed: () => setState(() => points.clear()),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text("CLEAR CANVAS"),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                onPressed: () => _handleSealFinalize(webPh),
                icon: const Icon(Icons.lock_rounded, size: 18),
                label: const Text("LOCK & FINALIZE DIGITAL SEAL", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WebSignaturePainter extends CustomPainter {
  final List<Offset?> points;
  WebSignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = const Color(0xFF1E1B4B)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(WebSignaturePainter oldDelegate) => true;
}
