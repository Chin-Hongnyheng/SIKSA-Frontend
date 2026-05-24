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
import '../modals/text_input_modal.dart';
import '../modals/gender_modal.dart';
import '../modals/date_picker_modal.dart';
import '../modals/notification_modal.dart';
import '../modals/language_modal.dart';
import '../widgets/center_toast.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  void _onLogoutTap() {
    final overlayState = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.logout, color: Colors.red, size: 32),
                const SizedBox(height: 12),
                const Text(
                  'Log Out',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Are you sure you want to log out?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => entry.remove(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
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
                                fontWeight: FontWeight.w600,
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
    context.read<UserProvider>().clearUser(); // 👈 clear user on logout
    await AuthProvider.clearTokens();
    if (!mounted) return;
    context.go('/start');
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
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

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: provider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            )
          : provider.error != null && user == null
          ? _buildError(provider)
          : _buildBody(user),
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
    return Column(
      children: [
        ProfileHeader(
          user: user,
          selectedImage: _selectedImage,
          onPickImage: _pickImage,
          onRefresh: () =>
              context.read<UserProvider>().loadUser(), // 👈 use provider
          onSettings: () {},
          onBack: () => Navigator.pop(context),
        ),
        Transform.translate(
          offset: const Offset(0, -ProfileHeader.avatarRadius),
          child: Column(
            children: [
              Text(
                user?['userName'] ?? 'User',
                style: const TextStyle(
                  color: Color(0xFF1B5E20),
                  fontSize: 34,
                  fontWeight: FontWeight(900),
                ),
              ),
              Text(
                user?['role'] ?? 'Student',
                style: const TextStyle(
                  color: Color.fromARGB(255, 53, 53, 53),
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        Expanded(
          child: Transform.translate(
            offset: const Offset(0, -ProfileHeader.avatarRadius),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  ProfileDetailCard(user: user, onFieldTap: _onFieldTap),
                  const SizedBox(height: 20),
                  ProfileMoreCard(
                    user: user,
                    onLogout: _onLogoutTap,
                    onNotificationTap: _onNotificationTap,
                    onLanguageTap: _onLanguageTap,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
