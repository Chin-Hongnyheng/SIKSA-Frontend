import 'package:flutter/material.dart';
import 'dart:io';

class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic>? user;
  final File? selectedImage;
  final VoidCallback onPickImage;
  final VoidCallback onRefresh;
  final VoidCallback onSettings;
  final VoidCallback onBack;

  static const double avatarRadius = 90.0;

  const ProfileHeader({
    super.key,
    required this.user,
    required this.selectedImage,
    required this.onPickImage,
    required this.onRefresh,
    required this.onSettings,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: const Color(0xFF2E7D32),
          padding: EdgeInsets.only(
            top: topPadding + 8,
            bottom: avatarRadius,
            left: 4,
            right: 4,
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: onBack,
              ),
              const Expanded(
                child: Text(
                  'Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 28,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white, size: 30),
                onPressed: onRefresh,
                tooltip: 'Refresh',
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white, size: 30),
                onPressed: onSettings,
              ),
            ],
          ),
        ),

        // ── Avatar overlapping banner ────────────────────────────────
        Transform.translate(
          offset: const Offset(0, -avatarRadius),
          child: Stack(
            children: [
              Container(
                width: avatarRadius * 2,
                height: avatarRadius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color.fromARGB(255, 250, 250, 250),
                    width: 3.5,
                  ),
                  color: const Color(0xFF2E7D32),
                ),
                child: ClipOval(
                  child: selectedImage != null
                      ? Image.file(selectedImage!, fit: BoxFit.cover)
                      : Icon(
                          Icons.person,
                          size: avatarRadius * 1.2,
                          color: Colors.white,
                        ),
                ),
              ),
              Positioned(
                bottom: 6,
                right: 10,
                child: GestureDetector(
                  onTap: onPickImage,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
