import 'package:flutter/material.dart';
import '../widgets/button.dart';

void showNotificationModal(
  BuildContext context, {
  required String currentValue,
  required void Function(String value) onSave,
}) {
  String selected = currentValue; // 'ON' or 'OFF'

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
            // Drag handle
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
              'Notification',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose whether to receive notifications.',
              style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
            ),
            const SizedBox(height: 24),

            // Toggle row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE0E0E0)),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Push Notifications',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selected == 'ON'
                            ? 'Currently enabled'
                            : 'Currently disabled',
                        style: TextStyle(
                          fontSize: 12,
                          color: selected == 'ON'
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: selected == 'ON',
                    activeColor: const Color(0xFF2E7D32),
                    onChanged: (val) =>
                        setModalState(() => selected = val ? 'ON' : 'OFF'),
                  ),
                ],
              ),
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
