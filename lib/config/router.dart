import 'package:go_router/go_router.dart';
import '../screens/authentication.dart';
import '../screens/start_screen.dart';
import '../screens/profile_screen.dart';
import '../providers/auth_provider.dart';
import '../screens/schedule_screen.dart';
import '../screens/assessments_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/loading_screen.dart';

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
    GoRoute(path: '/dashboard', builder: (context, state) => DashBoardScreen()),
  ],
);
