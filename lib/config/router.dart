import 'package:go_router/go_router.dart';
import '../screens/Authentication_Screen.dart';
import '../screens/Start_Screen.dart';
import '../screens/Home_Screen.dart';
import '../screens/Profile_Screen.dart';
import '../providers/auth_provider.dart';
import '../screens/Schedule_Screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final loggedIn = AuthProvider.accessToken != null;
    final path = state.uri.toString();

    if (loggedIn) return '/schedule';
    if (path == '/auth') return null;
    return '/';
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => StartScreen()),
    GoRoute(path: '/auth', builder: (context, state) => AuthenticationScreen()),
    GoRoute(path: '/home', builder: (context, state) => HomeScreen()),
    GoRoute(path: '/profile', builder: (context, state) => ProfileScreen()),
    GoRoute(path: '/start', builder: (context, state) => StartScreen()),
    GoRoute(path: '/schedule', builder: (context, state) => ScheduleScreen()),
  ],
);
