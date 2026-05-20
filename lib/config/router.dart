import 'package:frontend/screens/Profile_Screen.dart';
import 'package:go_router/go_router.dart';

import '../screens/Authentication_Screen.dart';
import '../screens/Start_Screen.dart';
import '../screens/Home_Screen.dart';
import '../screens/assessments_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => StartScreen()),
    GoRoute(path: '/auth', builder: (context, state) => AuthenticationScreen()),
    GoRoute(path: '/home', builder: (context, state) => HomeScreen()),
    GoRoute(
      path: '/assessments',
      builder: (context, state) => const AssessmentsScreen(),
    ),
    GoRoute(path: '/profile', builder: (context, state) => ProfileScreen()),
  ],
);
