import 'package:flutter/material.dart';
import '../../graphql/graphql_service.dart';
import '../providers/auth_provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import '../widgets/profile_header.dart';
import '../widgets/profile_detail_card.dart';
import '../widgets/profile_more_card.dart';
import '../modals/text_input_modal.dart';
import '../modals/gender_modal.dart';
import '../modals/date_picker_modal.dart';
import '../modals/notification_modal.dart';
import '../modals/language_modal.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GraphQLService graphqlService = GraphQLService();
  Map<String, dynamic>? user;
  bool isLoading = true;
  String? error;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchUser();
  }

  @override
  void reassemble() {
    super.reassemble();
    fetchUser();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  Future<void> fetchUser() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final result = await graphqlService.me();
      if (!mounted) return;
      setState(() {
        user = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  /// Called by every modal on Save — updates local state then calls the API
  Future<void> _updateField(String key, String value) async {
    // 1. Optimistic local update
    setState(() => user?[key] = value);

    // 2. Build the full profile payload (all fields required by mutation)
    await _submitProfile();
  }

  Future<void> _submitProfile() async {
    if (user == null) return;

    // 👇 add this
    print('userName: ${user?['userName']}');
    print('dob: ${user?['dob']}');
    print('gender: ${user?['gender']}');
    print('address: ${user?['address']}');
    print('notification: ${user?['notification']}');
    print('language: ${user?['language']}');

    try {
      await graphqlService.update(
        userName: user?['userName'] ?? '',
        dob: user?['dob'] ?? '',
        gender: user?['gender'] ?? '',
        address: user?['address'] ?? '',
        notification: user?['notification'] ?? 'ON',
        language: user?['language'] ?? 'ENGLISH',
      );
    } catch (e) {
      if (!mounted) return;
      print('❌ updateProfile error: $e');
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Error'),
          content: SelectableText(
            e.toString(),
          ), // 👈 SelectableText lets you copy it
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  void _onFieldTap(
    String fieldName,
    String fieldKey, {
    bool isGender = false,
    bool isDateOfBirth = false,
  }) {
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
    showNotificationModal(
      context,
      currentValue: user?['notification'] ?? 'ON',
      onSave: (value) => _updateField('notification', value),
    );
  }

  void _onLanguageTap() {
    showLanguageModal(
      context,
      currentValue: user?['language'] ?? 'ENGLISH',
      onSave: (value) => _updateField('language', value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            )
          : error != null
          ? _buildError()
          : _buildBody(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              error!,
              style: const TextStyle(color: Colors.red, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: fetchUser,
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

  Widget _buildBody() {
    return Column(
      children: [
        ProfileHeader(
          user: user,
          selectedImage: _selectedImage,
          onPickImage: _pickImage,
          onRefresh: fetchUser,
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
                    onLogout: () {},
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
