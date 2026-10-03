import 'package:flutter/material.dart';

/// Colors pulled directly from the web app's inline styles
/// (Sidebar #2d4a5a, timetable cells #3a6070, hover accents).
class AppColors {
  AppColors._();
  static const navy = Color(0xFF2D4A5A);
  static const teal = Color(0xFF3A6070);
  static const background = Color(0xFFF0F4F7);
  static const white = Colors.white;
  static const danger = Color(0xFFD64545);
  static const success = Color(0xFF2E9E5B);
  static const warning = Color(0xFFE0A233);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    const fontFamily = 'PlusJakartaSans';
    final base = ThemeData(useMaterial3: true);
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      // Applying the font to every named text style (not just the
      // top-level `fontFamily:` above) guarantees nothing falls back
      // to the device's system font, even on phones like MIUI ones
      // that override default typefaces at the OS level.
      textTheme: base.textTheme.apply(fontFamily: fontFamily),
      primaryTextTheme: base.primaryTextTheme.apply(fontFamily: fontFamily),
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.navy,
        primary: AppColors.navy,
        secondary: AppColors.teal,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.navy,
        indicatorColor: AppColors.teal,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? Colors.white : Colors.white60);
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}