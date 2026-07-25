import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../service/otp_service.dart';
import '../widgets/center_toast.dart';

class OtpField extends StatefulWidget {
  final int length;
  final String email;
  final VoidCallback onVerifySuccess;

  const OtpField({
    super.key,
    this.length = 6,
    required this.email,
    required this.onVerifySuccess,
  });

  @override
  State<OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<OtpField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool isVerifying = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get code => _controller.text;

  /// Auto-verify when all 6 digits entered
  Future<void> _autoVerifyOtp() async {
    if (_controller.text.length == widget.length) {
      await _verifyOtp();
    }
  }

  /// Verify OTP using API Service
  Future<void> _verifyOtp() async {
    final otp = _controller.text.trim();

    if (otp.isEmpty || otp.length != 6) {
      await CenterToast.show(
        context,
        message: "Please enter all 6 digits",
        icon: Icons.error,
        color: Colors.red,
      );
      return;
    }

    setState(() {
      isVerifying = true;
    });

    try {
      // CALL API SERVICE - VERIFY OTP
      await ApiService.verifyOtp(widget.email, otp);

      if (!mounted) return;

      widget.onVerifySuccess();
    } catch (e) {
      if (!mounted) return;

      // ERROR HANDLING
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      await CenterToast.show(
        context,
        message: errorMessage,
        icon: Icons.error,
        color: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          isVerifying = false;
        });
      }
    }
  }

  /// Show error snackbar
  // void _showError(String message) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text(message),
  //       backgroundColor: Colors.red,
  //       duration: const Duration(seconds: 3),
  //     ),
  //   );
  // }

  /// Show success snackbar
  // void _showSuccess(String message) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text(message),
  //       backgroundColor: Colors.green,
  //       duration: const Duration(seconds: 2),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: Stack(
        children: [
          /// hidden real input
          Opacity(
            opacity: 0,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              maxLength: widget.length,
              onChanged: (_) {
                setState(() {});
                // Call auto-verify on text change
                _autoVerifyOtp();
              },
            ),
          ),

          /// UI boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(widget.length, (index) {
              String char = "";
              if (index < _controller.text.length) {
                char = _controller.text[index];
              }

              // Track if digit entered
              bool isEntered = index < _controller.text.length;

              return Container(
                width: 50,
                height: 55,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _focusNode.hasFocus ? Colors.green : Colors.grey,
                    width: 1.5,
                  ),
                  // Add light green background when digit entered
                  color: isEntered ? Colors.green : Colors.transparent,
                ),
                // Show loading spinner while verifying
                child: isVerifying && isEntered
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      )
                    : Text(
                        char,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
