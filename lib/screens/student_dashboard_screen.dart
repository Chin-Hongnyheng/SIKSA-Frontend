import 'package:flutter/material.dart';

import 'dashboard_screen.dart';

class StudentDashBoardScreen extends StatelessWidget {
  const StudentDashBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashBoardScreen(isStudentDashboard: true);
  }
}
