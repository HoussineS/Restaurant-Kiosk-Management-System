import 'package:flutter/material.dart';

abstract final class AppTheme {
  static final lightTheme = _buildTheme(
    ColorScheme.fromSeed(
      seedColor: const Color(0xFF1F7A5A),
      brightness: Brightness.light,
    ),
  );

  static final darkTheme = _buildTheme(
    ColorScheme.fromSeed(
      seedColor: const Color(0xFF1F7A5A),
      brightness: Brightness.dark,
    ),
  );

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      visualDensity: VisualDensity.standard,
      appBarTheme: const AppBarTheme(centerTitle: false),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(96, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(96, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
