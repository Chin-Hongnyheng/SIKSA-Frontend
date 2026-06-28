import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/attendance_session_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/floating_line_background.dart';
import '../../widgets/center_toast.dart';
import '../../modals/attendance_modal_password.dart';

class StudentMarkAttendancePage extends StatefulWidget {
  final String? courseCode;
  const StudentMarkAttendancePage({super.key, this.courseCode});

  @override
  State<StudentMarkAttendancePage> createState() =>
      _StudentMarkAttendancePageState();
}

class _StudentMarkAttendancePageState extends State<StudentMarkAttendancePage> {
  bool isLoading = true;
  String? errorMessage;

  List<AttendanceSessionModel> activeSessions = [];
  List<AttendanceSessionModel> pastSessions = [];

  /// sessionId → status (e.g. 'present', 'late') for already-marked sessions
  Map<String, String> markedSessions = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadActiveSessions());
  }

  Future<void> _loadActiveSessions() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final courseProvider = context.read<CourseProvider>();
      final attendanceProvider = context.read<AttendanceProvider>();
      final user = context.read<UserProvider>().user;

      // Only courses the student is enrolled in
      final enrolledCourses = courseProvider.allCourses
          .where((c) => c.isSubscribed == true)
          .where(
            (c) =>
                widget.courseCode == null || c.courseCode == widget.courseCode,
          )
          .toList();

      if (enrolledCourses.isEmpty) {
        if (!mounted) return;
        setState(() {
          activeSessions = [];
          pastSessions = [];
          isLoading = false;
        });
        return;
      }

      // Load active sessions for each enrolled course
      final List<AttendanceSessionModel> fetched = [];
      for (final course in enrolledCourses) {
        await attendanceProvider.loadActiveSessionsByCourse(course.courseCode);
        final sessions = attendanceProvider.activeSessions
            .where((s) => s.courseCode == course.courseCode && s.isActive)
            .toList();
        fetched.addAll(sessions);
      }

      // Load student's existing attendance records to check already-marked
      final Map<String, String> marked = {};
      // With this:
      if (user != null && user.id != null) {
        await attendanceProvider.loadStudentRecords(user.id!);
        for (final record in attendanceProvider.studentRecords) {
          if (record.status != null && record.status!.isNotEmpty) {
            marked[record.sessionId!] = record.status!;
          }
        }
      }

      // Split into active vs past based on time
      final List<AttendanceSessionModel> active = [];
      final List<AttendanceSessionModel> past = [];

      for (final session in fetched) {
        final status = _sessionTimeStatus(session);
        if (status == 'Active') {
          active.add(session);
        } else {
          past.add(session);
        }
      }

      if (!mounted) return;
      setState(() {
        activeSessions = active;
        pastSessions = past;
        markedSessions = marked;
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

  Color _accentColor(String courseCode) {
    const colors = [
      Color(0xFF1E6B2D),
      Color(0xFF1565C0),
      Color(0xFF6A1B9A),
      Color(0xFFE65100),
      Color(0xFF00695C),
      Color(0xFFC62828),
    ];
    return colors[courseCode.hashCode.abs() % colors.length];
  }

  String _sessionTimeStatus(AttendanceSessionModel session) {
    try {
      final now = DateTime.now();
      final sp = session.startTime.split(':');
      final ep = session.endTime.split(':');
      final start = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(sp[0]),
        int.parse(sp[1]),
      );
      final end = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(ep[0]),
        int.parse(ep[1]),
      );
      if (now.isBefore(start)) return 'Upcoming';
      if (now.isAfter(end)) return 'Ended';
      return 'Active';
    } catch (_) {
      return 'Active';
    }
  }

  Color _statusBadgeColor(String status) {
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

  Widget _sessionCard(
    AttendanceSessionModel session, {
    required bool isActiveSection,
  }) {
    final accent = _accentColor(session.courseCode);
    final timeStatus = _sessionTimeStatus(session);
    final alreadyMarked = markedSessions.containsKey(session.id);
    final markedStatus = markedSessions[session.id];

    // Card is tappable only if: section is active AND not already marked
    final isTappable = isActiveSection && !alreadyMarked;

    final Color timeStatusColor;
    if (timeStatus == 'Active') {
      timeStatusColor = Colors.green;
    } else if (timeStatus == 'Upcoming') {
      timeStatusColor = Colors.orange;
    } else {
      timeStatusColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Opacity(
        opacity: (!isActiveSection || alreadyMarked) ? 0.75 : 1.0,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: isTappable
                ? () async {
                    await AttendancePasswordModal.show(context, session);
                    // Reload after modal closes to reflect new marked status
                    await _loadActiveSessions();
                  }
                : alreadyMarked
                ? () async {
                    await CenterToast.show(
                      context,
                      message:
                          'You\'ve already been marked ${markedStatus ?? 'in'} for this session.',
                      icon: Icons.info_outline_rounded,
                      color: Colors.blue,
                    );
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Left color accent bar
                  Container(
                    width: 4,
                    height: 60,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Session info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Course code + time status badge + marked badge
                        Row(
                          children: [
                            Text(
                              session.courseCode,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: accent,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Time status badge (Active / Ended / Upcoming)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: timeStatusColor.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: timeStatusColor.withOpacity(0.4),
                                ),
                              ),
                              child: Text(
                                timeStatus,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: timeStatusColor,
                                ),
                              ),
                            ),
                            // Already marked badge
                            if (alreadyMarked && markedStatus != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusBadgeColor(
                                    markedStatus,
                                  ).withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _statusBadgeColor(
                                      markedStatus,
                                    ).withOpacity(0.5),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 10,
                                      color: _statusBadgeColor(markedStatus),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      markedStatus[0].toUpperCase() +
                                          markedStatus.substring(1),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: _statusBadgeColor(markedStatus),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Session title
                        Text(
                          session.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Time + date row
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 13,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${session.startTime} – ${session.endTime}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 13,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              session.date,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),
                  // Right icon
                  Icon(
                    alreadyMarked
                        ? Icons.check_circle_outline_rounded
                        : isTappable
                        ? Icons.keyboard_arrow_right_rounded
                        : Icons.lock_outline_rounded,
                    color: alreadyMarked
                        ? _statusBadgeColor(markedStatus ?? '')
                        : isTappable
                        ? accent
                        : Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No sessions available',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Active sessions from your enrolled\ncourses will appear here.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: _loadActiveSessions,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1E6B2D)),
            label: const Text(
              'Refresh',
              style: TextStyle(color: Color(0xFF1E6B2D)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final hasAnything = activeSessions.isNotEmpty || pastSessions.isNotEmpty;

    if (!hasAnything) return _emptyState();

    return RefreshIndicator(
      onRefresh: _loadActiveSessions,
      color: const Color(0xFF1E6B2D),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          // ── Active Sessions ──────────────────────────────────────────
          if (activeSessions.isNotEmpty) ...[
            _sectionHeader('Active Sessions'),
            ...activeSessions.map(
              (s) => _sessionCard(s, isActiveSection: true),
            ),
            const SizedBox(height: 8),
          ],

          // ── Past Sessions ────────────────────────────────────────────
          if (pastSessions.isNotEmpty) ...[
            _sectionHeader('Past Sessions'),
            ...pastSessions.map((s) => _sessionCard(s, isActiveSection: false)),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Green gradient background ──────────────────────────────
          const Positioned.fill(
            child: FloatingLinesBackground(
              colors: [Color(0xFF00FF88), Color(0xFF00DD66), Color(0xFF1E6B2D)],
              lineCount: 6,
              animationSpeed: 0.5,
            ),
          ),

          // ── White body panel ───────────────────────────────────────
          Positioned(
            top: topPadding + 70,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(color: Color(0xFFF5F6FA)),
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1E6B2D),
                      ),
                    )
                  : errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.wifi_off_rounded,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Could not load sessions',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _loadActiveSessions,
                            icon: const Icon(
                              Icons.refresh_rounded,
                              color: Color(0xFF1E6B2D),
                            ),
                            label: const Text(
                              'Try again',
                              style: TextStyle(color: Color(0xFF1E6B2D)),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _buildContent(),
            ),
          ),

          // ── Top header ─────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: Colors.white,
                    ),
                    const Expanded(
                      child: Text(
                        'Mark Attendance',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _loadActiveSessions,
                      icon: const Icon(Icons.refresh_rounded),
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
