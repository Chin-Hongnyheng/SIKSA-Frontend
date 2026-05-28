import 'package:flutter/material.dart';

import '../../core/graphql/api_service.dart';
import 'session_attendance_page.dart';

class ViewAttendanceSessionsPage extends StatefulWidget {
  const ViewAttendanceSessionsPage({super.key});

  @override
  State<ViewAttendanceSessionsPage> createState() =>
      _ViewAttendanceSessionsPageState();
}

class _ViewAttendanceSessionsPageState
    extends State<ViewAttendanceSessionsPage> {
  bool isLoading = true;
  String? errorMessage;

  String selectedCourseId = ApiService.defaultCourseId;
  List<dynamic> sessions = [];

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
      final data = await ApiService.getAttendanceSessionsByCourse(
        selectedCourseId,
      );

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

  Widget buildSessionCard(dynamic rawSession) {
    final session = Map<String, dynamic>.from(rawSession as Map);

    final title = session["title"]?.toString() ?? "No Title";
    final date = session["date"]?.toString() ?? "-";
    final start = session["startTime"]?.toString() ?? "-";
    final end = session["endTime"]?.toString() ?? "-";
    final isActive = session["isActive"] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SessionAttendancePage(
                  session: session,
                ),
              ),
            );

            await loadSessions();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isActive
                      ? Colors.green.withOpacity(0.12)
                      : Colors.grey.withOpacity(0.2),
                  child: Icon(
                    Icons.event_available,
                    color: isActive ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text("$date • $start - $end"),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
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
          "Attendance Sessions",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: loadSessions,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else if (sessions.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(
                  child: Text("No attendance sessions yet"),
                ),
              )
            else
              ...sessions.map(buildSessionCard),
          ],
        ),
      ),
    );
  }
}