import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class QuickAccessCard extends StatefulWidget {
  final Widget icon;
  final String title;
  final VoidCallback? onTap;

  const QuickAccessCard({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  State<QuickAccessCard> createState() => _QuickAccessCardState();
}

class _QuickAccessCardState extends State<QuickAccessCard> {
  double _currentScale = 1.0;

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.primary;

    return AnimatedScale(
      scale: _currentScale,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _currentScale = 0.95),
        onTapUp: (_) {
          setState(() => _currentScale = 1.0);
          if (widget.onTap != null) widget.onTap!();
        },
        onTapCancel: () => setState(() => _currentScale = 1.0),
        child: Container(
          width: double.infinity,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: primaryColor.withOpacity(0.15),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: primaryColor.withOpacity(0.1),
                width: 1.2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(19),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: null,
                  splashColor: primaryColor.withOpacity(0.05),
                  highlightColor: primaryColor.withOpacity(0.02),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      widget.icon,
                      const SizedBox(height: 8),
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF2D3748),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
