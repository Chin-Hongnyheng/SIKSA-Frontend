import 'package:flutter/material.dart';

class ProfileMoreCard extends StatelessWidget {
  final Map<String, dynamic>? user;
  final VoidCallback onLogout;
  final VoidCallback onNotificationTap;
  final VoidCallback onLanguageTap;

  const ProfileMoreCard({
    super.key,
    required this.user,
    required this.onLogout,
    required this.onNotificationTap,
    required this.onLanguageTap,
  });

  @override
  Widget build(BuildContext context) {
    final notification = user?['notification'] ?? 'ON';
    final language = user?['language'] ?? 'ENGLISH';
    final langLabel = language == 'KHMER' ? 'ខ្មែរ' : 'English';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: const [
                  Icon(Icons.more_horiz, color: Color(0xFF2E7D32), size: 24),
                  SizedBox(width: 12),
                  Text(
                    'More',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey[200]),
            _buildOption(
              icon: Icons.notifications,
              label: 'Notification',
              subtitle: notification,
              subtitleColor: notification == 'ON'
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFF9E9E9E),
              hasArrow: true,
              onTap: onNotificationTap,
            ),
            _buildOption(
              icon: Icons.language,
              label: 'Languages',
              subtitle: langLabel,
              hasArrow: true,
              onTap: onLanguageTap,
            ),
            _buildOption(
              icon: Icons.help_outline,
              label: 'Support',
              subtitle: 'need help?',
              hasArrow: true,
            ),
            _buildOption(
              icon: Icons.logout,
              label: 'Log out',
              hasArrow: true,
              isLastItem: true,
              onTap: onLogout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    String? subtitle,
    Color? subtitleColor,
    bool hasArrow = false,
    bool isLastItem = false,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF2E7D32), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: subtitleColor ?? const Color(0xFF9E9E9E),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (hasArrow)
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFFBDBDBD),
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
        if (!isLastItem)
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Divider(height: 1, color: Colors.grey[200]),
          ),
      ],
    );
  }
}
