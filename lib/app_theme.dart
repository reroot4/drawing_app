import 'package:flutter/material.dart';

class AppColors {
  static const navy = Color(0xFF2B4D8F);
  static const navyDark = Color(0xFF1A3366);
  static const yellow = Color(0xFFF5D800);
  static const white = Color(0xFFFFFFFF);
  static const bgLight = Color(0xFFF4F4F4);
  static const border = Color(0xFF1A1A1A);
  static const red = Color(0xFFE53935);
  static const green = Color(0xFF43A047);
  static const blue = Color(0xFF1E88E5);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    primaryColor: AppColors.navy,
    scaffoldBackgroundColor: AppColors.bgLight,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.navy,
      primary: AppColors.navy,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.navy,
      inactiveTrackColor: Colors.grey.shade200,
      thumbColor: AppColors.navy,
      overlayColor: AppColors.navy.withOpacity(0.2),
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
    ),
  );
}
