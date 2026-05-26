import 'package:flutter/material.dart';
import '../widgets/button.dart';
import '../widgets/OTP_field.dart';
import '../service/OTP_service.dart';
import '../widgets/center_toast.dart';

class OtpModal extends StatefulWidget {
  final String? email;
  final VoidCallback onVerify;

  const OtpModal({super.key, this.email, required this.onVerify});

  @override
  State<OtpModal> createState() => _OtpModalState();
}

class _OtpModalState extends State<OtpModal> {
  bool isResending = false;

  /// Resend OTP using API Service
  Future<void> _resendOtp() async {
    if (widget.email == null || widget.email!.isEmpty) {
      await CenterToast.show(
        context,
        message: "Email not provided",
        icon: Icons.error,
        color: Colors.red,
      );
      return;
    }

    setState(() {
      isResending = true;
    });

    try {
      // CALL API SERVICE
      await ApiService.sendOtp(widget.email!);

      if (!mounted) return;

      // SUCCESS
      await CenterToast.show(
        context,
        message: "OTP sent to your email",
        icon: Icons.check_circle,
        color: Colors.green,
      );
      await CenterToast.show(
        context,
        message: "Password cannot be empty",
        icon: Icons.error,
        color: Colors.red,
      );
    } catch (e) {
      if (!mounted) return;

      // ERROR HANDLING
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('❌ $errorMessage'), backgroundColor: Colors.red),
      // );
      await CenterToast.show(
        context,
        message: errorMessage,
        icon: Icons.error,
        color: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
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
              /// drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const Text(
                "Enter 6 Digits Code",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Show email in description
              Text(
                widget.email != null && widget.email!.isNotEmpty
                    ? "Enter the 6 digits code that you received on ${widget.email}."
                    : "Enter the 6 digits code that you received on your email.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),

              const SizedBox(height: 24),

              /// Pass email and callback to OtpField
              widget.email != null && widget.email!.isNotEmpty
                  ? OtpField(
                      length: 6,
                      email: widget.email!,
                      onVerifySuccess: () {
                        Navigator.pop(context);
                        widget.onVerify();
                      },
                    )
                  : const Text(
                      'Email not provided',
                      style: TextStyle(color: Colors.red),
                    ),

              const SizedBox(height: 24),

              /// Resend button now calls _resendOtp
              AppButton(
                text: isResending ? "Resending..." : "Resend OTP",
                onPressed: () {
                  if (isResending) return;
                  _resendOtp();
                },
              ),

              const SizedBox(height: 12),

              Text(
                "OTP expires in 5 minutes",
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
