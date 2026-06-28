import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/course_provider.dart';
import '../../models/course_model.dart';
import '../../widgets/center_toast.dart';
import '../../widgets/floating_line_background.dart';
import 'session_attendance_page.dart';

class CreateAttendanceSessionPage extends StatefulWidget {
  final Map<String, dynamic>? scheduleData;

  const CreateAttendanceSessionPage({super.key, this.scheduleData});

  @override
  State<CreateAttendanceSessionPage> createState() =>
      _CreateAttendanceSessionPageState();
}

class _CreateAttendanceSessionPageState
    extends State<CreateAttendanceSessionPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController lateDurationController = TextEditingController();

  bool isCreating = false;
  String? errorMessage;

  CourseModel? selectedCourse;
  String? selectedCourseCode;

  DateTime selectedDate = DateTime.now();
  TimeOfDay startTime = TimeOfDay.now();
  TimeOfDay endTime = const TimeOfDay(hour: 15, minute: 0);
  int lateDurationMinutes = 15;

  String? _displayCourseName;
  String? _displayCourseCode;
  String? _displayLocation;
  String? _displayStartTime;
  String? _displayEndTime;

  Timer? countdownTimer;
  int remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    titleController.text = "Attendance Session";
    lateDurationController.text = "15";

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final courseProvider = context.read<CourseProvider>();

      if (widget.scheduleData != null) {
        final data = widget.scheduleData!;

        final courseCode = data['courseCode'] as String?;
        final sessionTitle = data['sessionTitle'] as String?;
        final startTimeStr = data['startTime'] as String?;
        final endTimeStr = data['endTime'] as String?;
        final location = data['courseLocation'] as String?;
        final courseName = data['courseName'] as String?;

        setState(() {
          _displayCourseCode = courseCode;
          _displayCourseName = courseName ?? courseCode;
          _displayLocation = location ?? '—';
          _displayStartTime = startTimeStr ?? '—';
          _displayEndTime = endTimeStr ?? '—';
        });

        if (sessionTitle != null && sessionTitle.isNotEmpty) {
          titleController.text = sessionTitle;
        }

        if (startTimeStr != null && startTimeStr.isNotEmpty) {
          final parts = startTimeStr.split(':');
          if (parts.length == 2) {
            startTime = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }
        }

        if (endTimeStr != null && endTimeStr.isNotEmpty) {
          final parts = endTimeStr.split(':');
          if (parts.length == 2) {
            endTime = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }
        }

        if (courseCode != null && courseProvider.courses.isNotEmpty) {
          try {
            selectedCourse = courseProvider.courses.firstWhere(
              (c) => c.courseCode == courseCode,
            );
            selectedCourseCode = courseCode;
          } catch (_) {
            selectedCourse = courseProvider.courses.first;
          }
        }
      } else {
        if (courseProvider.courses.isEmpty) {
          courseProvider.loadCourses();
        } else {
          setState(() {
            selectedCourse = courseProvider.courses.first;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    titleController.dispose();
    lateDurationController.dispose();
    countdownTimer?.cancel();
    super.dispose();
  }

  String formatDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
  String displayDate(DateTime date) => DateFormat('d MMMM yyyy').format(date);

  String formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  int getRemainingSeconds(String? expiresAtText) {
    if (expiresAtText == null) return 0;
    try {
      final ms = int.tryParse(expiresAtText);
      final expiresAt = ms != null
          ? DateTime.fromMillisecondsSinceEpoch(ms)
          : DateTime.parse(expiresAtText).toLocal();
      final diff = expiresAt.difference(DateTime.now()).inSeconds;
      return diff > 0 ? diff : 0;
    } catch (_) {
      return 0;
    }
  }

  void startCountdown(String? passwordExpiresAt) {
    countdownTimer?.cancel();
    remainingSeconds = getRemainingSeconds(passwordExpiresAt);

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) return;
      setState(() => remainingSeconds--);
      if (remainingSeconds <= 0) timer.cancel();
    });
  }

  Future<void> createSession() async {
    final title = titleController.text.trim();
    final lateDurationStr = lateDurationController.text.trim();
    final lateDuration = int.tryParse(lateDurationStr) ?? 15;

    if (selectedCourse == null) {
      showError('Please select a course');
      return;
    }
    if (title.isEmpty) {
      showError('Please enter a session title');
      return;
    }

    final provider = context.read<AttendanceProvider>();
    final effectiveCourseCode = widget.scheduleData != null
        ? _displayCourseCode!
        : selectedCourse!.courseCode;
    final existing = provider.findActiveSession(
      courseCode: selectedCourse!.courseCode,
      date: formatDate(selectedDate),
      startTime: formatTime(startTime),
      endTime: formatTime(endTime),
    );

    if (existing != null) {
      CenterToast.show(
        context,
        message: 'Session still active — resuming existing session',
        icon: Icons.info_outline,
        color: Colors.orange,
      );
      if (!mounted) return;
      context.pushReplacement('/attendance/home/list/create/${existing.id}');
      return;
    }

    setState(() {
      isCreating = true;
      errorMessage = null;
      lateDurationMinutes = lateDuration;
    });

    try {
      final session = await provider.createAttendanceSession(
        courseCode: effectiveCourseCode,
        title: title,
        date: formatDate(selectedDate),
        startTime: formatTime(startTime),
        endTime: formatTime(endTime),
        lateAfterMinutes: lateDuration,
      );

      if (!mounted) return;

      if (session == null) {
        final err = provider.error;
        setState(() {
          isCreating = false;
          errorMessage = err ?? 'Failed to create session';
        });
        showError(errorMessage!);
        return;
      }

      setState(() => isCreating = false);
      startCountdown(session.passwordExpiresAt);
      if (!mounted) return;

      CenterToast.show(
        context,
        message: 'Attendance session created',
        icon: Icons.check_circle,
        color: Colors.green,
      );
      context.pushReplacement('/attendance/home/list/create/${session.id}');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isCreating = false;
        errorMessage = e.toString();
      });
      showError('Failed to create session: $e');
    }
  }

  void showError(String message) {
    CenterToast.show(
      context,
      message: message,
      icon: Icons.error_outline,
      color: Colors.red,
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.black54,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 17, color: Colors.grey[500]),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.lock_outline_rounded, size: 14, color: Colors.grey[400]),
      ],
    );
  }

  Widget _divider() =>
      Divider(height: 20, thickness: 0.5, color: Colors.grey.shade200);

  Widget _buildForm(List<CourseModel> courses, bool isLoadingCourses) {
    final bool fromSchedule = widget.scheduleData != null;

    return Column(
      children: [
        if (fromSchedule) ...[
          _sectionCard(
            title: 'COURSE',
            child: _infoRow(
              Icons.school_outlined,
              _displayCourseCode ?? '',
              _displayCourseName ?? '—',
            ),
          ),
          _sectionCard(
            title: 'SCHEDULE',
            child: Column(
              children: [
                _infoRow(
                  Icons.calendar_today_outlined,
                  'Date',
                  displayDate(selectedDate),
                ),
                _divider(),
                _infoRow(
                  Icons.access_time_rounded,
                  'Start time',
                  _displayStartTime ?? '—',
                ),
                _divider(),
                _infoRow(
                  Icons.timer_off_outlined,
                  'End time',
                  _displayEndTime ?? '—',
                ),
                _divider(),
                _infoRow(
                  Icons.location_on_outlined,
                  'Location',
                  _displayLocation ?? '—',
                ),
              ],
            ),
          ),
        ],

        _sectionCard(
          title: 'SESSION TITLE',
          child: TextField(
            controller: titleController,
            decoration: InputDecoration(
              hintText: 'e.g. Week 5 Attendance',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        _sectionCard(
          title: 'LATE AFTER (MINUTES)',
          child: TextField(
            controller: lateDurationController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '15',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixText: 'min',
              suffixStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
        ),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.orange.withOpacity(0.4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.security_rounded,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 13,
                      height: 1.5,
                    ),
                    children: [
                      TextSpan(
                        text: 'The attendance code rotates every minute. ',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(
                        text:
                            'Students checking in after the late threshold will be marked late.',
                      ),
                    ],
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
              color: Colors.red.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Text(
              errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isCreating ? null : createSession,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: Colors.green.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: isCreating
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Creating session...',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_clock_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Create Attendance Session',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Consumer<CourseProvider>(
      builder: (context, courseProvider, _) {
        if (selectedCourse == null && courseProvider.courses.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() => selectedCourse = courseProvider.courses.first);
          });
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // ── Animated green background ──────────────────────────
              const Positioned.fill(
                child: FloatingLinesBackground(
                  colors: [
                    Color(0xFF00FF88),
                    Color(0xFF00DD66),
                    Color(0xFF1E6B2D),
                  ],
                  lineCount: 6,
                  animationSpeed: 0.5,
                ),
              ),

              // ── White body panel ───────────────────────────────────
              Positioned(
                top: topPadding + 70,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: const BoxDecoration(color: Color(0xFFF2F2F2)),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: _buildForm(
                      courseProvider.courses,
                      courseProvider.isLoading,
                    ),
                  ),
                ),
              ),

              // ── Top header ─────────────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          color: Colors.white,
                        ),
                        const Expanded(
                          child: Text(
                            'Create Attendance Session',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
