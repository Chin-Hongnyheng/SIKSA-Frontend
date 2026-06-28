import 'package:flutter/material.dart';
import '../widgets/phonetextfield.dart';
import '../widgets/button.dart';
import '../widgets/center_toast.dart';

void showPhoneEditModal(
  BuildContext context, {
  required String? currentValue,
  required Future<void> Function(String value) onSave,
}) {
  final phoneController = TextEditingController();
  bool isSaving = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: double.infinity),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const Text(
                    "Edit Phone Number",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  PhoneTextField(
                    controller: phoneController,
                    initialValue: currentValue,
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    text: isSaving ? "Saving..." : "Save",
                    onPressed: isSaving
                        ? null
                        : () async {
                            final value = phoneController.text.trim();

                            if (value.isEmpty) {
                              await CenterToast.show(
                                context,
                                message: "Phone number is required",
                                icon: Icons.error,
                                color: Colors.red,
                              );
                              return;
                            }

                            setState(() => isSaving = true);
                            try {
                              await onSave(value);
                              if (context.mounted) Navigator.pop(context);
                            } catch (e) {
                              if (context.mounted) {
                                await CenterToast.show(
                                  context,
                                  message: e.toString(),
                                  icon: Icons.error,
                                  color: Colors.red,
                                );
                              }
                            } finally {
                              setState(() => isSaving = false);
                            }
                          },
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
