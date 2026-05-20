import 'package:flutter/material.dart';

void showGenderModal(
  BuildContext context, {
  required String fieldKey,
  required Map<String, dynamic>? user,
  required void Function(String key, String value) onSave,
}) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
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
          _GenderOption(
            label: 'Male',
            value: 'Male',
            fieldKey: fieldKey,
            user: user,
            onSave: onSave,
          ),
          const SizedBox(height: 10),
          _GenderOption(
            label: 'Female',
            value: 'Female',
            fieldKey: fieldKey,
            user: user,
            onSave: onSave,
          ),
          const SizedBox(height: 10),
          _GenderOption(
            label: 'Other',
            value: 'Other',
            fieldKey: fieldKey,
            user: user,
            onSave: onSave,
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}

class _GenderOption extends StatelessWidget {
  final String label;
  final String value;
  final String fieldKey;
  final Map<String, dynamic>? user;
  final void Function(String key, String value) onSave;

  const _GenderOption({
    required this.label,
    required this.value,
    required this.fieldKey,
    required this.user,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = user?[fieldKey] == value;
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onSave(fieldKey, value);
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
}
