import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class ScanIcon extends StatelessWidget {
  final double size;
  const ScanIcon({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.primary;

    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.crop_free_rounded, color: primaryColor, size: size),
        Icon(Icons.qr_code_2_rounded, color: primaryColor, size: size * 0.7),
      ],
    );
  }
}
