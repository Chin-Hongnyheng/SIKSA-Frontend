import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../screens/Authentication_Screen.dart';
import '../screens/start_screen.dart';
import '../screens/profile_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../screens/schedule_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/loading_screen.dart';
import '../screens/assessment_screen.dart';
import '../screens/courses_screen.dart';
import '../screens/student_dashboard_screen.dart';
import '../screens/teacher_dashboard_screen.dart';
import '../screens/Attendance/attendance_home_page.dart';
import '../screens/Attendance/create_attendance_session_page.dart';
import '../screens/Attendance/view_attendance_sessions_page.dart';
import '../screens/Attendance/studentAttendance_page.dart'
    as student_attendance;

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

String getUserField(dynamic user, List<String> fields, String fallback) {
  if (user == null) return fallback;

  // Try from toJson() first
  try {
    final json = user.toJson();

    if (json is Map) {
      for (final field in fields) {
        final value = json[field];

        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
    }
  } catch (_) {}

  // Try common direct model properties
  for (final field in fields) {
    try {
      if (field == 'id' && user.id != null) return user.id.toString();
    } catch (_) {}

    try {
      if (field == '_id' && user.id != null) return user.id.toString();
    } catch (_) {}

    try {
      if (field == 'studentId' && user.studentId != null) {
        return user.studentId.toString();
      }
    } catch (_) {}

    try {
      if (field == 'userName' && user.userName != null) {
        return user.userName.toString();
      }
    } catch (_) {}

    try {
      if (field == 'name' && user.name != null) {
        return user.name.toString();
      }
    } catch (_) {}

    try {
      if (field == 'fullName' && user.fullName != null) {
        return user.fullName.toString();
      }
    } catch (_) {}

    try {
      if (field == 'email' && user.email != null) {
        return user.email.toString();
      }
    } catch (_) {}
  }

  return fallback;
}

final GoRouter router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final loggedIn = AuthProvider.accessToken != null;
    final path = state.uri.toString();
    if (!loggedIn && path != '/auth' && path != '/start') {
      return '/';
    }

    if (loggedIn && (path == '/' || path == '/auth' || path == '/start')) {
      return '/dashboard';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => LoadingScreen()),
    GoRoute(path: '/start', builder: (context, state) => StartScreen()),
    GoRoute(path: '/auth', builder: (context, state) => AuthenticationScreen()),
    GoRoute(
      path: '/assessments',
      builder: (context, state) => const AssessmentsScreen(),
    ),
    GoRoute(path: '/profile', builder: (context, state) => ProfileScreen()),
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
