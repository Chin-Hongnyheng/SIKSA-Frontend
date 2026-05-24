// lib/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/notification_card.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color headerGreen = const Color(0xFF2E7D32);
    final Color primaryGreen = const Color(0xFF388E3C);
    final Color backgroundGray = const Color(0xFFF9F9F9);
    final Color sectionHeaderGray = const Color(0xFF757575);

    // Mock Data based on the image
    final List<Map<String, dynamic>> newNotifications = [
      {
        'title': 'Quiz have been created',
        'message': 'You can do your quiz now. Please be on time.',
        'time': '1 hours ago',
        'isUnread': true,
      },
      {
        'title': 'Scores published',
        'message': 'You can check and see your scores for now.',
        'time': '2 hours ago',
        'isUnread': true,
      },
    ];

    final List<Map<String, dynamic>> earlierNotifications = [
      {
        'title': 'Midterm exam scores',
        'message': 'Check for your exam scores now.',
        'time': 'Yesterday, 5:00 PM',
        'isUnread': false,
      },
      {
        'title': 'Scores published',
        'message': 'You can check and see your scores for now.',
        'time': 'Today, 10:00 AM',
        'isUnread': false,
      },
    ];

    return Scaffold(
      backgroundColor: backgroundGray,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Header
            Container(
              color: headerGreen,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10,
                bottom: 15,
                left: 16,
                right: 16,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      // Navigate back
                      context.pop(context);
                    },
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Notifications',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance for center alignment
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mark all read action
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          // Handle mark all read action
                        },
                        child: Text(
                          'Mark all read',
                          style: TextStyle(
                            color: primaryGreen,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // "New" Section
                    Text(
                      'New',
                      style: TextStyle(
                        fontSize: 20,
                        color: sectionHeaderGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...newNotifications.map(
                      (notif) => NotificationCard(
                        title: notif['title'],
                        message: notif['message'],
                        time: notif['time'],
                        isUnread: notif['isUnread'],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // "Earlier" Section
                    Text(
                      'Earlier',
                      style: TextStyle(
                        fontSize: 20,
                        color: sectionHeaderGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...earlierNotifications.map(
                      (notif) => NotificationCard(
                        title: notif['title'],
                        message: notif['message'],
                        time: notif['time'],
                        isUnread: notif['isUnread'],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
