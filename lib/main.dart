import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('SIKSA APP'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          // The Text widget is used to display text on the screen.
          child: Text(
            'Hello, Welcome to SIKSA APP!',
            style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.green),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
