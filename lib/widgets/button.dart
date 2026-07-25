import 'package:flutter/material.dart';
import '../core/theme/app_gradient.dart';

class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;

  const AppButton({super.key, required this.text, this.onPressed});

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.onPressed == null ? 0.5 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: GestureDetector(
          onTapDown: widget.onPressed == null
              ? null
              : (_) => setState(() => _isPressed = true),
          onTapUp: widget.onPressed == null
              ? null
              : (_) {
                  setState(() => _isPressed = false);
                  widget.onPressed!();
                },
          onTapCancel: widget.onPressed == null
              ? null
              : () => setState(() => _isPressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(2),
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
                    ? ShaderMask(
                        shaderCallback: (bounds) {
                          return AppGradients.button.createShader(bounds);
                        },
                        child: Text(
                          widget.text,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      )
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
      ),
    );
  }
}
