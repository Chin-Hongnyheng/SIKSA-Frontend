import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../providers/user_provider.dart';
import '../providers/course_provider.dart';
import '../providers/schedule_provider.dart';
import '../providers/assessment_provider.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/quick_access.dart';
import '../widgets/scan_icon.dart';
import '../widgets/today_schedule.dart';

class DashBoardScreen extends StatefulWidget {
  const DashBoardScreen({super.key});

  @override
  State<DashBoardScreen> createState() => _DashBoardScreenState();
}

class _DashBoardScreenState extends State<DashBoardScreen> {
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
    final courses = context.watch<CourseProvider>().courses;
    final schedules = context.watch<ScheduleProvider>().schedules;
    final assessments = context.watch<AssessmentProvider>().assessments;

    return Scaffold(
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
                        context.push('assessments');
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
          ),
        ),
      ),
    );
  }
}
