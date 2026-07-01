// ignore_for_file: unnecessary_underscores, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../models/course_model.dart';
import '../models/schedule_model.dart';
import '../providers/user_provider.dart';
import '../providers/course_provider.dart';
import '../providers/schedule_provider.dart';
import '../providers/assessment_provider.dart';
import '../providers/attendance_provider.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/quick_access.dart';
import '../widgets/recommendation.dart';
import '../widgets/scan_icon.dart';
import '../widgets/today_schedule.dart';
import '../widgets/floating_line_background.dart';

class DashBoardScreen extends StatefulWidget {
  const DashBoardScreen({super.key});

  @override
  State<DashBoardScreen> createState() => _DashBoardScreenState();
}

class _DashBoardScreenState extends State<DashBoardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_loadDashboardData);
  }

  Future<void> _loadDashboardData() async {
    final userProvider = context.read<UserProvider>();
    if (userProvider.user == null) {
      await userProvider.loadUser();
    }
    if (!mounted) return;

    final role = userProvider.user?.role;
    await Future.wait([
      context.read<CourseProvider>().loadCourses(role: role),
      context.read<CourseProvider>().loadAllCourses(),
      context.read<CourseProvider>().loadTeacherStudentCount(),
      context.read<AssessmentProvider>().loadAllAssessments(),
      context.read<ScheduleProvider>().loadSchedules(),
    ]);

    final userId = userProvider.user?.id;
    if (userId != null && userId.isNotEmpty) {
      await context.read<AttendanceProvider>().loadStudentSummary(userId);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final courseProvider = context.watch<CourseProvider>();
    final allCourses = courseProvider.allCourses;
    final currentUserName = user?.userName;
    final schedules = context.watch<ScheduleProvider>().schedules;
    final assessments = context.watch<AssessmentProvider>().allAssessments;
    final totalStudents = courseProvider.teacherStudentCount;

    // ── Attendance ────────────────────────────────────────────────────────
    final attendanceProvider = context.watch<AttendanceProvider>();
    final summary = attendanceProvider.attendanceSummary;
    final attendanceTotal = summary.values.fold(0, (s, v) => s + v);
    final attendanceRate = attendanceProvider.attendanceRate;

    // ── Courses ───────────────────────────────────────────────────────────
    final createdCourses = allCourses
        .where((c) => c.createdBy == currentUserName)
        .toList();

    final enrolledCourses = allCourses
        .where((c) => c.isSubscribed && c.createdBy != currentUserName)
        .toList();

    final myCoursesCount = createdCourses.length + enrolledCourses.length;

    // ── Today sessions ────────────────────────────────────────────────────
    final teachingSchedules = schedules
        .where((s) => s.source != 'enrolled')
        .toList();
    final todaySessionCount = teachingSchedules
        .where((s) => _matchesDate(s, DateTime.now()))
        .length;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          FloatingLinesBackground(
            colors: [Color(0xFF00FF88), Color(0xFF00DD66), Color(0xFF1E6B2D)],
            lineCount: 6,
            animationSpeed: 0.5,
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top bar ─────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.push('/courses/qr'),
                        icon: const Icon(
                          Icons.qr_code,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── User greeting ────────────────────────────────────────
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.push('/profile'),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color.fromARGB(255, 250, 250, 250),
                              width: 2.5,
                            ),
                            color: AppColors.secondary,
                          ),
                          child: ClipOval(
                            child: user?.photoUrl != null
                                ? Image.network(
                                    user!.photoUrl!,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: const TextStyle(
                                color: Color.fromARGB(179, 255, 255, 255),
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Text(
                              user?.userName ?? 'User',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Stat cards row 1 ─────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: DashboardStatCard(
                          icon: Icons.menu_book_outlined,
                          title: 'My Courses',
                          value: myCoursesCount.toString(),
                          color: Colors.red,
                          onTap: () => context.push('/courses'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DashboardStatCard(
                          icon: Icons.check_circle_outline,
                          title: 'My Attendance',
                          value: attendanceTotal == 0
                              ? '0%'
                              : '$attendanceRate%',
                          color: Colors.yellow,
                          onTap: () => context.push('/attendance/student'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Stat cards row 2 ─────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: DashboardStatCard(
                          icon: Icons.schedule_outlined,
                          title: 'My Schedules',
                          value: schedules.length.toString(),
                          color: Colors.orange,
                          onTap: () => context.push('/schedule'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DashboardStatCard(
                          icon: Icons.event,
                          title: 'Today Sessions',
                          value: todaySessionCount.toString(),
                          color: Colors.purple,
                          onTap: () => context.push('/attendance/home/list'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Quick access row ─────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: QuickAccessCard(
                          icon: Icon(
                            Icons.auto_stories_outlined,
                            color: AppColors.primary,
                            size: 36,
                          ),
                          title: 'Discover',
                          onTap: () => context.push('/courses/discover'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: QuickAccessCard(
                          icon: Icon(
                            Icons.fact_check_outlined,
                            color: AppColors.primary,
                            size: 36,
                          ),
                          title: 'Attendance',
                          onTap: () => context.push('/attendance'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: QuickAccessCard(
                          icon: const ScanIcon(size: 36),
                          title: 'QR Scan',
                          onTap: () => context.push('/qr_scan'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const RecommendationWidget(),
                  const TodaySchedule(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSubscribedStudents(
    BuildContext context,
    List<CourseModel> createdCourses,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SubscribedStudentsSheet(courses: createdCourses),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Subscribed Students Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _SubscribedStudentsSheet extends StatelessWidget {
  const _SubscribedStudentsSheet({required this.courses});

  final List<CourseModel> courses;

  @override
  Widget build(BuildContext context) {
    final coursesWithStudents = courses
        .where((c) => c.subscribers.isNotEmpty)
        .toList();

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Subscribed Students',
              style: TextStyle(
                color: Color(0xFF1B3B22),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            if (coursesWithStudents.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(
                  child: Text(
                    'No students subscribed yet.',
                    style: TextStyle(color: Color(0xFF718096)),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: coursesWithStudents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final course = coursesWithStudents[index];
                    return _CourseStudentsBlock(course: course);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CourseStudentsBlock extends StatelessWidget {
  const _CourseStudentsBlock({required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${course.courseCode} - ${course.courseName}',
                  style: const TextStyle(
                    color: Color(0xFF1B3B22),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${course.subscribers.length}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...course.subscribers.map(
            (student) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      student.userName,
                      style: const TextStyle(
                        color: Color(0xFF2D3748),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      student.email,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF718096),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
