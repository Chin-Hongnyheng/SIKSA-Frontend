import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:frontend/firebase_options.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/router.dart';
import 'providers/auth_provider.dart';
import 'providers/course_provider.dart';
import 'providers/assessment_provider.dart';
import 'providers/schedule_provider.dart';
import 'providers/setting_provider.dart';
import 'providers/user_provider.dart';
import 'providers/attendance_provider.dart';
<<<<<<< HEAD
import 'providers/grade_provider.dart';
=======
import 'providers/notification_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}
>>>>>>> 856b57c5ea4757de77c69653abe22b2f3cbd0602

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await AuthProvider.loadTokens();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
<<<<<<< HEAD
  try {
    await GoogleSignIn.instance.initialize();
  } catch (e) {
    debugPrint('Google SignIn initialization skipped or failed: $e');
  }
=======
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await GoogleSignIn.instance.initialize();
>>>>>>> 856b57c5ea4757de77c69653abe22b2f3cbd0602
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        ChangeNotifierProvider(
          create: (_) => AssessmentProvider()
            ..loadAllAssessments()
            ..loadFolders(),
        ),
        ChangeNotifierProvider(
          create: (_) => ScheduleProvider()..loadSchedules(),
        ),
        ChangeNotifierProvider(create: (_) => UserProvider()..loadUser()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => GradeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
<<<<<<< HEAD

=======
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
>>>>>>> 856b57c5ea4757de77c69653abe22b2f3cbd0602
      ],
      child: const MyApp(),
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
