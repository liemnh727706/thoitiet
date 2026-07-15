import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get theme {
    const seed = Color(0xFF2196F3);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF2F5F8),
      fontFamily: 'Roboto',
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  // Style card kính mờ dùng trên nền gradient
  static BoxDecoration glassCard = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.15),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
  );
}
