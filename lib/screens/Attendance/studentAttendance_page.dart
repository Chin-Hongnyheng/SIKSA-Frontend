import 'package:flutter/material.dart';

import '../../widgets/student_mini_dashboard.dart';

class StudentAttendancePage extends StatelessWidget {
  final String studentId;
  final String studentName;

  const StudentAttendancePage({
    super.key,
    this.studentId = 'student1',
    this.studentName = 'student1',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          backgroundColor: Colors.green,
          centerTitle: true,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            "My Attendance",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: StudentMiniDashboard(
          studentId: studentId,
          studentName: studentName,
        ),
      ),
    );
  }
}