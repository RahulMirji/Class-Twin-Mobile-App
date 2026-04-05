import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Class Twin Design System — "Warm Minimalism"
/// Inspired by organic, tactile home-app aesthetic
class AppTheme {
  AppTheme._();

  // ─── Color Tokens ───────────────────────────────────────────────
  // Primary palette — warm amber-brown
  static const Color primary = Color(0xFFA0522D);
  static const Color primaryDim = Color(0xFF8B4513);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFF5E6D8);

  // Secondary
  static const Color secondary = Color(0xFF6B4C3B);
  static const Color secondaryContainer = Color(0xFFEEDDD5);
  static const Color onSecondary = Color(0xFFFFFFFF);

  // Tertiary — signature green accent (keep for "Got It" / success)
  static const Color tertiary = Color(0xFF2D6A4F);
  static const Color tertiaryContainer = Color(0xFFBEFFDC);
  static const Color onTertiary = Color(0xFFE6FFEE);

  // Surface hierarchy — "warm paper" model
  static const Color surface = Color(0xFFF8FAF8);
  static const Color surfaceBright = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFE8EDE8);
  static const Color surfaceContainerHigh = Color(0xFFE0E8E0);
  static const Color surfaceContainerHighest = Color(0xFFD8E2D8);
  static const Color surfaceContainerLow = Color(0xFFF2F5F2);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFCDD8CD);

  // On-surface
  static const Color onSurface = Color(0xFF1A1A1A);
  static const Color onSurfaceVariant = Color(0xFF6B7280);

  // Outline
  static const Color outline = Color(0xFF9CA3AF);
  static const Color outlineVariant = Color(0xFFD1D5DB);

  // Inverse
  static const Color inverseSurface = Color(0xFF1A1A1A);
  static const Color onInverseSurface = Color(0xFFF3F4F6);
  static const Color inversePrimary = Color(0xFFFFFFFF);

  // Error
  static const Color error = Color(0xFF9E422C);
  static const Color errorContainer = Color(0xFFFEE2D5);
  static const Color onError = Color(0xFFFFFFFF);

  // ─── Semantic Colors ────────────────────────────────────────────
  static const Color responseGotIt = Color(0xFF2D6A4F);    // green — mastery
  static const Color responseSomewhat = Color(0xFFD4A017);  // amber — partial
  static const Color responseLost = Color(0xFF9E422C);      // red-brown — lost

  // ─── Text Colors ────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // ─── Special ────────────────────────────────────────────────────
  static const Color streamBackground = Color(0xFF000000);
  static const Color accentInk = Color(0xFF2D6A4F);

  // ─── Nav Dark Pill ──────────────────────────────────────────────
  static const Color navBackground = Color(0xFF1C1C1E);
  static const Color navIcon = Color(0xFFFFFFFF);
  static const Color navIconInactive = Color(0xFF8E8E93);

  // ─── Border & Radius Tokens ─────────────────────────────────────
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusXxl = 28.0;
  static const double radiusFull = 9999.0;

  // ─── Spacing ────────────────────────────────────────────────────
  static const double spacing2 = 2.0;
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing28 = 28.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;
  static const double spacing64 = 64.0;
  static const double spacing80 = 80.0;

  // ─── Gradients ──────────────────────────────────────────────────
  /// Soft sage-green header gradient (top of Dashboard, Profile)
  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFFDDEBDD), Color(0xFFF8FAF8)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 1.0],
  );

  /// Warm amber-brown gradient for active/live cards
  static const LinearGradient activeCardGradient = LinearGradient(
    colors: [Color(0xFFB8622A), Color(0xFF7A3B10)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Subtle warm tint gradient for onboarding background
  static const LinearGradient onboardingGradient = LinearGradient(
    colors: [Color(0xFFE8F0E8), Color(0xFFFAFAFA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Elevation (Ambient Shadow) ─────────────────────────────────
  static List<BoxShadow> get ambientShadow => [
        BoxShadow(
          color: const Color(0xFF1A1A1A).withValues(alpha: 0.07),
          blurRadius: 24,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get ambientShadowWarm => [
        BoxShadow(
          color: const Color(0xFFA0522D).withValues(alpha: 0.18),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF1A1A1A).withValues(alpha: 0.06),
          blurRadius: 16,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ];

  // ─── Typography ─────────────────────────────────────────────────
  // Headline / Display — "The Intellectual Voice"
  static TextStyle get displayLarge => GoogleFonts.newsreader(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        height: 1.2,
        letterSpacing: -0.5,
      );

  static TextStyle get displayMedium => GoogleFonts.newsreader(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        height: 1.2,
        letterSpacing: -0.3,
      );

  static TextStyle get displaySmall => GoogleFonts.newsreader(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        height: 1.2,
      );

  static TextStyle get headlineMedium => GoogleFonts.newsreader(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        height: 1.3,
      );

  // Body / UI — "The Functional Voice"
  static TextStyle get titleLarge => GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get titleMedium => GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      );

  static TextStyle get labelLarge => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get labelMedium => GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      );

  static TextStyle get labelSmall => GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: textTertiary,
      );

  // ─── Theme Data ─────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: surface,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        tertiary: tertiary,
        tertiaryContainer: tertiaryContainer,
        surface: surface,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        error: error,
        errorContainer: errorContainer,
        onError: onError,
        outline: outline,
        outlineVariant: outlineVariant,
        inverseSurface: inverseSurface,
        onInverseSurface: onInverseSurface,
        inversePrimary: inversePrimary,
      ),
      textTheme: TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        displaySmall: displaySmall,
        headlineMedium: headlineMedium,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: titleLarge,
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return surfaceContainerHighest;
            }
            if (states.contains(WidgetState.pressed)) {
              return primaryDim;
            }
            return primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return textTertiary;
            }
            return onPrimary;
          }),
          elevation: WidgetStateProperty.all(0),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusFull)),
          ),
          textStyle: WidgetStateProperty.all(
            GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusFull),
          ),
          side: const BorderSide(color: outlineVariant),
          textStyle: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerLow,
        hintStyle: bodyMedium.copyWith(color: textTertiary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: outlineVariant,
        thickness: 0.5,
        space: 0,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) return onPrimary;
          return surfaceContainerLowest;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return surfaceContainerHigh;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }
}
