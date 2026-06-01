import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/router.dart';
import 'providers/auth_provider.dart';
import 'providers/course_provider.dart';
import 'providers/assessment_provider.dart';
import 'providers/schedule_provider.dart';
import 'providers/user_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await AuthProvider.loadTokens();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        ChangeNotifierProvider(
          create: (_) => AssessmentProvider()..loadAllAssessments(),
        ),
        ChangeNotifierProvider(
          create: (_) => ScheduleProvider()..loadSchedules(),
        ),
        ChangeNotifierProvider(create: (_) => UserProvider()..loadUser()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
