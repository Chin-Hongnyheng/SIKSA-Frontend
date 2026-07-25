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

    await Future.wait([
      context.read<CourseProvider>().loadCourses(),
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

  // ── Smart Attendance navigation ─────────────────────────────────────────
  //
  // - No teaching courses, only enrolled  → go straight to Mark Attendance
  // - Teaching courses, none enrolled     → go straight to Manage Attendance
  // - Both teaching & enrolled            → show the picker (Attendance hub)
  // - Neither                              → recommend discovering courses
  void _handleAttendanceTap({
    required bool hasTeaching,
    required bool hasEnrolled,
  }) {
    if (hasTeaching && hasEnrolled) {
      context.push('/attendance');
    } else if (hasTeaching && !hasEnrolled) {
      context.push('/attendance/home');
    } else if (!hasTeaching && hasEnrolled) {
      context.push('/attendance/mark');
    } else {
      _showNoCoursesSheet();
    }
  }

  void _showNoCoursesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NoCoursesSheet(
        onDiscover: () {
          Navigator.of(context).pop();
          context.push('/courses/discover');
        },
        onCreate: () {
          Navigator.of(context).pop();
          context.push('/courses');
        },
      ),
    );
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
    final hasTeaching = createdCourses.isNotEmpty;
    final hasEnrolled = enrolledCourses.isNotEmpty;

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top bar ─────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
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
                  ),

                  const SizedBox(height: 12),

                  // ── User greeting ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
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
                  ),

                  const SizedBox(height: 24),

                  // ── Stats + Quick Access, wrapped in one styled panel ────
                  // Outer gutter (panel ↔ screen) is small (8px) so the
                  // panel stretches almost full screen width. Inner gutter
                  // (cards ↔ panel edge) is a small fixed 10px so the
                  // cards get clean breathing room from the rounded
                  // corners instead of touching them directly.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // ── Stat cards row 1 ─────────────────────────────
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
                                  onTap: () =>
                                      context.push('/attendance/student'),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // ── Stat cards row 2 ─────────────────────────────
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
                                  onTap: () =>
                                      context.push('/attendance/home/list'),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // ── Quick access row ─────────────────────────────
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
                                  onTap: () =>
                                      context.push('/courses/discover'),
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
                                  onTap: () => _handleAttendanceTap(
                                    hasTeaching: hasTeaching,
                                    hasEnrolled: hasEnrolled,
                                  ),
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
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: const [TodaySchedule(), RecommendationWidget()],
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
// No Courses Sheet — shown when user has neither teaching nor enrolled courses
// ─────────────────────────────────────────────────────────────────────────────

class _NoCoursesSheet extends StatelessWidget {
  const _NoCoursesSheet({required this.onDiscover, required this.onCreate});

  final VoidCallback onDiscover;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    // Extend the white background all the way to the bottom of the
    // screen (behind the home indicator / gesture bar) instead of
    // stopping at the safe area, so there's no gap showing the scrim.
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 12, 20, 28 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fact_check_outlined,
                color: AppColors.primary,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Courses Yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B3B22),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You need to be teaching or enrolled in a course before you '
            'can take or manage attendance. Get started below.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF718096)),
          ),
          const SizedBox(height: 24),

          // ── Discover / enroll in a course ──────────────────────────
          _ActionTile(
            icon: Icons.auto_stories_outlined,
            iconColor: Colors.blue,
            title: 'Discover Courses',
            subtitle: 'Browse and enroll in a course as a student',
            onTap: onDiscover,
          ),
          const SizedBox(height: 12),

          // ── Create a course to teach ───────────────────────────────
          _ActionTile(
            icon: Icons.add_box_outlined,
            iconColor: Colors.green,
            title: 'Create a Course',
            subtitle: 'Start teaching by creating your own course',
            onTap: onCreate,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7FAF7),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B3B22),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_right_rounded,
                color: Color(0xFFA9A7A7),
              ),
            ],
          ),
        ),
      ),
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

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      padding: EdgeInsets.fromLTRB(18, 12, 18, 22 + bottomInset),
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
