import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        appBar: AppBar(
          title: Text('SIKSA APP', style: GoogleFonts.nunito(fontSize: 20)),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            children: [
              Text(
                'Hello, Welcome to SIKSA APP!',
                style: TextStyle(fontSize: 30),
              ),
              Text('SIKSA APP', style: GoogleFonts.nunito(fontSize: 20)),
            ],
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
