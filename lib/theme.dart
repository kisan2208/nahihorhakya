import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// GreenCredit brand palette.
class AppColors {
  static const primary = Color(0xFF1B7A43); // deep green
  static const primaryDark = Color(0xFF0F5A30);
  static const accent = Color(0xFFA8E063); // lime
  static const surface = Color(0xFFF6F9F4); // off-white
  static const charcoal = Color(0xFF1A241E); // text
  static const muted = Color(0xFF5C6B60);
  static const amber = Color(0xFFE0A73C);
  static const danger = Color(0xFFD8563B);

  // Background gradient stops.
  static const bgTop = Color(0xFFEAF6EC);
  static const bgBottom = Color(0xFFD3EBDA);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.surface,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
      ),
    );
    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: AppColors.charcoal,
        displayColor: AppColors.charcoal,
      ),
    );
  }

  static TextStyle display(double size, {FontWeight w = FontWeight.w700, Color? c}) =>
      GoogleFonts.poppins(fontSize: size, fontWeight: w, color: c ?? AppColors.charcoal, height: 1.1);

  static TextStyle body(double size, {FontWeight w = FontWeight.w400, Color? c}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: w, color: c ?? AppColors.charcoal, height: 1.3);
}
