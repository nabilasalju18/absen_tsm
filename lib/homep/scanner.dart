import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// 🔥 Helper langsung di file yang sama
class ScannerHelper {
  static String? extractCode(BarcodeCapture capture) {
    if (capture.barcodes.isEmpty) return null;

    final barcode = capture.barcodes.firstWhere(
      (b) => b.rawValue != null && b.rawValue!.isNotEmpty,
      orElse: () => capture.barcodes.first,
    );

    final code = barcode.rawValue;

    if (code == null || code.isEmpty) return null;

    return code.trim();
  }
}

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final MobileScannerController controller = MobileScannerController();

  bool isScanned = false;

  void onDetect(BarcodeCapture capture) async {
  if (isScanned) return;

  final code = ScannerHelper.extractCode(capture);

  if (code == null) return;

  setState(() => isScanned = true);

  await controller.stop();

  if (!mounted) return;

  Navigator.pop(context, code);
}

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan QR")),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: onDetect,
          ),

          if (isScanned)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: Text(
                  "Scan berhasil",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
        ],
      ),
    );
  }
}