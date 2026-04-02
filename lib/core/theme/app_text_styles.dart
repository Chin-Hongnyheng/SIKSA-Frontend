import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Large headings
  static const headlineLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  // Medium headings
  static const headlineMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.darkText,
  );

  // Body text
  static const body = TextStyle(fontSize: 16, color: AppColors.whiteText);

  // Small text / captions
  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: AppColors.caption,
  );

  // Buttons
  static const button = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    fontFamily: 'Poppins',
  );
}
