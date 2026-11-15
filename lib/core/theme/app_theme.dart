import 'package:flutter/material.dart';

/// Paleta obtenida del logotipo corporativo entregado para Obratek 2.0.
/// No depende del tema por defecto de AppSheet.
class AppPalette {
  static const ink = Color(0xFF182439);
  static const navy = Color(0xFF111E35);
  static const navyDark = Color(0xFF0C172B);
  static const muted = Color(0xFF65748D);
  static const primary = Color(0xFFE90079);
  static const primarySoft = Color(0xFFFFEAF4);
  static const cyan = Color(0xFF11C8E9);
  static const teal = Color(0xFF00879E);
  static const background = Color(0xFFF4F7FC);
  static const border = Color(0xFFE2E9F4);
  static const surface = Colors.white;
  static const danger = Color(0xFFB83B55);
  static const success = Color(0xFF17855B);
}

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: AppPalette.primary,
      brightness: Brightness.light, surface: AppPalette.surface);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppPalette.background,
      visualDensity: VisualDensity.standard,
      appBarTheme: const AppBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppPalette.ink,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 31, fontWeight: FontWeight.w800,
          color: AppPalette.ink, letterSpacing: -0.9),
        headlineMedium: TextStyle(fontSize: 25, fontWeight: FontWeight.w800,
          color: AppPalette.ink, letterSpacing: -0.6),
        titleLarge: TextStyle(fontSize: 19, fontWeight: FontWeight.w700,
          color: AppPalette.ink),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
          color: AppPalette.ink),
        bodyLarge: TextStyle(fontSize: 15, color: AppPalette.ink),
        bodyMedium: TextStyle(fontSize: 14, color: AppPalette.ink),
        bodySmall: TextStyle(fontSize: 12, color: AppPalette.muted),
      ),
      cardTheme: CardThemeData(
        color: AppPalette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppPalette.border)),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: AppPalette.muted),
        hintStyle: const TextStyle(color: Color(0xFF8592A8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppPalette.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppPalette.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppPalette.primary, width: 1.8)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(backgroundColor: AppPalette.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 17),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.ink,
          side: const BorderSide(color: AppPalette.border),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        height: 74,
        indicatorColor: AppPalette.primarySoft,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w600, fontSize: 10)),
      ),
      dividerTheme: const DividerThemeData(color: AppPalette.border),
    );
  }
}
