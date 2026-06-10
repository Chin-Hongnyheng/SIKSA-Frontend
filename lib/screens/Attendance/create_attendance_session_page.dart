import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/graphql/api_service.dart';
import 'session_attendance_page.dart';

class CreateAttendanceSessionPage extends StatefulWidget {
  const CreateAttendanceSessionPage({super.key});

  @override
  State<CreateAttendanceSessionPage> createState() =>
      _CreateAttendanceSessionPageState();
}

class _CreateAttendanceSessionPageState
    extends State<CreateAttendanceSessionPage> {
  final TextEditingController titleController = TextEditingController();

  bool isLoadingCourses = true;
  bool isCreating = false;
  bool isRefreshing = false;

  String? errorMessage;

  List<dynamic> courses = [];
  String selectedCourseId = "";
  String selectedCourseName = "Course";

  final String teacherId = "teacher1";

  DateTime selectedDate = DateTime.now();
  TimeOfDay startTime = TimeOfDay.now();
  TimeOfDay endTime = const TimeOfDay(hour: 15, minute: 0);

  Map<String, dynamic>? activeSession;

  Timer? countdownTimer;
  int remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    titleController.text = "Attendance Session";
    loadCourses();
  }

  @override
  void dispose() {
    titleController.dispose();
    countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> loadCourses() async {
    setState(() {
      isLoadingCourses = true;
      errorMessage = null;
    });

    try {
      final courseData = await ApiService.getCourses();

      String firstId = ApiService.defaultCourseId;
      String firstName = "Mobile";

      if (courseData.isNotEmpty) {
        firstId = courseData.first["_id"]?.toString() ?? firstId;
        firstName = courseData.first["name"]?.toString() ?? firstName;
      }

      setState(() {
        courses = courseData;
        selectedCourseId = firstId;
        selectedCourseName = firstName;
        isLoadingCourses = false;
      });
    } catch (e) {
      debugPrint("Error loading courses: $e");

      setState(() {
        selectedCourseId = ApiService.defaultCourseId;
        selectedCourseName = "Mobile";
        isLoadingCourses = false;
        errorMessage = null;
      });
    }
  }

  String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String displayDate(DateTime date) {
    return DateFormat('d MMMM yyyy').format(date);
  }

  String formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      selectedDate = picked;
    });
  }

  Future<void> pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: startTime,
    );

    if (picked == null) return;

    setState(() {
      startTime = picked;
    });
  }

  Future<void> pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: endTime,
    );

    if (picked == null) return;

    setState(() {
      endTime = picked;
    });
  }

  int getRemainingSeconds(String? expiresAtText) {
    if (expiresAtText == null) return 0;

    try {
      final expiresAt = DateTime.parse(expiresAtText).toLocal();
      final now = DateTime.now();
      final diff = expiresAt.difference(now).inSeconds;

      return diff > 0 ? diff : 0;
    } catch (_) {
      return 0;
    }
  }

  void startCountdown() {
    countdownTimer?.cancel();

    remainingSeconds = getRemainingSeconds(
      activeSession?["passwordExpiresAt"]?.toString(),
    );

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) return;

      setState(() {
        remainingSeconds--;
      });

      if (remainingSeconds <= 0) {
        timer.cancel();
        await refreshCode();
      }
    });
  }

  Future<void> createSession() async {
    final title = titleController.text.trim();

    if (selectedCourseId.isEmpty) {
      showError("Please select a course");
      return;
    }

    if (title.isEmpty) {
      showError("Please enter session title");
      return;
    }

    setState(() {
      isCreating = true;
      errorMessage = null;
    });

    try {
      final session = await ApiService.createAttendanceSession(
        courseId: selectedCourseId,
        teacherId: teacherId,
        title: title,
        date: formatDate(selectedDate),
        startTime: formatTime(startTime),
        endTime: formatTime(endTime),
      );

      if (!mounted) return;

      setState(() {
        activeSession = session;
        isCreating = false;
      });

      startCountdown();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Attendance session created"),
          backgroundColor: Colors.green,
        ),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SessionAttendancePage(session: session),
        ),
      );
    } catch (e) {
      debugPrint("Create session error: $e");

      if (!mounted) return;

      setState(() {
        isCreating = false;
        errorMessage = e.toString();
      });

      showError("Failed to create session");
    }
  }

  Future<void> refreshCode() async {
    final sessionId = activeSession?["id"]?.toString();

    if (sessionId == null || sessionId.isEmpty) return;

    setState(() {
      isRefreshing = true;
    });

    try {
      final newSession =
          await ApiService.refreshAttendanceSessionPassword(sessionId);

      if (!mounted) return;

      setState(() {
        activeSession = newSession;
        isRefreshing = false;
      });

      startCountdown();
    } catch (e) {
      debugPrint("Refresh code error: $e");

      if (!mounted) return;

      setState(() {
        isRefreshing = false;
      });

      showError("Failed to refresh code");
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget buildCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget buildPickerBox({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down),
          ],
        ),
      ),
    );
  }

  Widget buildCreateForm() {
    return Column(
      children: [
        buildCard(
          title: "Course",
          child: isLoadingCourses
              ? const Center(child: CircularProgressIndicator())
              : DropdownButtonFormField<String>(
                  value: selectedCourseId.isEmpty ? null : selectedCourseId,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: courses.isEmpty
                      ? [
                          DropdownMenuItem(
                            value: ApiService.defaultCourseId,
                            child: const Text("Mobile"),
                          ),
                        ]
                      : courses.map((course) {
                          final id = course["_id"]?.toString() ?? "";
                          final name =
                              course["name"]?.toString() ?? "No Course";

                          return DropdownMenuItem<String>(
                            value: id,
                            child: Text(name),
                          );
                        }).toList(),
                  onChanged: (value) {
                    if (value == null) return;

                    final selected = courses.firstWhere(
                      (course) => course["_id"]?.toString() == value,
                      orElse: () => {
                        "_id": value,
                        "name": "Mobile",
                      },
                    );

                    setState(() {
                      selectedCourseId = value;
                      selectedCourseName =
                          selected["name"]?.toString() ?? "Mobile";
                    });
                  },
                ),
        ),
        buildCard(
          title: "Session Title",
          child: TextField(
            controller: titleController,
            decoration: InputDecoration(
              hintText: "Example: Week 1 Attendance",
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        buildCard(
          title: "Date",
          child: buildPickerBox(
            icon: Icons.calendar_today,
            text: displayDate(selectedDate),
            onTap: pickDate,
          ),
        ),
        Row(
          children: [
            Expanded(
              child: buildCard(
                title: "Start Time",
                child: buildPickerBox(
                  icon: Icons.access_time,
                  text: formatTime(startTime),
                  onTap: pickStartTime,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildCard(
                title: "Class End",
                child: buildPickerBox(
                  icon: Icons.timer_off,
                  text: formatTime(endTime),
                  onTap: pickEndTime,
                ),
              ),
            ),
          ],
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.security, color: Colors.orange),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Security rule: the attendance code changes every 1 minute. Students who check in after 15 minutes will be marked late.",
                  style: TextStyle(
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (errorMessage != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red),
            ),
            child: Text(
              errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: isCreating ? null : createSession,
            icon: isCreating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.lock_clock, color: Colors.white),
            label: Text(
              isCreating ? "Creating..." : "Create Attendance Session",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          backgroundColor: Colors.green,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            "Create Attendance Session",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: buildCreateForm(),
      ),
    );
  }
}