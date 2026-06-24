import 'package:flutter/material.dart';

abstract final class AppTheme {
  static final lightTheme = _buildTheme(
    ColorScheme.fromSeed(
      seedColor: Colors.black,
      primary: Colors.black,
      surface: const Color(0xFFFFFFFF),
      brightness: Brightness.light,
    ),
  );

  static final darkTheme = _buildTheme(
    ColorScheme.fromSeed(
      seedColor: Colors.white,
      primary: Colors.white,
      surface: const Color(0xFF1C1C1E),
      brightness: Brightness.dark,
    ),
  );

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.brightness == Brightness.light ? const Color(0xFFF5F5F7) : Colors.black,
      visualDensity: VisualDensity.standard,
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.brightness == Brightness.light ? const Color(0xFFF0F0F0) : const Color(0xFF2C2C2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0.5,
        shadowColor: Colors.black.withOpacity(0.2),
        margin: EdgeInsets.zero,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(96, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(96, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
      ),
    );
  }
}
