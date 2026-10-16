import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF030C14);
  static const surface = Color(0xFF071722);
  static const surfaceAlt = Color(0xFF0A1E2C);
  static const border = Color(0xFF17384A);
  static const cyan = Color(0xFF00B8FF);
  static const green = Color(0xFF00E58B);
  static const red = Color(0xFFFF4858);
  static const amber = Color(0xFFFFC328);
  static const purple = Color(0xFFAD63FF);
  static const text = Color(0xFFE8F1F7);
  static const muted = Color(0xFF8FA7B8);
}

abstract final class AppTheme {
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.cyan,
      secondary: AppColors.green,
      surface: AppColors.surface,
      error: AppColors.red,
    ),
    fontFamily: 'Segoe UI',
    fontFamilyFallback: const ['Tahoma', 'Arial'],
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: AppColors.text, fontSize: 13),
      bodySmall: TextStyle(color: AppColors.muted, fontSize: 11),
      titleMedium: TextStyle(
        color: AppColors.text,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    ),
    dividerColor: AppColors.border,
    splashFactory: InkRipple.splashFactory,
  );
}
