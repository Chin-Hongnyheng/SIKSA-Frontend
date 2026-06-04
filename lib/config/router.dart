import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';

import '../screens/authentication_screen.dart';
import '../screens/start_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/schedule_screen.dart';
import '../screens/assessments_screen.dart';
import '../screens/dashboard_screen.dart';

import '../screens/Attendance/attendance_home_page.dart';
import '../screens/Attendance/create_attendance_session_page.dart';
import '../screens/Attendance/view_attendance_sessions_page.dart';
import '../screens/Attendance/studentAttendance_page.dart'
    as student_attendance;

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

    if (!loggedIn && path != '/auth' && path != '/') {
      return '/';
    }

    if (loggedIn && (path == '/' || path == '/auth' || path == '/start')) {
      return '/dashboard';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => StartScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => AuthenticationScreen(),
    ),
    GoRoute(
      path: '/assessments',
      builder: (context, state) => const AssessmentsScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => ProfileScreen(),
    ),
    GoRoute(
      path: '/start',
      builder: (context, state) => StartScreen(),
    ),
    GoRoute(
      path: '/schedule',
      builder: (context, state) => ScheduleScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => DashBoardScreen(),
    ),
    GoRoute(
      path: '/attendance',
      builder: (context, state) => AttendanceHomePage(),
    ),
    GoRoute(
      path: '/attendance/create',
      builder: (context, state) => CreateAttendanceSessionPage(),
    ),
    GoRoute(
      path: '/attendance/sessions',
      builder: (context, state) => ViewAttendanceSessionsPage(),
    ),
    GoRoute(
      path: '/attendance/student',
      builder: (context, state) {
        final userProvider = context.read<UserProvider>();
        final user = userProvider.user;

        final studentId = getUserField(
          user,
          ['id', '_id', 'studentId'],
          'student1',
        );

        final studentName = getUserField(
          user,
          ['userName', 'name', 'fullName', 'email'],
          'Student',
        );

        return student_attendance.StudentAttendancePage(
          studentId: studentId,
          studentName: studentName,
        );
      },
    ),
  ],
);