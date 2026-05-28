  import 'dart:typed_data';
  import 'dart:ui' as ui;
  import 'dart:io';

  import 'package:flutter/material.dart';
  import 'package:flutter/rendering.dart';
  import 'package:flutter/services.dart';

  import 'package:qr_flutter/qr_flutter.dart';
  import 'package:share_plus/share_plus.dart';
  import 'package:path_provider/path_provider.dart';

  class GenerateQRPage extends StatefulWidget {
    const GenerateQRPage({super.key});

    @override
    State<GenerateQRPage> createState() => _GenerateQRPageState();
  }

  class _GenerateQRPageState extends State<GenerateQRPage> {
    final TextEditingController _controller = TextEditingController();
    final GlobalKey _qrKey = GlobalKey();

    String qrData = "Enter something";

    Future<Uint8List?> _captureQR() async {
      try {
        final boundary =
            _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

        final image = await boundary.toImage(pixelRatio: 3.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

        return byteData?.buffer.asUint8List();
      } catch (e) {
        debugPrint("Capture error: $e");
        return null;
      }
    }

    /// ✅ SAVE WITHOUT ANY GALLERY PLUGIN
    Future<void> _saveQR() async {
      final bytes = await _captureQR();
      if (bytes == null) return;

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/qr_code.png');

      await file.writeAsBytes(bytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Saved at: ${file.path}")),
      );
    }

    /// SHARE
    Future<void> _shareQR() async {
      final bytes = await _captureQR();
      if (bytes == null) return;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/qr.png');

      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: "Here is my QR Code",
      );
    }

    /// COPY TEXT
    void _copyText() {
      Clipboard.setData(ClipboardData(text: qrData));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Copied")),
      );
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: const Text("Generate QR Code")),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: "Enter data",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  setState(() {
                    qrData = _controller.text.isEmpty
                        ? "Enter something"
                        : _controller.text;
                  });
                },
                child: const Text("Generate"),
              ),

              const SizedBox(height: 20),

              RepaintBoundary(
                key: _qrKey,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(10),
                  child: QrImageView(
                    data: qrData,
                    size: 200,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _saveQR,
                    child: const Text("Save"),
                  ),
                  ElevatedButton(
                    onPressed: _shareQR,
                    child: const Text("Share"),
                  ),
                  ElevatedButton(
                    onPressed: _copyText,
                    child: const Text("Copy"),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }