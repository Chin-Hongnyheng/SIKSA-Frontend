import 'package:flutter/material.dart';

import '../../models/attendance_session_model.dart';
import '../../service/attendance_service.dart';
import 'attendance_session_report_page.dart';
import 'session_attendance_page.dart';

class ViewAttendanceSessionsPage extends StatefulWidget {
  const ViewAttendanceSessionsPage({super.key});

  @override
  State<ViewAttendanceSessionsPage> createState() =>
      _ViewAttendanceSessionsPageState();
}

class _ViewAttendanceSessionsPageState
    extends State<ViewAttendanceSessionsPage> {
  final AttendanceService attendanceService = AttendanceService();

  bool isLoading = true;
  String? errorMessage;

  String selectedCourseId = AttendanceService.defaultCourseId;
  List<AttendanceSessionModel> sessions = [];

  @override
  void initState() {
    super.initState();
    loadSessions();
  }

  Future<void> loadSessions() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data =
          await attendanceService.getAttendanceSessionsByCourse(selectedCourseId);

      if (!mounted) return;

      setState(() {
        sessions = data;
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

  Future<void> openReport(AttendanceSessionModel session) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AttendanceSessionReportPage(
          session: session,
        ),
      ),
    );

    await loadSessions();
  }

  Future<void> openEdit(AttendanceSessionModel session) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SessionAttendancePage(
          session: session.toJson(),
        ),
      ),
    );

    await loadSessions();
  }

  Future<void> deleteSession(AttendanceSessionModel session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Attendance Session'),
          content: Text(
            'Are you sure you want to delete "${session.title}"?\n\nThis will also delete all attendance records inside this session.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              label: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final deleted = await attendanceService.deleteAttendanceSession(session.id);

      if (!mounted) return;

      if (deleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance session deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        await loadSessions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session not found or already deleted'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color sessionStatusColor(AttendanceSessionModel session) {
    return session.isActive ? Colors.green : Colors.grey;
  }

  Widget buildSessionCard(AttendanceSessionModel session) {
    final color = sessionStatusColor(session);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => openReport(session),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(
                    Icons.assignment_outlined,
                    color: color,
                  ),
                ),
                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${session.date} • ${session.startTime} - ${session.endTime}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        session.isActive ? 'Active session' : 'Closed session',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                Column(
                  children: [
                    IconButton(
                      onPressed: () => openReport(session),
                      icon: const Icon(Icons.visibility_outlined),
                      tooltip: 'View report',
                    ),
                    IconButton(
                      onPressed: () => openEdit(session),
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit attendance',
                    ),
                    IconButton(
                      onPressed: () => deleteSession(session),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                      tooltip: 'Delete session',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return RefreshIndicator(
        onRefresh: loadSessions,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      );
    }

    if (sessions.isEmpty) {
      return RefreshIndicator(
        onRefresh: loadSessions,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(
              child: Text('No attendance sessions yet'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadSessions,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Attendance Sessions',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap a session to view the report. Use edit to update attendance or delete to remove the session.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          ...sessions.map(buildSessionCard),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'View Attendance Sessions',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: buildBody(),
    );
  }
}