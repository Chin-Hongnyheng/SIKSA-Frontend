import 'package:flutter/material.dart';

class SuccessPage extends StatelessWidget {
  final String scannedData;

  const SuccessPage({
    super.key,
    required this.scannedData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Success"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 100,
              ),
              const SizedBox(height: 20),
              const Text(
                "Scan Successful!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                "Scanned Data:",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 5),
              Text(
                scannedData,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // go back to scanner
                },
                child: const Text("Scan Again"),
              )
            ],
          ),
        ),
      ),
    );
  }
}