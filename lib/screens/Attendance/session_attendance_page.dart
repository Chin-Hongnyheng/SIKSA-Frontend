import 'package:flutter/material.dart';

import '../../core/graphql/api_service.dart';
import '../../widgets/student_mini_dashboard.dart';

class SessionAttendancePage extends StatefulWidget {
  final Map<String, dynamic> session;

  const SessionAttendancePage({
    super.key,
    required this.session,
  });

  @override
  State<SessionAttendancePage> createState() => _SessionAttendancePageState();
}

class _SessionAttendancePageState extends State<SessionAttendancePage> {
  bool isLoading = true;
  String? errorMessage;

  List<Map<String, dynamic>> students = [];
  Map<String, String> selectedStatus = {};

  String get sessionId => widget.session["id"]?.toString() ?? "";
  String get courseId => widget.session["courseId"]?.toString() ?? "";
  String get sessionDate => widget.session["date"]?.toString() ?? "";
  String get startTime => widget.session["startTime"]?.toString() ?? "";
  String get endTime => widget.session["endTime"]?.toString() ?? "";
  String get title => widget.session["title"]?.toString() ?? "Attendance";

  @override
  void initState() {
    super.initState();
    loadPage();
  }

  Future<void> loadPage() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final studentData = await ApiService.getStudentsFromCourse(courseId);
      final records = await ApiService.getSessionAttendance(sessionId);

      final Map<String, String> loadedStatus = {};

      for (final record in records) {
        final studentId = record["studentId"]?.toString();
        final status = record["status"]?.toString();

        if (studentId != null && status != null) {
          loadedStatus[studentId] = status;
        }
      }

      if (!mounted) return;

      setState(() {
        students = studentData
            .map<Map<String, dynamic>>(
              (student) => Map<String, dynamic>.from(student as Map),
            )
            .toList();
        selectedStatus = loadedStatus;
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

  String currentTimeHHMM() {
    final now = TimeOfDay.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  Future<void> markStudent(String studentId, String status) async {
    String? checkIn;
    String? checkOut;

    if (status == "present") {
      checkIn = startTime;
      checkOut = endTime;
    } else if (status == "late") {
      checkIn = currentTimeHHMM();
      checkOut = endTime;
    } else {
      checkIn = null;
      checkOut = null;
    }

    setState(() {
      selectedStatus[studentId] = status;
    });

    try {
      await ApiService.markAttendance(
        studentId: studentId,
        courseId: courseId,
        sessionId: sessionId,
        date: sessionDate,
        status: status,
        checkIn: checkIn,
        checkOut: checkOut,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Saved $studentId as $status"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to save attendance: $e"),
          backgroundColor: Colors.red,
        ),
      );

      await loadPage();
    }
  }

  void showMiniDashboard(Map<String, dynamic> student) {
    final studentId = student["_id"]?.toString() ?? "";
    final studentName = student["userName"]?.toString() ?? studentId;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.86,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "$studentName Attendance",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(),
                Flexible(
                  child: SingleChildScrollView(
                    child: StudentMiniDashboard(
                      studentId: studentId,
                      studentName: studentName,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget statusButton({
    required String studentId,
    required String status,
    required String label,
    required Color color,
  }) {
    final isSelected = selectedStatus[studentId] == status;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          markStudent(studentId, status);
        },
        child: Container(
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget studentRow(Map<String, dynamic> student) {
    final studentId = student["_id"]?.toString() ?? "";
    final studentName = student["userName"]?.toString() ?? "No Name";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              showMiniDashboard(student);
            },
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    studentName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(Icons.bar_chart, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              statusButton(
                studentId: studentId,
                status: "present",
                label: "Present",
                color: Colors.green,
              ),
              statusButton(
                studentId: studentId,
                status: "late",
                label: "Late",
                color: Colors.orange,
              ),
              statusButton(
                studentId: studentId,
                status: "absent",
                label: "Absent",
                color: Colors.red,
              ),
              statusButton(
                studentId: studentId,
                status: "permission",
                label: "Permission",
                color: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final password = widget.session["password"]?.toString() ?? "------";

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: loadPage,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$sessionDate • $startTime - $endTime",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text("Student code: $password"),
                ],
              ),
            ),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (errorMessage != null)
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              )
            else if (students.isEmpty)
              const Center(
                child: Text("No students found"),
              )
            else
              ...students.map(studentRow),
          ],
        ),
      ),
    );
  }
}