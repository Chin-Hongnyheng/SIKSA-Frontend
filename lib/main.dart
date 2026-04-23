import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_theme.dart';
import 'Attendance/studentAttendance.dart';
import 'Attendance/teacherAttendance.dart';
import 'qrcode/scan_code_page.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      // home: const StudentAttendance(), 
      home: ScanCodePage(),
      debugShowCheckedModeBanner: false
    );
  }
}