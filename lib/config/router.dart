import 'package:go_router/go_router.dart';
import '../screens/authentication_screen.dart';
import '../screens/start_screen.dart';
import '../screens/profile_screen.dart';
import '../providers/auth_provider.dart';
import '../screens/schedule_screen.dart';
import '../screens/assessments_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/Attendance/attendance_home_page.dart';
import '../screens/Attendance/create_attendance_session_page.dart';
import '../screens/Attendance/view_attendance_sessions_page.dart';
import '../screens/Attendance/studentAttendance_page.dart' as student_attendance;

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
    GoRoute(
      path: '/assessments',
      builder: (context, state) => const AssessmentsScreen(),
    ),
    GoRoute(path: '/profile', builder: (context, state) => ProfileScreen()),
    GoRoute(path: '/start', builder: (context, state) => StartScreen()),
    GoRoute(path: '/schedule', builder: (context, state) => ScheduleScreen()),
    GoRoute(path: '/dashboard', builder: (context, state) => DashBoardScreen()),
    GoRoute(path: '/attendance', builder: (context, state) => AttendanceHomePage()),
    GoRoute(path: '/attendance/create', builder: (context, state) => CreateAttendanceSessionPage()),
    GoRoute(path: '/attendance/sessions', builder: (context, state) => ViewAttendanceSessionsPage()),
    GoRoute(path: '/attendance/student', builder: (context, state) => student_attendance.StudentAttendancePage(studentId: 'student1', studentName: 'student1')),
  ],
);
