import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralised, premium design system for InovXA.
/// All colours, radii, shadows, gradients live here so the app stays consistent.
class AppTheme {
  // ───── Brand palette ─────
  static const indigo = Color(0xFF4F46E5);
  static const blue = Color(0xFF2563EB);
  static const ink = Color(0xFF0F172A);
  static const subtle = Color(0xFF64748B);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const surfaceLight = Color(0xFFF8FAFC);
  static const surfaceDark = Color(0xFF0B1020);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [indigo, blue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ───── Spacing (8pt) ─────
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s24 = 24;
  static const double s32 = 32;

  // ───── Radii ─────
  static const double rSm = 12;
  static const double rMd = 16;
  static const double rLg = 24;

  // ───── Soft shadow ─────
  static List<BoxShadow> softShadow(BuildContext ctx) {
    final dark = Theme.of(ctx).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: dark ? 0.4 : 0.06),
        blurRadius: 18,
        offset: const Offset(0, 6),
      ),
    ];
  }

  // ───── Themes ─────
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: indigo,
        brightness: Brightness.light,
      ).copyWith(surface: surfaceLight),
      scaffoldBackgroundColor: surfaceLight,
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: ink,
        displayColor: ink,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rMd)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: _inputTheme(false),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: indigo,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.poppins(
              fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: indigo,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.poppins(
              fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: indigo,
        foregroundColor: Colors.white,
      ),
      dividerColor: const Color(0xFFE2E8F0),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: indigo,
        brightness: Brightness.dark,
      ).copyWith(surface: surfaceDark),
      scaffoldBackgroundColor: surfaceDark,
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF131A33),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rMd)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: _inputTheme(true),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: indigo,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.poppins(
              fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: indigo,
        foregroundColor: Colors.white,
      ),
      dividerColor: const Color(0xFF1F2A4A),
    );
  }

  static InputDecorationTheme _inputTheme(bool dark) {
    final fill = dark ? const Color(0xFF131A33) : Colors.white;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide:
          BorderSide(color: dark ? const Color(0xFF1F2A4A) : const Color(0xFFE2E8F0)),
    );
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: indigo, width: 1.5),
      ),
      labelStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: dark ? Colors.white70 : subtle,
          fontWeight: FontWeight.w500),
    );
  }
}
