import 'package:flutter/material.dart';

class NusaDhipaTheme {
  static const red = Color(0xFFD32F2F);
  static const redDark = Color(0xFFB71C1C);

  static const background = Color(0xFFF7F7F7);
  static const surface = Color(0xFFFFFFFF);

  static const text = Color(0xFF212121);
  static const muted = Color(0xFF757575);
  static const border = Color(0xFFE5E5E5);

  static const success = Color(0xFF16A34A);

  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: red,
          brightness: Brightness.light,
        ).copyWith(
          primary: red,
          onPrimary: Colors.white,
          secondary: red,
          onSecondary: Colors.white,
          surface: surface,
          onSurface: text,
          error: const Color(0xFFD32F2F),
          onError: Colors.white,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,

      scaffoldBackgroundColor: background,

      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),

      cardTheme: const CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: red,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: red,
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: red, width: 1.5),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: const Color(0xFFFFE5E5),

        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected) ? red : muted,
            fontWeight: FontWeight.w600,
          );
        }),

        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected) ? red : muted,
          );
        }),
      ),

      dividerTheme: const DividerThemeData(color: border, thickness: 1),
    );
  }
}
