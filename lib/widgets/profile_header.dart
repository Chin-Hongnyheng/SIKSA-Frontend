import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final VoidCallback onRefresh;
  final VoidCallback onSettings;
  final VoidCallback onBack;

  const ProfileHeader({
    super.key,
    required this.onRefresh,
    required this.onSettings,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: SizedBox(
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Centered title — always dead-center of the row, regardless
              // of how wide the left/right button groups are.
              const Text(
                'Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                ),
              ),

              // Left + right controls sit on top, title peeks out between them.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: onBack,
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 26,
                        ),
                        onPressed: onRefresh,
                        tooltip: 'Refresh',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.settings,
                          color: Colors.white,
                          size: 26,
                        ),
                        onPressed: onSettings,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
