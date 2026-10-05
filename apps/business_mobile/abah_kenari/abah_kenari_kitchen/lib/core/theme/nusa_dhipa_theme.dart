import 'package:flutter/material.dart';

class NusaDhipaColors {
  static const primary = Color(0xFFB71C1C);
  static const primaryDark = Color(0xFF7F0000);
  static const primaryLight = Color(0xFFE53935);

  static const background = Color(0xFFF7F8FA);
  static const surface = Colors.white;

  static const textPrimary = Color(0xFF202124);
  static const textSecondary = Color(0xFF6B7280);

  static const success = Color(0xFF16803C);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFDC2626);

  static const border = Color(0xFFE5E7EB);
}

class NusaDhipaTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: NusaDhipaColors.background,

      colorScheme: ColorScheme.fromSeed(
        seedColor: NusaDhipaColors.primary,
        brightness: Brightness.light,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: NusaDhipaColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),

      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: NusaDhipaColors.border),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: NusaDhipaColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: NusaDhipaColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: NusaDhipaColors.primary,
            width: 2,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: NusaDhipaColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
