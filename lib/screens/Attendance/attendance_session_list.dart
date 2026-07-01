import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/schedule_model.dart';
import '../../models/course_model.dart';
import '../../models/attendance_session_model.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../widgets/floating_line_background.dart';

class AttendanceSessionListPage extends StatefulWidget {
  /// When provided, only schedules for this course are shown and the
  /// "Create" flow carries this course forward automatically.
  final String? courseCode;
  final String? courseName;

  const AttendanceSessionListPage({
    super.key,
    this.courseCode,
    this.courseName,
  });

  bool get isScoped => courseCode != null;

  @override
  State<AttendanceSessionListPage> createState() =>
      _AttendanceSessionListPageState();
}

class _AttendanceSessionListPageState extends State<AttendanceSessionListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncActiveSessions());
  }

  // Only schedules for courses the user TEACHES are relevant here — this
  // page is for taking/managing attendance, which only makes sense for
  // courses you own. Schedules from courses you're merely enrolled in
  // (source == 'enrolled') are excluded everywhere in this page.
  List<ScheduleModel> _teachingSchedules(List<ScheduleModel> all) {
    return all.where((s) => s.source != 'enrolled').toList();
  }

  Future<void> _syncActiveSessions() async {
    if (!mounted) return;
    final schedules = _teachingSchedules(
      context.read<ScheduleProvider>().schedules,
    );
    final today = DateTime.now();
    final todayCodes = schedules
        .where((s) => _matchesDate(s, today))
        .where((s) => !widget.isScoped || s.courseCode == widget.courseCode)
        .map((s) => s.courseCode)
        .toSet();

    final provider = context.read<AttendanceProvider>();
    for (final code in todayCodes) {
      await provider.loadActiveSessionsByCourse(code);
    }
  }

  bool _matchesDate(ScheduleModel schedule, DateTime date) {
    final recurrence = schedule.recurrenceType.toLowerCase().trim();
    if (recurrence == 'none') {
      if (schedule.date == null) return false;
      final target = _parseDate(schedule.date!);
      return target != null && _isSameDay(target, date);
    }
    final start = schedule.startDate != null
        ? _parseDate(schedule.startDate!)
        : null;
    final end = schedule.endDate != null ? _parseDate(schedule.endDate!) : null;
    if (start == null || end == null) return false;
    final dateOnly = DateTime(date.year, date.month, date.day);
    if (dateOnly.isBefore(start) || dateOnly.isAfter(end)) return false;
    if (recurrence == 'daily') return true;
    if (recurrence == 'weekly') {
      if (schedule.selectedDays == null || schedule.selectedDays!.isEmpty)
        return false;
      final weekdayName = _weekdayName(date.weekday);
      return schedule.selectedDays!
          .map((d) => d.toLowerCase().trim())
          .contains(weekdayName.toLowerCase());
    }
    if (recurrence == 'monthly') {
      if (schedule.selectedDays == null || schedule.selectedDays!.isEmpty)
        return false;
      final selectedDayNumbers = schedule.selectedDays!
          .map((d) => int.tryParse(d.trim().split(' ').first))
          .whereType<int>()
          .toList();
      return selectedDayNumbers.contains(date.day);
    }
    return false;
  }

  DateTime? _parseDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr).toUtc();
      return DateTime(dt.year, dt.month, dt.day);
    } catch (_) {
      return null;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _weekdayName(int weekday) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[weekday - 1];
  }

  String _getSessionStatus(ScheduleModel schedule) {
    try {
      final now = DateTime.now();
      final sp = schedule.startTime.split(':');
      final ep = schedule.endTime.split(':');
      if (sp.length != 2 || ep.length != 2) return 'Unknown';
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
      if (now.isAfter(end)) return 'Finished';
      return 'Active';
    } catch (_) {
      return 'Unknown';
    }
  }

  Color _badgeBg(String s) {
    switch (s) {
      case 'Active':
        return const Color(0xFFEAF3DE);
      case 'Upcoming':
        return const Color(0xFFFAEEDA);
      case 'Finished':
        return const Color(0xFFFCEBEB);
      case 'Resume':
        return const Color(0xFFE3F0FF);
      default:
        return const Color(0xFFF1EFE8);
    }
  }

  Color _badgeBorder(String s) {
    switch (s) {
      case 'Active':
        return const Color(0xFF97C459);
      case 'Upcoming':
        return const Color(0xFFEF9F27);
      case 'Finished':
        return const Color(0xFFF09595);
      case 'Resume':
        return const Color(0xFF5B9BD5);
      default:
        return const Color(0xFFB4B2A9);
    }
  }

  Color _badgeText(String s) {
    switch (s) {
      case 'Active':
        return const Color(0xFF3B6D11);
      case 'Upcoming':
        return const Color(0xFF854F0B);
      case 'Finished':
        return const Color(0xFFA32D2D);
      case 'Resume':
        return const Color(0xFF1A4E8A);
      default:
        return const Color(0xFF5F5E5A);
    }
  }

  Color _parseScheduleColor(String hex) {
    try {
      final c = hex.replaceAll('#', '').trim();
      if (c.length == 6) return Color(int.parse('FF$c', radix: 16));
      if (c.length == 8) return Color(int.parse(c, radix: 16));
    } catch (_) {}
    return const Color(0xFF6B7280);
  }

  Color _onColor(Color c) =>
      c.computeLuminance() > 0.4 ? Colors.black87 : Colors.white;

  String _getCourseName(String courseCode, List<CourseModel> courses) {
    try {
      return courses.firstWhere((c) => c.courseCode == courseCode).courseName;
    } catch (_) {
      return courseCode;
    }
  }

  String _formatDate(DateTime d) {
    const wd = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const mo = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${wd[d.weekday - 1]}, ${d.day} ${mo[d.month - 1]}';
  }

  String _todayStr() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Widget _sectionHeader(String label, DateTime date, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatDate(date),
                style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
              ),
            ],
          ),
          const Spacer(),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3DE),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF97C459), width: 0.5),
              ),
              child: Text(
                '$count session${count != 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3B6D11),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 32,
            color: Colors.grey[350],
          ),
          const SizedBox(height: 8),
          Text(
            'No sessions available',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _sessionCard({
    required ScheduleModel schedule,
    required String timeStatus,
    required String courseName,
    required bool isToday,
    AttendanceSessionModel? existingSession,
  }) {
    final sc = _parseScheduleColor(schedule.color);
    final isActionable = isToday && timeStatus == 'Active';
    final hasSession = existingSession != null;
    final badgeLabel = (isActionable && hasSession) ? 'Resume' : timeStatus;
    final actionLabel = hasSession ? 'Resume' : 'Start';
    final actionIcon = hasSession
        ? Icons.play_circle_outline_rounded
        : Icons.arrow_forward_rounded;

    Future<void> onTap() async {
      if (!isActionable) return;
      if (hasSession) {
        await context.push(
          '/attendance/home/list/create/${existingSession.id}',
        );
      } else {
        await context.push(
          '/attendance/home/list/create',
          extra: {
            'courseCode': schedule.courseCode,
            'courseName': courseName,
            'courseLocation': schedule.location,
            'sessionTitle': schedule.assessmentName,
            'startTime': schedule.startTime,
            'endTime': schedule.endTime,
          },
        );
      }
      if (mounted) await _syncActiveSessions();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          color: sc.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sc.withOpacity(0.22), width: 0.5),
        ),
        clipBehavior: Clip.hardEdge,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: sc),
            Expanded(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 90, 0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              schedule.courseCode,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: sc,
                              ),
                            ),
                            Text(
                              ' • ',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                            ),
                            Expanded(
                              child: Text(
                                courseName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 13,
                              color: sc.withOpacity(0.8),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              schedule.location,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Icon(
                              Icons.access_time_rounded,
                              size: 13,
                              color: sc.withOpacity(0.8),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${schedule.startTime} – ${schedule.endTime}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isToday)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _badgeBg(badgeLabel),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _badgeBorder(badgeLabel),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          badgeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _badgeText(badgeLabel),
                          ),
                        ),
                      ),
                    ),
                  if (isActionable)
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: sc,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(actionIcon, size: 12, color: _onColor(sc)),
                            const SizedBox(width: 4),
                            Text(
                              actionLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _onColor(sc),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final todayStr = _todayStr();

    final allSchedules = context.watch<ScheduleProvider>().schedules;
    // Only courses the user TEACHES are relevant for taking attendance.
    // Schedules merely enrolled in (source == 'enrolled') are excluded
    // here regardless of whether this page is course-scoped or not.
    final teachingSchedules = _teachingSchedules(allSchedules);
    final schedules = widget.isScoped
        ? teachingSchedules
              .where((s) => s.courseCode == widget.courseCode)
              .toList()
        : teachingSchedules;
    final courses = context.watch<CourseProvider>().courses;
    final attendanceProvider = context.watch<AttendanceProvider>();

    final todayList = schedules.where((s) => _matchesDate(s, today)).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final tomorrowList =
        schedules.where((s) => _matchesDate(s, tomorrow)).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

    const headerTitle = 'Attendance Sessions';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Animated green background ──────────────────────────────
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
              decoration: const BoxDecoration(color: Color(0xFFF3F3F3)),
              child: RefreshIndicator(
                onRefresh: _syncActiveSessions,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                  children: [
                    _sectionHeader('Today', today, todayList.length),
                    if (todayList.isEmpty)
                      _emptyState()
                    else
                      ...todayList.map((s) {
                        final existing = attendanceProvider.findActiveSession(
                          courseCode: s.courseCode,
                          date: todayStr,
                          startTime: s.startTime,
                          endTime: s.endTime,
                        );
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _sessionCard(
                            schedule: s,
                            timeStatus: _getSessionStatus(s),
                            courseName: _getCourseName(s.courseCode, courses),
                            isToday: true,
                            existingSession: existing,
                          ),
                        );
                      }),

                    const SizedBox(height: 10),
                    const Divider(height: 1, thickness: 0.5),
                    const SizedBox(height: 24),

                    _sectionHeader('Tomorrow', tomorrow, tomorrowList.length),
                    if (tomorrowList.isEmpty)
                      _emptyState()
                    else
                      ...tomorrowList.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _sessionCard(
                            schedule: s,
                            timeStatus: 'Upcoming',
                            courseName: _getCourseName(s.courseCode, courses),
                            isToday: false,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
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
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: Colors.white,
                    ),
                    Expanded(
                      child: Text(
                        headerTitle,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
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
  }
}
