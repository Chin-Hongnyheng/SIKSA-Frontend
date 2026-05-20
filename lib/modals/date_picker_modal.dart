import 'package:flutter/material.dart';

Future<void> showProfileDatePicker(
  BuildContext context, {
  required String fieldKey,
  required Map<String, dynamic>? user,
  required void Function(String key, String value) onSave,
}) async {
  DateTime initialDate;
  try {
    initialDate = user?[fieldKey] != null
        ? DateTime.parse(user![fieldKey].toString())
        : DateTime(2000);
  } catch (_) {
    initialDate = DateTime(2000);
  }

  final selectedDate = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(1950),
    lastDate: DateTime.now(),
    builder: (context, child) => Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1B5E20),
          onPrimary: Colors.white,
          surface: Colors.white,
        ),
      ),
      child: child!,
    ),
  );

  if (selectedDate != null) {
    // Store as full ISO string to match backend expectation
    onSave(fieldKey, selectedDate.toIso8601String());
  }
}
