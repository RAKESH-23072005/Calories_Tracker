import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── LifeFit Primary Palette ──────────────────────────────────────────
  static const Color primaryGreen = Color(0xFF2DB573);
  static const Color primaryGreenLight = Color(0xFF5DD39E);
  static const Color primaryGreenDark = Color(0xFF1E8A56);
  static const Color primaryGreenSurface = Color(0xFFE8F8F0);

  // ── Neutral Colors ───────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF7F8FA);
  static const Color softGrey = Color(0xFFF2F3F5);
  static const Color mediumGrey = Color(0xFFE0E2E8);
  static const Color darkGrey = Color(0xFF1F2937);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // ── Accent Colors ────────────────────────────────────────────────────
  static const Color accentOrange = Color(0xFFFF9F43);
  static const Color accentRed = Color(0xFFEE5A5A);
  static const Color accentBlue = Color(0xFF54A0FF);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentPink = Color(0xFFFF6B9D);

  // ── Meal Colors (LifeFit style) ──────────────────────────────────────
  static const Color breakfastColor = Color(0xFFFFB74D);
  static const Color lunchColor = Color(0xFF4FC3F7);
  static const Color dinnerColor = Color(0xFF7E57C2);
  static const Color snackColor = Color(0xFFFF8A65);

  // ── Health-related Colors ────────────────────────────────────────────
  static const Color softYellow = Color(0xFFFFF9C4);
  static const Color warningYellow = Color(0xFFFFD54F);
  static const Color healthGreen = Color(0xFF66BB6A);

  // ── Card & Surface ───────────────────────────────────────────────────
  static const double cardRadius = 20.0;
  static const double buttonRadius = 16.0;
  static const double inputRadius = 14.0;

  // ── Shadows ──────────────────────────────────────────────────────────
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];

  // ── Cached Poppins base (avoids repeated GoogleFonts lookups) ───────
  static final TextStyle _poppinsBase = GoogleFonts.poppins();

  // ── Text Styles (derived from cached base) ────────────────────────
  static TextStyle get headingLarge => _poppinsBase.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static TextStyle get headingMedium => _poppinsBase.copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static TextStyle get headingSmall => _poppinsBase.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static TextStyle get bodyLarge => _poppinsBase.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  static TextStyle get bodyMedium => _poppinsBase.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static TextStyle get bodySmall => _poppinsBase.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textTertiary,
  );

  static TextStyle get labelBold => _poppinsBase.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static TextStyle get caption => _poppinsBase.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: textTertiary,
  );

  // ── Theme Data ───────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.poppinsTextTheme();

    return ThemeData(
      useMaterial3: true,
      textTheme: textTheme,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.light,
        primary: primaryGreen,
        secondary: primaryGreenLight,
        surface: white,
        error: accentRed,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: softGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: accentRed),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: textTertiary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return primaryGreen;
            }
            return white;
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return white;
            }
            return darkGrey;
          }),
        ),
      ),
      chipTheme: ChipThemeData(
        selectedColor: primaryGreen,
        backgroundColor: softGrey,
        labelStyle: GoogleFonts.poppins(fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        side: BorderSide.none,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: softGrey,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(inputRadius),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
