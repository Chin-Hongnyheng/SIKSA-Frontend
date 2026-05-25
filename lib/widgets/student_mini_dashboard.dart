import 'package:flutter/material.dart';

import '../core/graphql/api_service.dart';
import 'summary_card.dart';
import 'week_section.dart';

class StudentMiniDashboard extends StatefulWidget {
  final String studentId;
  final String studentName;

  const StudentMiniDashboard({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<StudentMiniDashboard> createState() => _StudentMiniDashboardState();
}

class _StudentMiniDashboardState extends State<StudentMiniDashboard> {
  bool isLoading = true;
  String? errorMessage;

  List<dynamic> records = [];

  int present = 0;
  int late = 0;
  int absent = 0;
  int permission = 0;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final recordData =
          await ApiService.getStudentAttendanceRecords(widget.studentId);

      int p = 0;
      int l = 0;
      int a = 0;
      int per = 0;

      for (final record in recordData) {
        final status = record["status"]?.toString().toLowerCase() ??
            record["type"]?.toString().toLowerCase() ??
            "";

        if (status == "present") {
          p++;
        } else if (status == "late") {
          l++;
        } else if (status == "absent") {
          a++;
        } else if (status == "permission") {
          per++;
        }
      }

      if (!mounted) return;

      setState(() {
        records = recordData;
        present = p;
        late = l;
        absent = a;
        permission = per;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          errorMessage!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.studentName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.8,
          children: [
            SummaryCard(
              title: "Present",
              value: "$present",
              color: Colors.green.withOpacity(0.12),
              borderColor: Colors.green,
            ),
            SummaryCard(
              title: "Late",
              value: "$late",
              color: Colors.orange.withOpacity(0.12),
              borderColor: Colors.orange,
            ),
            SummaryCard(
              title: "Absent",
              value: "$absent",
              color: Colors.red.withOpacity(0.12),
              borderColor: Colors.red,
            ),
            SummaryCard(
              title: "Permission",
              value: "$permission",
              color: Colors.blue.withOpacity(0.12),
              borderColor: Colors.blue,
            ),
          ],
        ),
        const SizedBox(height: 18),
        WeekSection(
          title: "Attendance Records",
          dateRange: "Created sessions",
          isExpanded: true,
          onToggle: () {},
          records: records,
        ),
      ],
    );
  }
}