import 'package:flutter/material.dart';

import 'screens/Attendance/attendance_home_page.dart';
import 'screens/Attendance/StudentAttendance.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      // home: AttendanceHomePage(),
      home: StudentAttendance(
        studentId: "student1",
        studentName: "student1",
      ),
    );
  }
}