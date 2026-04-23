import 'package:flutter/material.dart';
import '../widgets/button.dart';
import 'textfield.dart';

class EmailModal extends StatelessWidget {
  final VoidCallback onContinue;
  final TextEditingController emailController;

  const EmailModal({
    super.key,
    required this.onContinue,
    required this.emailController,
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
                "Forgot Password",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              const Text(
                "Enter your email for the verification process, we will send 4 digits code to your email.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),

              const SizedBox(height: 20),

              AppTextField(
                controller: emailController,
                label: "Email",
                hint: "Enter your email",
                secure: false,
                icon: Icons.mail,
              ),

              const SizedBox(height: 20),

              AppButton(text: "Continue", onPressed: onContinue),
            ],
          ),
        ),
      ),
    );
  }
}
