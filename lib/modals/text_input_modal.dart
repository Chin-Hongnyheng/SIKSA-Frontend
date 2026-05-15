import 'package:flutter/material.dart';
import '../widgets/button.dart';
import '../widgets/textfield.dart';

void showTextInputModal(
  BuildContext context, {
  required String fieldName,
  required String fieldKey,
  required Map<String, dynamic>? user,
  required void Function(String key, String value) onSave,
}) {
  final textController = TextEditingController(
    text: user?[fieldKey]?.toString() ?? '',
  );

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom,
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
          AppTextField(
            label: fieldName,
            hint: 'Enter $fieldName',
            secure: false,
            controller: textController,
          ),
          const SizedBox(height: 20),
          AppButton(
            text: 'Save',
            onPressed: () {
              final newValue = textController.text;
              Navigator.pop(ctx);
              onSave(fieldKey, newValue);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}
