import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../screens/authentication_screen.dart';
import '../screens/start_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../screens/schedule_screen.dart';
import '../screens/assessment_screen.dart';
import '../screens/courses_screen.dart';
import '../screens/student_dashboard_screen.dart';
import '../screens/teacher_dashboard_screen.dart';

Widget _dashboardForRole(BuildContext context) {
  final userProvider = context.watch<UserProvider>();
  final role = userProvider.user?.role.trim().toLowerCase();

  if (userProvider.isLoading && userProvider.user == null) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  if (role == 'student') {
    return const StudentDashBoardScreen();
  }

  return const TeacherDashBoardScreen();
}

final GoRouter router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final loggedIn = AuthProvider.accessToken != null;
    final path = state.uri.toString();
    if (!loggedIn && path != '/auth' && path != '/') {
      return '/';
    }
    if (loggedIn && (path == '/' || path == '/auth' || path == '/start')) {
      return '/dashboard';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => StartScreen()),
    GoRoute(path: '/auth', builder: (context, state) => AuthenticationScreen()),
    GoRoute(path: '/home', builder: (context, state) => HomeScreen()),
    GoRoute(
      path: '/assessments',
      builder: (context, state) => const AssessmentsScreen(),
    ),
    GoRoute(path: '/profile', builder: (context, state) => ProfileScreen()),
    GoRoute(path: '/start', builder: (context, state) => StartScreen()),
    GoRoute(path: '/schedule', builder: (context, state) => ScheduleScreen()),
    GoRoute(
      path: '/course',
      builder: (context, state) => const CoursesScreen(),
    ),
    GoRoute(
      path: '/courses',
      builder: (context, state) => const CoursesScreen(),
    ),
    GoRoute(
      path: '/my-courses',
      builder: (context, state) =>
          const CoursesScreen(onlySubscribed: true, showSearch: true),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => _dashboardForRole(context),
    ),
    GoRoute(
      path: '/teacher-dashboard',
      builder: (context, state) => const TeacherDashBoardScreen(),
    ),
    GoRoute(
      path: '/student-dashboard',
      builder: (context, state) => const StudentDashBoardScreen(),
    ),
  ],
);
