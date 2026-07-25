import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/attendance_session_model.dart';
import '../screens/Attendance/session_attendance_page.dart';
import '../screens/Attendance/student_course_attendance_report_page.dart';
import '../screens/authentication_screen.dart';
import '../screens/scan_screen.dart';

import '../screens/start_screen.dart';
import '../screens/profile_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../screens/schedule_screen.dart';
import '../screens/loading_screen.dart';
import '../screens/assessment_screen.dart';
import '../screens/courses_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/Attendance/attendance_home_page.dart';
import '../screens/Attendance/attendance_session_list.dart';
import '../screens/Attendance/create_attendance_session_page.dart';
import '../screens/Attendance/studentAttendance_page.dart'
    as student_attendance;
import '../screens/grading_screen.dart';
import '../screens/Attendance/attendance_screen.dart';
import '../screens/Attendance/attendance_session_report_page.dart';
import '../screens/course_qr_screen.dart';
import '../screens/Attendance/student_mark_attendance_page.dart';
import '../screens/notifications_screen.dart';


String getUserField(dynamic user, List<String> fields, String fallback) {
  if (user == null) return fallback;

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
      path: '/dashboard',
      builder: (context, state) => const DashBoardScreen(),
    ),
    GoRoute(path: '/profile', builder: (context, state) => ProfileScreen()),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(path: '/schedule', builder: (context, state) => ScheduleScreen()),
    GoRoute(
      path: '/assessments',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return AssessmentsScreen(
          preselectedCourseCode: extra?['courseCode'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/courses',
      builder: (context, state) =>
          const CoursesScreen(mode: CourseScreenMode.my),
    ),
    GoRoute(
      path: '/courses/discover',
      builder: (context, state) =>
          const CoursesScreen(mode: CourseScreenMode.discover),
    ),
    GoRoute(
      path: '/courses/qr',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return CourseQrScreen(
          preselectedCourseCode: extra?['courseCode'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/my-courses',
      builder: (context, state) => const CoursesScreen(),
    ),
    GoRoute(
      path: '/qr_scan',
      builder: (context, state) => const QrScanScreen(),
    ),
    GoRoute(
      path: '/attendance',
      builder: (context, state) => AttendanceScreen(),
    ),
    GoRoute(
      path: '/attendance/home',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return AttendanceHomePage(
          courseCode: extra?['courseCode'] as String?,
          courseName: extra?['courseName'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/attendance/report',
      builder: (context, state) {
        final session = state.extra as AttendanceSessionModel;
        return AttendanceSessionReportPage(session: session);
      },
    ),
    GoRoute(
      path: '/attendance/home/list',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return AttendanceSessionListPage(
          courseCode: extra?['courseCode'] as String?,
          courseName: extra?['courseName'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/attendance/home/list/create',
      builder: (context, state) => CreateAttendanceSessionPage(
        scheduleData: state.extra as Map<String, dynamic>?,
      ),
    ),
    GoRoute(
      path: '/attendance/home/list/create/:sessionId',
      builder: (context, state) {
        final sessionId = state.pathParameters['sessionId']!;
        return SessionAttendancePage(sessionId: sessionId);
      },
    ),
    GoRoute(
      path: '/attendance/student',
      builder: (context, state) {
        final userProvider = context.read<UserProvider>();
        final user = userProvider.user;

        final studentId = getUserField(user, [
          'id',
          '_id',
          'studentId',
        ], 'student1');
        final studentName = getUserField(user, [
          'userName',
          'name',
          'fullName',
          'email',
        ], 'Student');

        return student_attendance.StudentAttendancePage(
          studentId: studentId,
          studentName: studentName,
        );
      },
    ),
    GoRoute(
      path: '/attendance/student/course-report',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return StudentCourseAttendanceReportPage(
          studentId: extra['studentId'] as String,
          studentName: extra['studentName'] as String,
          courseCode: extra['courseCode'] as String,
          courseName: extra['courseName'] as String,
        );
      },
    ),
    GoRoute(
      path: '/attendance/mark',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return StudentMarkAttendancePage(
          courseCode: extra?['courseCode'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/grading',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return GradingScreen(
          preselectedCourseCode: extra?['courseCode'] as String?,
        );
      },
    ),
  ],
);
