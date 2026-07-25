import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    textTheme: GoogleFonts.nunitoTextTheme(),

    // Base colors
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,

    // Color scheme (for AppBar, buttons, etc.)
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Color.fromARGB(255, 73, 61, 61),
      error: AppColors.error,
      onError: Colors.white,
      surface: Colors.white,
      onSurface: AppColors.darkText,
    ),

    // Text theme
    // textTheme: const TextTheme(
    //   headlineLarge: AppTextStyles.headlineLarge,
    //   headlineMedium: AppTextStyles.headlineMedium,
    //   bodyMedium: AppTextStyles.body,
    //   bodySmall: AppTextStyles.caption,
    // ),

    // // AppBar theme
    // appBarTheme: const AppBarTheme(
    //   backgroundColor: AppColors.primary,
    //   foregroundColor: Colors.white,
    //   elevation: 0,
    //   centerTitle: true,
    // ),

    // // Elevated button theme
    // elevatedButtonTheme: ElevatedButtonThemeData(
    //   style: ElevatedButton.styleFrom(
    //     foregroundColor: Colors.white,
    //     textStyle: AppTextStyles.button,
    //     shape: RoundedRectangleBorder(
    //       borderRadius: BorderRadius.circular(12),
    //     ),
    //     padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    //   ),
    // ),
  );

  // /// Example method to create a gradient button
  // static Widget gradientButton({
  //   required String text,
  //   required VoidCallback onPressed,
  //   double borderRadius = 12,
  // }) {
  //   return Container(
  //     decoration: BoxDecoration(
  //       gradient: AppGradients.button,
  //       borderRadius: BorderRadius.circular(borderRadius),
  //     ),
  //     child: Material(
  //       color: Colors.transparent,
  //       child: InkWell(
  //         borderRadius: BorderRadius.circular(borderRadius),
  //         onTap: onPressed,
  //         child: Container(
  //           alignment: Alignment.center,
  //           padding: const EdgeInsets.symmetric(vertical: 16),
  //           child: Text(
  //             text,
  //             style: AppTextStyles.button,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
