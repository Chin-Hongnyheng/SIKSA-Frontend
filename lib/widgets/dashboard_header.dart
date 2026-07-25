import 'package:flutter/material.dart';

class DashboardHeader extends StatelessWidget {
  final String name;
  final String subtitle;
  final String? avatarUrl;
  final VoidCallback? onBellPressed;

  const DashboardHeader({
    super.key,
    required this.name,
    required this.subtitle,
    this.avatarUrl,
    this.onBellPressed,
  });

  @override
  Widget build(BuildContext context) {
    final Color headerGreen = const Color(0xFF2E7D32);

    return Container(
      color: headerGreen,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 15,
        left: 16,
        right: 16,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundImage: avatarUrl != null
                ? NetworkImage(avatarUrl!)
                : null,
            backgroundColor: Colors.white24,
            child: avatarUrl == null
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Welcome, ',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      TextSpan(
                        text: name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          GestureDetector(
            onTap: onBellPressed,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(Icons.notifications_none, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
