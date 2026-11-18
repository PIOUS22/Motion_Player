import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF121212);
  static const surface = Color(0xFF1E1E1E);
  static const cyan = Color(0xFF00E5FF);
  static const orange = Color(0xFFFF9100);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.dark(primary: AppColors.cyan, secondary: AppColors.orange, surface: AppColors.surface),
        navigationBarTheme: NavigationBarThemeData(backgroundColor: AppColors.surface, indicatorColor: AppColors.cyan.withOpacity(.2)),
      );
}
