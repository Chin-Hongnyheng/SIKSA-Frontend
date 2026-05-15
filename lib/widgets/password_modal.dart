import 'package:flutter/material.dart';
import '../widgets/button.dart';
import 'textfield.dart';

class PasswordModal extends StatelessWidget {
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final VoidCallback onSubmit;
  const PasswordModal({
    super.key,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom, // keyboard space
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// drag indicator
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
                "Reset Password",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              const Text(
                "Set the new password for your account so you can login and access all the features.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),

              const SizedBox(height: 20),

              AppTextField(
                controller: newPasswordController,
                label: "New Password",
                hint: "Enter your password",
                secure: true,
                showToggle: true,
                icon: Icons.lock,
              ),

              const SizedBox(height: 20),

              AppTextField(
                controller: confirmPasswordController,
                label: "Confirm Password",
                hint: "Enter your password",
                secure: true,
                showToggle: true,
                icon: Icons.lock,
              ),

              const SizedBox(height: 20),

              AppButton(text: "Update Password", onPressed: onSubmit),
            ],
          ),
        ),
      ),
    );
  }
}
