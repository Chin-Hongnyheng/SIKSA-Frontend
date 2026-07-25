import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/notification_card.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  String _formatTime(DateTime? time) {
    if (time == null) return 'Just now';
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 2) {
      return 'Yesterday, ${DateFormat.jm().format(time)}';
    }
    return DateFormat('MMM d, yyyy h:mm a').format(time);
  }

  @override
  Widget build(BuildContext context) {
    final Color headerGreen = const Color(0xFF2E7D32);
    final Color primaryGreen = const Color(0xFF388E3C);
    final Color backgroundGray = const Color(0xFFF9F9F9);
    final Color sectionHeaderGray = const Color(0xFF757575);

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
                      context.pop();
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
              child: Consumer<NotificationProvider>(
                builder: (context, provider, child) {
                  final messages = provider.messages;

                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (messages.isEmpty) {
                    return const Center(
                      child: Text(
                        'No notifications yet.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Mark all read action
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () {
                              provider.clearUnread();
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

                        Text(
                          'Recent',
                          style: TextStyle(
                            fontSize: 20,
                            color: sectionHeaderGray,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),

                        ...messages.map((msg) {
                          return GestureDetector(
                            onTap: () {
                              if (msg.isUnread) provider.markAsRead(msg.id);
                              // Can also route based on msg.data
                            },
                            child: NotificationCard(
                              title: msg.title,
                              message: msg.body,
                              time: _formatTime(msg.createdAt),
                              isUnread: msg.isUnread,
                            ),
                          );
                        }),

                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

