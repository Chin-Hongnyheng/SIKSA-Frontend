// lib/widgets/notification_card_widget.dart
import 'package:flutter/material.dart';

class NotificationCard extends StatelessWidget {
  final String title;
  final String message;
  final String time;
  final bool isUnread;

  const NotificationCard({
    super.key,
    required this.title,
    required this.message,
    required this.time,
    this.isUnread = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = const Color(0xFF388E3C);
    final Color textGray = const Color(0xFF9E9E9E);
    final Color darkText = const Color(0xFF212121);

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.04),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bell Icon
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryGreen, width: 1.5),
            ),
            child: Icon(
              Icons.notifications_none,
              color: primaryGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Content Area
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: primaryGreen,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: darkText,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Bottom row with Time and Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      time,
                      style: TextStyle(color: textGray, fontSize: 12),
                    ),
                    Row(
                      children: [
                        if (isUnread) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              border: Border.all(color: primaryGreen),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              'Mark read',
                              style: TextStyle(
                                color: primaryGreen,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Icon(
                          Icons.delete_outline,
                          color: Colors.black54,
                          size: 18,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Unread Dot Indicator
          if (isUnread)
            Container(
              margin: const EdgeInsets.only(left: 8.0, top: 4.0),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: primaryGreen,
                shape: BoxShape.circle,
              ),
            )
          else
            const SizedBox(width: 10), // Placeholder to keep alignment consistent
        ],
      ),
    );
  }
}