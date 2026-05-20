import 'package:flutter/material.dart';
import '../widgets/button.dart';

void showLanguageModal(
  BuildContext context, {
  required String currentValue,
  required void Function(String value) onSave,
}) {
  String selected = currentValue; // 'ENGLISH' or 'KHMER'

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Text(
              'Language',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select your preferred language.',
              style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
            ),
            const SizedBox(height: 24),
            _LanguageOption(
              label: 'English',
              value: 'ENGLISH',
              flag: '🇺🇸',
              selected: selected,
              onTap: () => setModalState(() => selected = 'ENGLISH'),
            ),
            const SizedBox(height: 10),
            _LanguageOption(
              label: 'ខ្មែរ (Khmer)',
              value: 'KHMER',
              flag: '🇰🇭',
              selected: selected,
              onTap: () => setModalState(() => selected = 'KHMER'),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Save',
              onPressed: () {
                Navigator.pop(ctx);
                onSave(selected);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final String value;
  final String flag;
  final String selected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.label,
    required this.value,
    required this.flag,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: onTap,
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
          children: [
            Text(flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? const Color(0xFF1B5E20) : Colors.black87,
                ),
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
