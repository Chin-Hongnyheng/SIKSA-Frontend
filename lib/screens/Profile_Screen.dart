import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../graphql/graphql_service.dart';
import '../widgets/loading.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchUser();
    });
  }

  Future<void> fetchUser() async {
    try {
      LoadingOverlay.show(context);
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
    } finally {
      LoadingOverlay.hide();
    }
  }

  void _showInputModal(
    String fieldName,
    String fieldKey, {
    bool isGender = false,
    bool isDateOfBirth = false,
  }) {
    if (isGender) {
      _showGenderModal(fieldKey);
    } else if (isDateOfBirth) {
      _showDatePicker(fieldKey);
    } else {
      _showTextInputModal(fieldName, fieldKey);
    }
  }

  void _showTextInputModal(String fieldName, String fieldKey) {
    final textController = TextEditingController(
      text: user?[fieldKey]?.toString() ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Edit $fieldName',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: textController,
              decoration: InputDecoration(
                hintText: 'Enter $fieldName',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF1B5E20),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    user?[fieldKey] = textController.text;
                  });
                  Navigator.pop(context);
                },
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showGenderModal(String fieldKey) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Gender',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 20),
            _buildGenderOption('Male', 'Male', fieldKey),
            const SizedBox(height: 10),
            _buildGenderOption('Female', 'Female', fieldKey),
            const SizedBox(height: 10),
            _buildGenderOption('Other', 'Other', fieldKey),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderOption(String label, String value, String fieldKey) {
    final isSelected = user?[fieldKey] == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          user?[fieldKey] = value;
        });
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1B5E20)
                : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? const Color(0xFFF1F8F6) : Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? const Color(0xFF1B5E20) : Colors.black87,
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF1B5E20)),
          ],
        ),
      ),
    );
  }

  Future<void> _showDatePicker(String fieldKey) async {
    final currentDate = user?[fieldKey] != null
        ? DateTime.parse(user?[fieldKey].toString() ?? '')
        : DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1B5E20),
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      setState(() {
        user?[fieldKey] = selectedDate.toString().split(' ')[0];
      });
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              // Settings action
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error: $error',
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Header
                  Container(
                    color: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 20,
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            color: Colors.white,
                          ),
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user?['userName'] ?? 'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?['role'] ?? 'Student',
                          style: const TextStyle(
                            color: Color(0xFFE8F5E9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // User Detail Section
                  Padding(
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
                              children: [
                                const Icon(
                                  Icons.person_outline,
                                  color: Color(0xFF2E7D32),
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'User Detail',
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
                          _buildDetailField(
                            icon: Icons.person,
                            label: 'Username',
                            value: user?['userName'],
                            fieldKey: 'userName',
                          ),
                          _buildDetailField(
                            icon: Icons.email,
                            label: 'Email',
                            value: user?['email'],
                            fieldKey: 'email',
                          ),
                          _buildDetailField(
                            icon: Icons.phone,
                            label: 'Phone',
                            value: user?['phone'],
                            fieldKey: 'phone',
                          ),
                          _buildDetailField(
                            icon: Icons.wc,
                            label: 'Gender',
                            value: user?['gender'],
                            fieldKey: 'gender',
                            isGender: true,
                          ),
                          _buildDetailField(
                            icon: Icons.calendar_today,
                            label: 'Date of Birth',
                            value: user?['dateOfBirth'],
                            fieldKey: 'dateOfBirth',
                            isDateOfBirth: true,
                            isLastItem: false,
                          ),
                          _buildDetailField(
                            icon: Icons.location_on,
                            label: 'Address',
                            value: user?['address'],
                            fieldKey: 'address',
                            isLastItem: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // More Section
                  Padding(
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
                              children: [
                                const Icon(
                                  Icons.more_horiz,
                                  color: Color(0xFF2E7D32),
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                const Text(
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
                          _buildMoreOption(
                            icon: Icons.notifications,
                            label: 'Notification',
                            subtitle: 'ON',
                          ),
                          _buildMoreOption(
                            icon: Icons.language,
                            label: 'Languages',
                            hasArrow: true,
                          ),
                          _buildMoreOption(
                            icon: Icons.help_outline,
                            label: 'Support',
                            subtitle: 'need help?',
                            hasArrow: true,
                          ),
                          _buildMoreOption(
                            icon: Icons.logout,
                            label: 'Log out',
                            hasArrow: true,
                            isLastItem: true,
                            onTap: () {
                              // Handle logout
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailField({
    required IconData icon,
    required String label,
    required dynamic value,
    required String fieldKey,
    bool isGender = false,
    bool isDateOfBirth = false,
    bool isLastItem = false,
  }) {
    String displayValue = '';

    if (value == null || value.toString().isEmpty) {
      displayValue = '';
    } else if (isDateOfBirth) {
      displayValue = _formatDate(value.toString());
    } else {
      displayValue = value.toString();
    }

    final isEmpty = displayValue.isEmpty;

    return Column(
      children: [
        GestureDetector(
          onTap: () => _showInputModal(
            label,
            fieldKey,
            isGender: isGender,
            isDateOfBirth: isDateOfBirth,
          ),
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
                      const SizedBox(height: 4),
                      Text(
                        isEmpty ? '+ Add $label' : displayValue,
                        style: TextStyle(
                          fontSize: 13,
                          color: isEmpty
                              ? const Color(0xFF9E9E9E)
                              : const Color(0xFF666666),
                          fontWeight: isEmpty
                              ? FontWeight.w400
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isEmpty ? Icons.arrow_forward : Icons.edit,
                  color: const Color(0xFFBDBDBD),
                  size: 18,
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

  Widget _buildMoreOption({
    required IconData icon,
    required String label,
    String? subtitle,
    bool hasArrow = false,
    bool isLastItem = false,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
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
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9E9E9E),
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
