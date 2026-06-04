import 'package:flutter/material.dart';

import '../../models/attendance_session_model.dart';
import '../../models/attendance_record_model.dart';
import '../../service/attendance_service.dart';
import '../../widgets/student_mini_dashboard.dart';
import 'session_attendance_page.dart';

class AttendanceSessionReportPage extends StatefulWidget {
  final AttendanceSessionModel session;

  const AttendanceSessionReportPage({
    super.key,
    required this.session,
  });

  @override
  State<AttendanceSessionReportPage> createState() =>
      _AttendanceSessionReportPageState();
}

class _AttendanceSessionReportPageState
    extends State<AttendanceSessionReportPage> {
  final AttendanceService attendanceService = AttendanceService();

  bool isLoading = true;
  String? errorMessage;

  List<Map<String, dynamic>> students = [];
  List<AttendanceRecordModel> records = [];

  @override
  void initState() {
    super.initState();
    loadReport();
  }

  Future<void> loadReport() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final studentData =
          await attendanceService.getStudentsFromCourse(widget.session.courseId);

      final recordData =
          await attendanceService.getSessionAttendance(widget.session.id);

      if (!mounted) return;

      setState(() {
        students = studentData;
        records = recordData;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  AttendanceRecordModel? findRecordByStudentId(String studentId) {
    for (final record in records) {
      if (record.studentId == studentId) {
        return record;
      }
    }
    return null;
  }

  String calculateTotalTime(String? checkIn, String? checkOut) {
    if (checkIn == null || checkOut == null) return '-';
    if (checkIn.isEmpty || checkOut.isEmpty) return '-';

    try {
      final startParts = checkIn.split(':');
      final endParts = checkOut.split(':');

      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);

      final endHour = int.parse(endParts[0]);
      final endMinute = int.parse(endParts[1]);

      final start = Duration(hours: startHour, minutes: startMinute);
      final end = Duration(hours: endHour, minutes: endMinute);

      final diff = end - start;

      if (diff.isNegative) return '-';

      final hours = diff.inHours;
      final minutes = diff.inMinutes.remainder(60);

      if (hours == 0) return '${minutes}m';
      if (minutes == 0) return '${hours}h';

      return '${hours}h ${minutes}m';
    } catch (_) {
      return '-';
    }
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'late':
        return Colors.orange;
      case 'absent':
        return Colors.red;
      case 'permission':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String statusText(String status) {
    if (status.isEmpty) return 'Not marked';
    return status[0].toUpperCase() + status.substring(1);
  }

  void openMiniDashboard(Map<String, dynamic> student) {
    final studentId = student['_id']?.toString() ?? '';
    final studentName = student['userName']?.toString() ?? studentId;

    showDialog(
      context: context,
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
                        '$studentName Attendance',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
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

  Future<void> openEditPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SessionAttendancePage(
          session: widget.session.toJson(),
        ),
      ),
    );

    await loadReport();
  }

  Widget buildSummaryHeader() {
    int present = 0;
    int late = 0;
    int absent = 0;
    int permission = 0;

    for (final record in records) {
      final status = record.status.toLowerCase();

      if (status == 'present') present++;
      if (status == 'late') late++;
      if (status == 'absent') absent++;
      if (status == 'permission') permission++;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.green.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.session.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.session.date} • ${widget.session.startTime} - ${widget.session.endTime}',
            style: const TextStyle(color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: miniCount('Present', present, Colors.green)),
              const SizedBox(width: 8),
              Expanded(child: miniCount('Late', late, Colors.orange)),
              const SizedBox(width: 8),
              Expanded(child: miniCount('Absent', absent, Colors.red)),
              const SizedBox(width: 8),
              Expanded(child: miniCount('Permission', permission, Colors.blue)),
            ],
          ),
        ],
      ),
    );
  }

  Widget miniCount(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(14),
        ),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Student',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Status',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Check In',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Check Out',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Total',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStudentRow(Map<String, dynamic> student, int index) {
    final studentId = student['_id']?.toString() ?? '';
    final studentName = student['userName']?.toString() ?? studentId;

    final record = findRecordByStudentId(studentId);

    final status = record?.status ?? '';
    final checkIn = record?.checkIn ?? '-';
    final checkOut = record?.checkOut ?? '-';
    final total = calculateTotalTime(record?.checkIn, record?.checkOut);

    return InkWell(
      onTap: () => openMiniDashboard(student),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: index.isEven ? Colors.white : Colors.grey.shade50,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.green.withOpacity(0.12),
                    child: Text(
                      studentName.isNotEmpty
                          ? studentName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      studentName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor(status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor(status)),
                  ),
                  child: Text(
                    statusText(status),
                    style: TextStyle(
                      fontSize: 11,
                      color: statusColor(status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(flex: 2, child: Text(checkIn)),
            Expanded(flex: 2, child: Text(checkOut)),
            Expanded(flex: 2, child: Text(total)),
          ],
        ),
      ),
    );
  }

  Widget buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          buildTableHeader(),
          if (students.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No students found'),
            )
          else
            ...students.asMap().entries.map(
                  (entry) => buildStudentRow(entry.value, entry.key),
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Attendance Report',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: openEditPage,
            icon: const Icon(Icons.edit, color: Colors.white),
            tooltip: 'Edit attendance',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openEditPage,
        backgroundColor: Colors.green,
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text(
          'Edit',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: loadReport,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            buildSummaryHeader(),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (errorMessage != null)
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 900,
                  child: buildTable(),
                ),
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}