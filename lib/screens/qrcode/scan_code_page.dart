import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/graphql/api_service.dart';
import 'success_page.dart';

class ScanCodePage extends StatefulWidget {
  const ScanCodePage({super.key});

  @override
  State<ScanCodePage> createState() => _ScanCodePageState();
}

class _ScanCodePageState extends State<ScanCodePage> {
  bool isScanning = true;

  void handleScan(String? code) {
    if (code == null) return;

    setState(() {
      isScanning = false;
    });

    // 🔹 TEMP validation (replace later with backend/API)
    if (code.contains("http") || code.length > 3) {
      // ✅ SUCCESS → go to new page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SuccessPage(scannedData: code),
        ),
      ).then((_) {
        // allow scanning again when returning
        setState(() {
          isScanning = true;
        });
      });
    } else {
      // ❌ ERROR → show dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Invalid QR Code"),
          content: const Text("This QR code is not valid."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  isScanning = true;
                });
              },
              child: const Text("OK"),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan QR Code"),
      ),
      body: MobileScanner(
        controller: MobileScannerController(
          detectionSpeed: DetectionSpeed.noDuplicates,
        ),
        onDetect: (capture) {
          if (!isScanning) return;

          final barcode = capture.barcodes.first;
          final String? code = barcode.rawValue;

          handleScan(code);
        },
      ),
    );
  }
}