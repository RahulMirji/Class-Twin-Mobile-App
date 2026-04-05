import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Class Twin Design System — "Editorial Serenity"
/// Based on the Calm Clarity Design from Stitch
class AppTheme {
  AppTheme._();

  // ─── Color Tokens ───────────────────────────────────────────────
  // Primary palette — warm, paper-like neutrals, now darkened for better contrast
  static const Color primary = Color(0xFF2D2C2A);
  static const Color primaryDim = Color(0xFF1F1E1D);
  static const Color onPrimary = Color(0xFFFCF7F3);
  static const Color primaryContainer = Color(0xFFE6E2DE);

  // Secondary
  static const Color secondary = Color(0xFF3D3C38);
  static const Color secondaryContainer = Color(0xFFE5E2DC);
  static const Color onSecondary = Color(0xFFFCF9F2);

  // Tertiary — signature green accent
  static const Color tertiary = Color(0xFF2D6A4F);
  static const Color tertiaryContainer = Color(0xFFBEFFDC);
  static const Color onTertiary = Color(0xFFE6FFEE);

  // Surface hierarchy — "stacked paper" model
  static const Color surface = Color(0xFFF9F9F8);
  static const Color surfaceBright = Color(0xFFF9F9F8);
  static const Color surfaceContainer = Color(0xFFEBEEED);
  static const Color surfaceContainerHigh = Color(0xFFE4E9E8);
  static const Color surfaceContainerHighest = Color(0xFFDDE4E3);
  static const Color surfaceContainerLow = Color(0xFFF2F4F3);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFD4DCDA);

  // On-surface
  static const Color onSurface = Color(0xFF2D3433);
  static const Color onSurfaceVariant = Color(0xFF5A6060);

  // Outline
  static const Color outline = Color(0xFF757C7B);
  static const Color outlineVariant = Color(0xFFADB3B2);

  // Inverse
  static const Color inverseSurface = Color(0xFF0C0F0E);
  static const Color onInverseSurface = Color(0xFF9C9D9C);
  static const Color inversePrimary = Color(0xFFFFFFFF);

  // Error
  static const Color error = Color(0xFF9E422C);
  static const Color errorContainer = Color(0xFFFE8B70);
  static const Color onError = Color(0xFFFFF7F6);

  // ─── Semantic Colors ────────────────────────────────────────────
  static const Color responseGotIt = Color(0xFF2D6A4F);    // green — mastery
  static const Color responseSomewhat = Color(0xFFD4A017);  // amber — partial
  static const Color responseLost = Color(0xFF9E422C);      // red-brown — lost

  // ─── Text Colors ────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1917);
  static const Color textSecondary = Color(0xFF5A6060);
  static const Color textTertiary = Color(0xFF757C7B);

  // ─── Special ────────────────────────────────────────────────────
  static const Color streamBackground = Color(0xFF000000);
  static const Color accentInk = Color(0xFF2D6A4F);

  // ─── Border & Radius Tokens ─────────────────────────────────────
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radiusXxl = 24.0;
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

  // ─── Elevation (Ambient Shadow) ─────────────────────────────────
  static List<BoxShadow> get ambientShadow => [
        BoxShadow(
          color: const Color(0xFF1A1917).withValues(alpha: 0.06),
          blurRadius: 40,
          offset: const Offset(0, 12),
        ),
      ];

  // ─── Typography ─────────────────────────────────────────────────
  // Headline / Display — "The Intellectual Voice"
  static TextStyle get displayLarge => GoogleFonts.newsreader(
        fontSize: 36,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        height: 1.2,
        letterSpacing: -0.5,
      );

  static TextStyle get displayMedium => GoogleFonts.newsreader(
        fontSize: 28,
        fontWeight: FontWeight.w500,
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
        fontWeight: FontWeight.w500,
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
        backgroundColor: surface,
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
              return Colors.black; // Even darker when clicked
            }
            return primary; // The new darker primary
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return textTertiary;
            }
            return onPrimary;
          }),
          elevation: WidgetStateProperty.all(0),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
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
            borderRadius: BorderRadius.circular(radiusLg),
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
          foregroundColor: tertiary,
          textStyle: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerLow,
        hintStyle: bodyMedium.copyWith(color: textTertiary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: outlineVariant,
        thickness: 0.5,
        space: 0,
      ),
    );
  }
}
