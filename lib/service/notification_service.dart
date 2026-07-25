import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import '../config/router.dart'; // your GoRouter instance
import 'dart:convert';

import '../models/notification_model.dart';
import '../core/utils/api_helper.dart';

class NotificationService {
  static final _fln = FlutterLocalNotificationsPlugin();

  static GraphQLClient _authClient() {
    final Link authLink = HttpLink(
      ApiHelper.resolveUrl(dotenv.env['GRAPHQL_URL']!),
      defaultHeaders: {"Authorization": "Bearer ${AuthProvider.accessToken}"},
    );
    return GraphQLClient(link: authLink, cache: GraphQLCache());
  }

  static const String _updateFcmTokenMutation = r'''
    mutation UpdateProfile($input: UpdateUserInput!) {
      updateProfile(input: $input) {
        message
      }
    }
  ''';

  /// Call this EARLY — e.g. when user taps "Get Started" on the start screen.
  /// Just asks OS permission and sets up local notification display + tap handling.
  /// No backend calls here (user isn't authenticated yet).
  static Future<bool> requestPermission(
    NotificationProvider notifProvider,
  ) async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized;
    notifProvider.setPermissionGranted(granted);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _fln.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload == null) return;
        try {
          final decoded = jsonDecode(response.payload!) as Map<String, dynamic>;
          _routeToScreen(decoded['screen'] as String?, decoded);
        } catch (_) {
          // Fallback for older/plain-string payloads
          _routeToScreen(response.payload);
        }
      },
    );

    return granted;
  }

  /// Call this AFTER login succeeds — registers the device token with the
  /// backend and sets up message listeners. Requires AuthProvider.accessToken
  /// to already be set.
  static Future<void> registerDevice(NotificationProvider notifProvider) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _sendTokenToBackend(token);
    FirebaseMessaging.instance.onTokenRefresh.listen(_sendTokenToBackend);

    // App open: show manually
    FirebaseMessaging.onMessage.listen((message) {
      notifProvider.addMessage(message);
      _fln.show(
        id: message.hashCode,
        title: message.notification?.title,
        body: message.notification?.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'default_channel',
            'Default',
            channelDescription: 'Default notification channel',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: jsonEncode(message.data),
      );
    });

    // App backgrounded, user taps system notification
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      notifProvider.addMessage(message);
      _routeToScreen(message.data['screen'], message.data);
    });

    // App was killed, opened via notification tap
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _routeToScreen(initial.data['screen'], initial.data);
  }

  /// Generic router — add cases here as new modules add notification types.
  static void _routeToScreen(String? screen, [Map<String, dynamic>? data]) {
    if (screen == null) return;
    switch (screen) {
      case 'login':
        router.go('/dashboard');
        break;
      case 'courseDetail':
        final courseCode = data?['courseCode'];
        if (courseCode != null) {
          router.go('/courses', extra: {'highlightCourseCode': courseCode});
        } else {
          router.go('/courses');
        }
        break;
      case 'markAttendance':
        final courseCode = data?['courseCode'];
        router.go('/attendance/mark', extra: {'courseCode': courseCode});
        break;
      default:
        router.go('/dashboard');
    }
  }

  static Future<void> _sendTokenToBackend(String token) async {
    try {
      final authLink = HttpLink(
        dotenv.env['GRAPHQL_URL']!,
        defaultHeaders: {"Authorization": "Bearer ${AuthProvider.accessToken}"},
      );
      final authClient = GraphQLClient(link: authLink, cache: GraphQLCache());
      await authClient.mutate(
        MutationOptions(
          document: gql(_updateFcmTokenMutation),
          variables: {
            'input': {'fcmToken': token},
          },
        ),
      );
    } catch (_) {
      // retry later / log
    }
  }

  static const String _getMyNotificationsQuery = r'''
    query GetMyNotifications {
      getMyNotifications {
        id
        title
        body
        data
        isUnread
        createdAt
      }
    }
  ''';

  static const String _markNotificationReadMutation = r'''
    mutation MarkNotificationRead($id: String!) {
      markNotificationRead(id: $id) {
        success
      }
    }
  ''';

  static const String _markAllNotificationsReadMutation = r'''
    mutation MarkAllNotificationsRead {
      markAllNotificationsRead {
        success
      }
    }
  ''';

  static Future<List<NotificationModel>> fetchNotifications() async {
    final client = _authClient();
    final result = await client.query(
      QueryOptions(
        document: gql(_getMyNotificationsQuery),
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final data = result.data?['getMyNotifications'] as List?;
    if (data == null) return [];

    return data.map((json) => NotificationModel.fromJson(json)).toList();
  }

  static Future<void> markNotificationRead(String id) async {
    final client = _authClient();
    await client.mutate(
      MutationOptions(
        document: gql(_markNotificationReadMutation),
        variables: {'id': id},
      ),
    );
  }

  static Future<void> markAllNotificationsRead() async {
    final client = _authClient();
    await client.mutate(
      MutationOptions(
        document: gql(_markAllNotificationsReadMutation),
      ),
    );
  }
}
