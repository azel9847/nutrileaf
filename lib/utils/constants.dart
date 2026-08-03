import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Color Palette ───────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  // ── Primary Brand ──
  static const Color primaryGreen = Color(0xFF43593E);
  static const Color lightGreen = Color(0xFF5A7354);
  static const Color paleGreen = Color(0xFFE4EBE3);
  static const Color leafGreen = Color(0xFF4E6648);
  static const Color darkGreen = Color(0xFF324430);
  static const Color mintGreen = Color(0xFF8EA88A);
  static const Color softGreen = Color(0xFFB3C5B0);

  // ── Pastel Earth Tones ──
  static const Color warmSand = Color(0xFFFFF8E1);
  static const Color softBrown = Color(0xFFBCAAA4);
  static const Color earthBeige = Color(0xFFEFEBE9);
  static const Color softCoral = Color(0xFFFFCDD2);
  static const Color terracotta = Color(0xFFC67B5C);
  static const Color terracottaLight = Color(0xFFDEA68A);

  // ── Light Neutrals ──
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF4F4EB);
  static const Color softBackground = Color(0xFFF4F4EB);
  static const Color darkText = Color(0xFF43593E);
  static const Color bodyText = Color(0xFF4A5A4A);
  static const Color caption = Color(0xFF8A9A8A);
  static const Color divider = Color(0xFFE0E4DC);
  static const Color cardShadow = Color(0x1A43593E);

  // ── Dark Theme Colors ──
  static const Color darkSurface = Color(0xFF243024);
  static const Color darkCard = Color(0xFF2C3D2C);
  static const Color darkBackground = Color(0xFF1C291C);
  static const Color darkDivider = Color(0xFF3E5340);
  static const Color darkCaption = Color(0xFF8A9A8A);
  static const Color darkBodyText = Color(0xFFBCC8BC);
  static const Color darkHeadingText = Color(0xFFE0ECE0);

  // ── Accent Colors for Nutrients ──
  static const Color nitrogen = Color(0xFF42A5F5);
  static const Color phosphorus = Color(0xFFFF7043);
  static const Color potassium = Color(0xFFAB47BC);
  static const Color calcium = Color(0xFF26C6DA);
  static const Color magnesium = Color(0xFFFFA726);
  static const Color healthy = Color(0xFF43593E);

  // ── Crop Colors ──
  static const Color rice = Color(0xFFFDD835);
  static const Color corn = Color(0xFFFF8F00);
  static const Color vegetable = Color(0xFF43593E);

  // ── Status Colors ──
  static const Color warningAmber = Color(0xFFFFB74D);
  static const Color dangerRed = Color(0xFFEF5350);
  static const Color successGreen = Color(0xFF43593E);

  // ── Solid Color Presets (No Gradients) ──
  static const Color splashBackground = Color(0xFF43593E);
  static const Color cardBackground = Color(0xFFF4F4EB);
  static const Color welcomeBackground = Color(0xFFF4F4EB);
}

// ─── Soft Shadow Helpers ─────────────────────────────────────────────────────

class SoftShadows {
  SoftShadows._();

  /// Light-theme soft raised card shadows
  static List<BoxShadow> get lightRaised => [
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.8),
          offset: const Offset(-4, -4),
          blurRadius: 12,
        ),
        BoxShadow(
          color: AppColors.cardShadow.withValues(alpha: 0.12),
          offset: const Offset(4, 4),
          blurRadius: 12,
        ),
      ];

  /// Subtler version for smaller components
  static List<BoxShadow> get lightSubtle => [
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.6),
          offset: const Offset(-2, -2),
          blurRadius: 8,
        ),
        BoxShadow(
          color: AppColors.cardShadow.withValues(alpha: 0.08),
          offset: const Offset(2, 2),
          blurRadius: 8,
        ),
      ];

  /// Dark-theme neumorphic shadows
  static List<BoxShadow> get darkRaised => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          offset: const Offset(4, 4),
          blurRadius: 12,
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.04),
          offset: const Offset(-4, -4),
          blurRadius: 12,
        ),
      ];

  static List<BoxShadow> get darkSubtle => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          offset: const Offset(2, 2),
          blurRadius: 8,
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.03),
          offset: const Offset(-2, -2),
          blurRadius: 8,
        ),
      ];

  /// Soft diffused shadow for CTA buttons
  static List<BoxShadow> get ctaButton => [
        BoxShadow(
          color: AppColors.primaryGreen.withValues(alpha: 0.30),
          offset: const Offset(0, 6),
          blurRadius: 20,
          spreadRadius: 0,
        ),
      ];

  /// Colored glow for buttons
  static List<BoxShadow> colorGlow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.25),
          offset: const Offset(0, 4),
          blurRadius: 16,
        ),
      ];
}

// ─── Typography ──────────────────────────────────────────────────────────────

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get headline1 => GoogleFonts.alata(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.darkText,
        height: 1.3,
      );

  static TextStyle get headline2 => GoogleFonts.alata(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.darkText,
        height: 1.3,
      );

  static TextStyle get headline3 => GoogleFonts.alata(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.darkText,
        height: 1.4,
      );

  static TextStyle get subtitle => GoogleFonts.alata(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.darkText,
      );

  static TextStyle get body => GoogleFonts.alata(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.bodyText,
        height: 1.5,
      );

  static TextStyle get bodyBold => GoogleFonts.alata(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.bodyText,
      );

  static TextStyle get caption => GoogleFonts.alata(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.caption,
      );

  static TextStyle get button => GoogleFonts.alata(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
        letterSpacing: 0.5,
      );

  static TextStyle get navLabel => GoogleFonts.alata(
        fontSize: 11,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get percentageLarge => GoogleFonts.alata(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryGreen,
      );
}

// ─── Dimensions ──────────────────────────────────────────────────────────────

class AppDimens {
  AppDimens._();

  static const double paddingXS = 4;
  static const double paddingSM = 8;
  static const double paddingMD = 16;
  static const double paddingLG = 24;
  static const double paddingXL = 32;

  static const double radiusSM = 12;
  static const double radiusMD = 20;
  static const double radiusLG = 28;
  static const double radiusXL = 36;

  static const double iconSM = 20;
  static const double iconMD = 24;
  static const double iconLG = 32;
  static const double iconXL = 48;

  static const double cardElevation = 0; // Soft UI uses shadows, not elevation
  static const double bottomNavHeight = 80;

  static const double softShadowBlur = 20;
  static const double softShadowOffset = 8;
}

// ─── Theme Data ──────────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: AppColors.primaryGreen,
        scaffoldBackgroundColor: AppColors.softBackground,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primaryGreen,
          secondary: AppColors.lightGreen,
          surface: AppColors.offWhite,
          error: AppColors.dangerRed,
          onPrimary: AppColors.white,
          onSecondary: AppColors.white,
          onSurface: AppColors.bodyText,
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.darkText,
          titleTextStyle: GoogleFonts.alata(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          ),
          color: AppColors.offWhite,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: AppColors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusLG),
            ),
            textStyle: AppTextStyles.button,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryGreen,
            textStyle: AppTextStyles.bodyBold,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: AppColors.white,
          elevation: 0,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusSM),
          ),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: AppColors.primaryGreen,
        scaffoldBackgroundColor: AppColors.darkBackground,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.leafGreen,
          secondary: AppColors.lightGreen,
          surface: AppColors.darkCard,
          error: AppColors.dangerRed,
          onPrimary: AppColors.white,
          onSecondary: AppColors.white,
          onSurface: AppColors.darkBodyText,
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.darkHeadingText,
          titleTextStyle: GoogleFonts.alata(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.darkHeadingText,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          ),
          color: AppColors.darkCard,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: AppColors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusLG),
            ),
            textStyle: AppTextStyles.button,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.leafGreen,
            textStyle: AppTextStyles.bodyBold,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.leafGreen,
          foregroundColor: AppColors.white,
          elevation: 0,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.darkDivider,
          thickness: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.darkCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusSM),
          ),
        ),
      );
}
