// ignore_for_file: unnecessary_underscores, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../models/course_model.dart';
import '../providers/user_provider.dart';
import '../providers/course_provider.dart';
import '../providers/schedule_provider.dart';
import '../providers/assessment_provider.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/quick_access.dart';
import '../widgets/scan_icon.dart';
import '../widgets/today_schedule.dart';
import '../widgets/floating_line_background.dart';

class DashBoardScreen extends StatefulWidget {
  final bool isStudentDashboard;

  const DashBoardScreen({super.key, this.isStudentDashboard = false});

  @override
  State<DashBoardScreen> createState() => _DashBoardScreenState();
}

class _DashBoardScreenState extends State<DashBoardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_loadDashboardCourses);
  }

  Future<void> _loadDashboardCourses() async {
    final userProvider = context.read<UserProvider>();

    if (userProvider.user == null) {
      await userProvider.loadUser();
    }

    if (!mounted) return;

    final role = userProvider.user?.role;
    await Future.wait([
      context.read<CourseProvider>().loadCourses(role: role),
      context.read<AssessmentProvider>().loadAllAssessments(),
    ]);

    final normalizedRole = role?.trim().toLowerCase();
    if (normalizedRole == 'teacher' || normalizedRole == 'admin') {
      await context.read<CourseProvider>().loadTeacherStudentCount();
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getUserRole(dynamic user) {
    if (user == null) return '';

    try {
      final value = user.role;
      if (value != null) return value.toString().toLowerCase();
    } catch (_) {}

    try {
      final value = user.userType;
      if (value != null) return value.toString().toLowerCase();
    } catch (_) {}

    try {
      final value = user.accountType;
      if (value != null) return value.toString().toLowerCase();
    } catch (_) {}

    try {
      final value = user.type;
      if (value != null) return value.toString().toLowerCase();
    } catch (_) {}

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final courseProvider = context.watch<CourseProvider>();
    final courses = courseProvider.courses;
    final schedules = context.watch<ScheduleProvider>().schedules;
    final assessments = context.watch<AssessmentProvider>().allAssessments;
    final totalStudents = courseProvider.teacherStudentCount;
    final myCourseCount = widget.isStudentDashboard
        ? courses.where((course) => course.isSubscribed).length
        : courses.length;

    return Scaffold(
<<<<<<< HEAD
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          FloatingLinesBackground(
            colors: [Color(0xFF00FF88), Color(0xFF00DD66), Color(0xFF1E6B2D)],
            lineCount: 6,
            animationSpeed: 0.5,
=======
      backgroundColor: AppColors.secondary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    onPressed: () {},
                    icon: const Icon(
                      Icons.qr_code,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

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
                            ? Image.network(user!.photoUrl!, fit: BoxFit.cover)
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

              Row(
                children: [
                  Expanded(
                    child: DashboardStatCard(
                      icon: Icons.menu_book_outlined,
                      title: 'My Courses',
                      value: courses.length.toString(),
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 16), // Middle gap
                  Expanded(
                    child: DashboardStatCard(
                      icon: Icons.assignment_outlined,
                      title: 'My Assessments',
                      value: assessments.length.toString(),
                      color: Colors.yellow,
                      onTap: () {
                        context.push('/assessments');
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DashboardStatCard(
                      icon: Icons.schedule_outlined,
                      title: 'My Schedules',
                      value: schedules.length.toString(),
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DashboardStatCard(
                      icon: Icons.school_outlined,
                      title: 'Total Students',
                      value: '12',
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: QuickAccessCard(
                      icon: Icon(
                        Icons.auto_stories_outlined,
                        color: AppColors.primary,
                        size: 36,
                      ),
                      title: 'Course',
                      onTap: () {
                        context.push('/course');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickAccessCard(
                      icon: Icon(
                        Icons.article_outlined,
                        color: AppColors.primary,
                        size: 36,
                      ),
                      title: 'Assessments',
                      onTap: () {
                        context.push('/assessments');
                      },
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
                      onTap: () {
                        final currentUser = context.read<UserProvider>().user;
                        final role = _getUserRole(currentUser);

                        if (role == 'teacher' || role == 'instructor') {
                          context.push('/attendance');
                        } else if (role == 'student') {
                          context.push('/attendance/student');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'User role not found. Current role: ${role.isEmpty ? "empty" : role}',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: QuickAccessCard(
                      icon: const ScanIcon(size: 36),
                      title: 'QR Scan',
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickAccessCard(
                      icon: Icon(
                        Icons.grid_view_rounded,
                        color: AppColors.primary,
                        size: 36,
                      ),
                      title: 'Management',
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickAccessCard(
                      icon: Icon(
                        Icons.event_note_outlined,
                        color: AppColors.primary,
                        size: 36,
                      ),
                      title: 'Schedule',
                      onTap: () {
                        context.push('/schedule');
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const TodaySchedule(),
            ],
>>>>>>> Phirum
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        onPressed: () {},
                        icon: const Icon(
                          Icons.qr_code,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

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

                  Row(
                    children: [
                      Expanded(
                        child: DashboardStatCard(
                          icon: Icons.menu_book_outlined,
                          title: 'My Courses',
                          value: myCourseCount.toString(),
                          color: Colors.red,
                          onTap: () {
                            if (widget.isStudentDashboard) {
                              context.push('/my-courses');
                            } else {
                              context.push('/courses');
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DashboardStatCard(
                          icon: Icons.assignment_outlined,
                          title: 'My Assessments',
                          value: assessments.length.toString(),
                          color: Colors.yellow,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: DashboardStatCard(
                          icon: Icons.schedule_outlined,
                          title: 'My Schedules',
                          value: schedules.length.toString(),
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DashboardStatCard(
                          icon: widget.isStudentDashboard
                              ? Icons.fact_check_outlined
                              : Icons.school_outlined,
                          title: widget.isStudentDashboard
                              ? 'My Attendances'
                              : 'Total Students',
                          value: widget.isStudentDashboard
                              ? '0'
                              : totalStudents.toString(),
                          color: Colors.blue,
                          onTap: widget.isStudentDashboard
                              ? null
                              : () => _showSubscribedStudents(context, courses),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: QuickAccessCard(
                          icon: Icon(
                            Icons.auto_stories_outlined,
                            color: AppColors.primary,
                            size: 36,
                          ),
                          title: 'Course',
                          onTap: () => context.push('/courses'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: QuickAccessCard(
                          icon: Icon(
                            Icons.article_outlined,
                            color: AppColors.primary,
                            size: 36,
                          ),
                          title: 'Assessments',
                          onTap: () => context.push('assessments'),
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
                          onTap: () => context.push('attendance'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: QuickAccessCard(
                          icon: const ScanIcon(size: 36),
                          title: 'QR Scan',
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: QuickAccessCard(
                          icon: Icon(
                            Icons.grade_outlined,
                            color: AppColors.primary,
                            size: 36,
                          ),
                          title: 'Grade',
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: QuickAccessCard(
                          icon: Icon(
                            Icons.event_note_outlined,
                            color: AppColors.primary,
                            size: 36,
                          ),
                          title: 'Schedule',
                          onTap: () => context.push('/schedule'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
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
    List<CourseModel> courses,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SubscribedStudentsSheet(courses: courses),
    );
  }
}

class _SubscribedStudentsSheet extends StatelessWidget {
  const _SubscribedStudentsSheet({required this.courses});

  final List<CourseModel> courses;

  @override
  Widget build(BuildContext context) {
    final coursesWithStudents = courses
        .where((course) => course.subscribers.isNotEmpty)
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
          ...course.subscribers
              .map(
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
              )
              .toList(),
        ],
      ),
    );
  }
}
