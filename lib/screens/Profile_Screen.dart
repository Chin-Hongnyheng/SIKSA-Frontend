// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_detail_card.dart';
import '../widgets/profile_more_card.dart';
import '../widgets/floating_line_background.dart';
import '../modals/text_input_modal.dart';
import '../modals/gender_modal.dart';
import '../modals/date_picker_modal.dart';
import '../modals/notification_modal.dart';
import '../modals/language_modal.dart';
import '../widgets/center_toast.dart';
import '../modals/phone_edit_modal.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  static const double avatarRadius = 70.0;

  void _onLogoutTap() {
    final overlayState = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black.withOpacity(0.4),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.logout_rounded, color: Colors.red, size: 36),
                const SizedBox(height: 12),
                const Text(
                  'Log Out',
                  style: TextStyle(
                    color: Color(0xFF1B3B22),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Are you sure you want to log out?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF607064),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => entry.remove(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5ECE7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Color(0xFF4F5F55),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          entry.remove();
                          await _handleLogout();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              'Log Out',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    overlayState.insert(entry);
  }

  Future<void> _handleLogout() async {
    context.read<UserProvider>().clearUser();
    await AuthProvider.clearTokens();
    if (!mounted) return;
    context.go('/start');
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
      try {
        await context.read<UserProvider>().uploadPhoto(File(image.path));
        if (mounted) {
          CenterToast.show(
            context,
            message: 'Photo updated!',
            icon: Icons.check_circle,
            color: Colors.green,
          );
        }
      } catch (e) {
        if (mounted) {
          CenterToast.show(
            context,
            message: e.toString(),
            icon: Icons.error_outline,
            color: Colors.red,
          );
        }
      }
    }
  }

  Future<void> _updateField(String key, String value) async {
    try {
      await context.read<UserProvider>().updateField(key, value);
    } catch (e) {
      if (mounted) {
        CenterToast.show(
          context,
          message: e.toString(),
          icon: Icons.error_outline,
          color: Colors.red,
        );
      }
    }
  }

  void _onFieldTap(
    String fieldName,
    String fieldKey, {
    bool isGender = false,
    bool isDateOfBirth = false,
  }) {
    final user = context.read<UserProvider>().userMap;
    if (isGender) {
      showGenderModal(
        context,
        fieldKey: fieldKey,
        user: user,
        onSave: _updateField,
      );
    } else if (isDateOfBirth) {
      showProfileDatePicker(
        context,
        fieldKey: fieldKey,
        user: user,
        onSave: _updateField,
      );
    } else if (fieldKey == 'phone') {
      showPhoneEditModal(
        context,
        currentValue: user?['phone']?.toString(),
        onSave: (value) => _updateField('phone', value),
      );
    } else {
      showTextInputModal(
        context,
        fieldName: fieldName,
        fieldKey: fieldKey,
        user: user,
        onSave: _updateField,
      );
    }
  }

  void _onNotificationTap() {
    final user = context.read<UserProvider>().userMap;
    showNotificationModal(
      context,
      currentValue: user?['notification'] ?? 'ON',
      onSave: (value) => _updateField('notification', value),
    );
  }

  void _onLanguageTap() {
    final user = context.read<UserProvider>().userMap;
    showLanguageModal(
      context,
      currentValue: user?['language'] ?? 'ENGLISH',
      onSave: (value) => _updateField('language', value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();
    final user = provider.userMap;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Animated green background (covers whole page) ──────────
          const Positioned.fill(
            child: FloatingLinesBackground(
              colors: [Color(0xFF00FF88), Color(0xFF00DD66), Color(0xFF1E6B2D)],
              lineCount: 6,
              animationSpeed: 0.5,
            ),
          ),

          // ── White body panel ─────────────────────────────────────────
          Positioned(
            top: topPadding + 70,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(color: Colors.white),
              child: provider.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2E7D32),
                      ),
                    )
                  : provider.error != null && user == null
                  ? _buildError(provider)
                  : _buildBody(user),
            ),
          ),

          // ── Top header (floats over the background) ─────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ProfileHeader(
              onRefresh: () => context.read<UserProvider>().loadUser(),
              onSettings: () {},
              onBack: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(UserProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              provider.error!,
              style: const TextStyle(color: Colors.red, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.read<UserProvider>().loadUser(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(Map<String, dynamic>? user) {
    final photoUrl = user?['photo_url'] as String?;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // ── Avatar + name, sitting inside the white panel, not overlapping ──
          const SizedBox(height: 24),
          Stack(
            children: [
              Container(
                width: avatarRadius * 2,
                height: avatarRadius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF2E7D32), width: 3),
                  color: const Color(0xFF2E7D32),
                ),
                child: ClipOval(
                  child: _selectedImage != null
                      ? Image.file(_selectedImage!, fit: BoxFit.cover)
                      : (photoUrl != null && photoUrl.isNotEmpty)
                      ? Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.person,
                            size: avatarRadius * 1.2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: avatarRadius * 1.2,
                          color: Colors.white,
                        ),
                ),
              ),
              Positioned(
                bottom: 6,
                right: 6,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            user?['userName'] ?? 'User',
            style: const TextStyle(
              color: Color(0xFF1B5E20),
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          ProfileDetailCard(user: user, onFieldTap: _onFieldTap),
          const SizedBox(height: 20),
          ProfileMoreCard(user: user, onLogout: _onLogoutTap),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
