import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProfileDetailCard extends StatelessWidget {
  final Map<String, dynamic>? user;
  final void Function(
    String fieldName,
    String fieldKey, {
    bool isGender,
    bool isDateOfBirth,
  })
  onFieldTap;

  const ProfileDetailCard({
    super.key,
    required this.user,
    required this.onFieldTap,
  });

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      // Handles both "2000-01-15T00:00:00.000Z" and "2000-01-15"
      return DateFormat(
        'MMM dd, yyyy',
      ).format(DateTime.parse(dateStr).toLocal());
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  Icon(
                    Icons.person_outline,
                    color: Color(0xFF2E7D32),
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
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
            _buildField(
              icon: Icons.person,
              label: 'Username',
              value: user?['userName'],
              fieldKey: 'userName',
            ),
            _buildField(
              icon: Icons.email,
              label: 'Email',
              value: user?['email'],
              fieldKey: 'email',
            ),
            _buildField(
              icon: Icons.phone,
              label: 'Phone',
              value: user?['phone'] != null ? '+${user!['phone']}' : null,
              fieldKey: 'phone',
            ),
            _buildField(
              icon: Icons.wc,
              label: 'Gender',
              value: user?['gender'],
              fieldKey: 'gender',
              isGender: true,
            ),
            _buildField(
              icon: Icons.calendar_today,
              label: 'Date of Birth',
              value: user?['dob'],
              fieldKey: 'dob',
              isDateOfBirth: true,
            ),
            _buildField(
              icon: Icons.location_on,
              label: 'Address',
              value: user?['address'],
              fieldKey: 'address',
              isLastItem: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required IconData icon,
    required String label,
    required dynamic value,
    required String fieldKey,
    bool isGender = false,
    bool isDateOfBirth = false,
    bool isLastItem = false,
  }) {
    String displayValue = '';
    if (value != null && value.toString().isNotEmpty) {
      displayValue = isDateOfBirth
          ? _formatDate(value.toString())
          : value.toString();
    }
    final isEmpty = displayValue.isEmpty;

    return Column(
      children: [
        InkWell(
          onTap: () => onFieldTap(
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
                  isEmpty ? Icons.arrow_forward_ios : Icons.edit,
                  color: const Color(0xFFBDBDBD),
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
