import 'package:flutter/material.dart';
import '../core/theme/app_gradient.dart';

class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;

  const AppButton({super.key, required this.text, required this.onPressed});

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(2), // BORDER THICKNESS
          decoration: BoxDecoration(
            gradient: _isPressed ? AppGradients.button : null,
            borderRadius: BorderRadius.circular(12),
          ),

          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 48,
            decoration: BoxDecoration(
              color: _isPressed ? Colors.white : null,
              gradient: _isPressed ? null : AppGradients.button,
              borderRadius: BorderRadius.circular(10),
            ),

            child: Center(
              child: _isPressed
                  // gradient text
                  ? ShaderMask(
                      shaderCallback: (bounds) {
                        return AppGradients.button.createShader(bounds);
                      },
                      child: const Text(
                        "SIGN UP",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                  // default white text
                  : Text(
                      widget.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
