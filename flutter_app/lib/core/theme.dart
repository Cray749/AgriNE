/// AgriSutra NE — Design System & Theme
/// ========================================
/// SINGLE SOURCE OF TRUTH for all visual constants.
///
/// Rules:
///   1. Never hardcode a color, font size, or padding anywhere in the app.
///      Always import from this file.
///   2. The dark palette is optimised for cheap AMOLED Android screens used
///      by farmers in bright daylight.
///   3. Minimum body font: 16sp. Minimum touch target: 48x48px.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ════════════════════════════════════════════════════════════════════════════
//  DARK PALETTE (default)
// ════════════════════════════════════════════════════════════════════════════

// ── Primary greens — richer, ICAR-grade ──────────────────────────────────────
const Color kGreenPrimary = Color(0xFF1B5E20); // Deep forest green — buttons, headers
const Color kGreenAccent  = Color(0xFF00E676); // Vivid spring green — CTAs, values
const Color kGreenLight   = Color(0xFFE8F5E9); // Very light green — subtle backgrounds
const String kFontFamily  = 'Poppins';

// ── Dark Backgrounds — warmer, less harsh than pure black ────────────────────
const Color kBgDark       = Color(0xFF111814); // Warm near-black with green tint
const Color kBgCard       = Color(0xFF1C2B22); // Richer card surface
const Color kBgCardBorder = Color(0xFF2D4A35); // Card border / divider lines

// ── Text ────────────────────────────────────────────────────────────────────
const Color kTextPrimary   = Color(0xFFE0E0E0); // Off-white — main body text
const Color kTextSecondary = Color(0xFF90A4AE); // Cool grey — labels, subtitles
const Color kTextHighlight = Color(0xFFFFFFFF); // Pure white — critical values

// ── Nutrient-specific (maps exactly to N -> P -> K, never swap these) ─────────
const Color kColorN = Color(0xFF69F0AE); // Mint green  — Nitrogen  / Urea
const Color kColorP = Color(0xFF40C4FF); // Bright sky blue — Phosphorus / SSP
const Color kColorK = Color(0xFFFFD600); // Harvest yellow — Potassium / MOP

// ── Status ──────────────────────────────────────────────────────────────────
const Color kSuccess = Color(0xFF4CAF50);
const Color kWarning = Color(0xFFFF9800);
const Color kError   = Color(0xFFE53935);

// ── Fertility class colours ──────────────────────────────────────────────────
const Color kFertilityLow    = Color(0xFFEF5350);
const Color kFertilityMedium = Color(0xFFFFCA28);
const Color kFertilityHigh   = Color(0xFF66BB6A);

// ── Gradient for header banners ───────────────────────────────────────────────
const List<Color> kGradientHeader = [
  Color(0xFF1B5E20),
  Color(0xFF2E7D32),
  Color(0xFF388E3C),
];


// ════════════════════════════════════════════════════════════════════════════
//  LIGHT PALETTE  (primary theme)
// ════════════════════════════════════════════════════════════════════════════

const Color kLightBgPrimary     = Color(0xFFF0F7EE); // Crisp warm white with green tint
const Color kLightBgSecondary   = Color(0xFFE8F5E9); // Slightly deeper for section breaks
const Color kLightBgCard        = Color(0xFFFFFFFF); // Pure white cards
const Color kLightBgCardBorder  = Color(0xFFCDE8C0); // Soft green border
const Color kLightTextPrimary   = Color(0xFF1A2E1A); // Near-black with green tint
const Color kLightTextSecondary = Color(0xFF4A7C40); // Medium green for subtitles
const Color kLightTextMuted     = Color(0xFF8BA88B); // Muted for labels
const Color kLightAccent        = Color(0xFF2E7D32); // Strong green CTA
const Color kLightAccentSoft    = Color(0xFF43A047); // Softer green for secondary actions


// ════════════════════════════════════════════════════════════════════════════
//  TYPOGRAPHY  (Poppins via google_fonts)
// ════════════════════════════════════════════════════════════════════════════

final TextStyle kStyleHeadingXL = GoogleFonts.poppins(
  fontSize: 28,
  fontWeight: FontWeight.w700,
  color: kTextHighlight,
  height: 1.25,
);

final TextStyle kStyleHeadingL = GoogleFonts.poppins(
  fontSize: 22,
  fontWeight: FontWeight.w700,
  color: kTextHighlight,
  height: 1.3,
);

final TextStyle kStyleHeadingM = GoogleFonts.poppins(
  fontSize: 18,
  fontWeight: FontWeight.w600,
  color: kTextPrimary,
  height: 1.35,
);

final TextStyle kStyleBodyL = GoogleFonts.poppins(
  fontSize: 16,
  fontWeight: FontWeight.w400,
  color: kTextPrimary,
  height: 1.5,
);

final TextStyle kStyleBodyM = GoogleFonts.poppins(
  fontSize: 14,
  fontWeight: FontWeight.w400,
  color: kTextSecondary,
  height: 1.5,
);

final TextStyle kStyleLabel = GoogleFonts.poppins(
  fontSize: 12,
  fontWeight: FontWeight.w500,
  color: kTextSecondary,
  letterSpacing: 0.4,
);

/// The BIG number shown on results cards — urea/ssp/mop kg/ha.
final TextStyle kStyleValueXL = GoogleFonts.poppins(
  fontSize: 36,
  fontWeight: FontWeight.w700,
  color: kGreenAccent,
  height: 1.1,
);

final TextStyle kStyleValueL = GoogleFonts.poppins(
  fontSize: 24,
  fontWeight: FontWeight.w700,
  color: kTextHighlight,
  height: 1.2,
);

extension TextStyleX on TextStyle {
  TextStyle withColor(Color c) => copyWith(color: c);
  TextStyle withSize(double s)  => copyWith(fontSize: s);
  TextStyle bold()              => copyWith(fontWeight: FontWeight.w700);
}


// ════════════════════════════════════════════════════════════════════════════
//  CONTEXT-AWARE COLOR HELPERS
//  Use these in screens so they work in BOTH light and dark mode.
// ════════════════════════════════════════════════════════════════════════════

/// Background colour for the scaffold
Color ctxBg(BuildContext ctx) =>
    Theme.of(ctx).brightness == Brightness.light ? kLightBgPrimary : kBgDark;

/// Card surface colour
Color ctxCard(BuildContext ctx) =>
    Theme.of(ctx).brightness == Brightness.light ? kLightBgCard : kBgCard;

/// Card border colour
Color ctxCardBorder(BuildContext ctx) =>
    Theme.of(ctx).brightness == Brightness.light ? kLightBgCardBorder : kBgCardBorder;

/// Primary text colour
Color ctxTextPrimary(BuildContext ctx) =>
    Theme.of(ctx).brightness == Brightness.light ? kLightTextPrimary : kTextPrimary;

/// Secondary text colour
Color ctxTextSecondary(BuildContext ctx) =>
    Theme.of(ctx).brightness == Brightness.light ? kLightTextSecondary : kTextSecondary;

/// Muted label colour
Color ctxTextMuted(BuildContext ctx) =>
    Theme.of(ctx).brightness == Brightness.light ? kLightTextMuted : kTextSecondary;

/// Accent / highlight colour (green CTA)
Color ctxAccent(BuildContext ctx) =>
    Theme.of(ctx).brightness == Brightness.light ? kLightAccent : kGreenAccent;

/// Bold heading colour
Color ctxHeading(BuildContext ctx) =>
    Theme.of(ctx).brightness == Brightness.light ? kLightTextPrimary : kTextHighlight;

/// Card BoxDecoration that adapts to theme
BoxDecoration ctxCardDecoration(BuildContext ctx, {Color? borderColor, Color? glowColor}) =>
    BoxDecoration(
      color: ctxCard(ctx),
      borderRadius: BorderRadius.circular(kRadiusCard),
      border: Border.all(
        color: borderColor ?? ctxCardBorder(ctx),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: (glowColor ?? kGreenPrimary).withOpacity(
              Theme.of(ctx).brightness == Brightness.light ? 0.08 : 0.25),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );


// ════════════════════════════════════════════════════════════════════════════
//  SPACING & SHAPE
// ════════════════════════════════════════════════════════════════════════════

const double kRadiusCard   = 16.0;
const double kRadiusButton = 12.0;
const double kRadiusChip   = 24.0;
const double kRadiusSmall  = 8.0;

const EdgeInsets kPaddingScreen = EdgeInsets.symmetric(horizontal: 20, vertical: 16);
const EdgeInsets kPaddingCard   = EdgeInsets.all(20);
const EdgeInsets kPaddingButton = EdgeInsets.symmetric(horizontal: 24, vertical: 16);

const SizedBox kGapXS = SizedBox(height: 4);
const SizedBox kGapS  = SizedBox(height: 8);
const SizedBox kGapM  = SizedBox(height: 16);
const SizedBox kGapL  = SizedBox(height: 24);
const SizedBox kGapXL = SizedBox(height: 32);

const SizedBox kGapHorizontalS = SizedBox(width: 8);
const SizedBox kGapHorizontalM = SizedBox(width: 16);


// ════════════════════════════════════════════════════════════════════════════
//  CARD DECORATIONS
// ════════════════════════════════════════════════════════════════════════════

BoxDecoration kCardDecoration({Color? borderColor}) => BoxDecoration(
  color: kBgCard,
  borderRadius: BorderRadius.circular(kRadiusCard),
  border: Border.all(color: borderColor ?? kBgCardBorder, width: 1.2),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.35),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ],
);

BoxDecoration kNutrientCardDecoration(Color accentColor) => BoxDecoration(
  color: kBgCard,
  borderRadius: BorderRadius.circular(kRadiusCard),
  border: Border.all(color: accentColor.withOpacity(0.45), width: 1.5),
  boxShadow: [
    BoxShadow(
      color: accentColor.withOpacity(0.15),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ],
);

BoxDecoration kInnerCardDecoration() => BoxDecoration(
  color: kBgDark,
  borderRadius: BorderRadius.circular(kRadiusSmall),
  border: Border.all(color: kBgCardBorder.withOpacity(0.6)),
);


// ════════════════════════════════════════════════════════════════════════════
//  FERTILITY CLASS HELPERS
// ════════════════════════════════════════════════════════════════════════════

Color fertilityClassColor(String fc) {
  switch (fc.toLowerCase()) {
    case 'low':    return kFertilityLow;
    case 'high':   return kFertilityHigh;
    default:       return kFertilityMedium;
  }
}

String fertilityClassLabel(String fc) {
  switch (fc.toLowerCase()) {
    case 'low':    return '🔴 LOW';
    case 'high':   return '🟢 HIGH';
    default:       return '🟡 MEDIUM';
  }
}


// ════════════════════════════════════════════════════════════════════════════
//  DARK MATERIAL THEME  (default)
// ════════════════════════════════════════════════════════════════════════════

ThemeData buildAppTheme() {
  final base = ThemeData.dark();

  return base.copyWith(
    useMaterial3: true,
    scaffoldBackgroundColor: kBgDark,

    colorScheme: const ColorScheme.dark(
      primary:   kGreenPrimary,
      secondary: kGreenAccent,
      surface:   kBgCard,
      error:     kError,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: kBgDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: kStyleHeadingM,
      iconTheme: const IconThemeData(color: kGreenAccent),
      surfaceTintColor: Colors.transparent,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kGreenPrimary,
        foregroundColor: kTextHighlight,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusButton),
        ),
        textStyle: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600),
        elevation: 4,
        shadowColor: kGreenPrimary.withOpacity(0.5),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kGreenAccent,
        side: const BorderSide(color: kGreenAccent, width: 1.5),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusButton),
        ),
        textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),

    cardTheme: CardThemeData(
      color: kBgCard,
      elevation: 8,
      shadowColor: kGreenAccent.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusCard),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kBgCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusSmall),
        borderSide: const BorderSide(color: kBgCardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusSmall),
        borderSide: const BorderSide(color: kBgCardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusSmall),
        borderSide: const BorderSide(color: kGreenAccent, width: 2),
      ),
      labelStyle: kStyleBodyM,
      hintStyle: kStyleBodyM.withColor(kTextSecondary.withOpacity(0.6)),
    ),

    sliderTheme: const SliderThemeData(
      activeTrackColor:    kGreenPrimary,
      inactiveTrackColor:  kBgCardBorder,
      thumbColor:          kGreenAccent,
      overlayColor:        Color(0x2200E676),
      valueIndicatorColor: kGreenPrimary,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: kBgCard,
      selectedColor:   kGreenPrimary,
      labelStyle:      kStyleBodyM,
      side:            const BorderSide(color: kBgCardBorder),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusChip),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    ),

    dividerTheme: const DividerThemeData(
      color:     kBgCardBorder,
      thickness: 1,
      space:     1,
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor:  kBgCard,
      contentTextStyle: kStyleBodyM.withColor(kTextPrimary),
      behavior:         SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusSmall),
      ),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color:            kGreenAccent,
      linearTrackColor: kBgCardBorder,
    ),

    textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
      bodyColor:    kTextPrimary,
      displayColor: kTextHighlight,
    ),
  );
}


// ════════════════════════════════════════════════════════════════════════════
//  LIGHT MATERIAL THEME
// ════════════════════════════════════════════════════════════════════════════

ThemeData buildLightTheme() {
  final base = ThemeData.light();

  return base.copyWith(
    useMaterial3: true,
    scaffoldBackgroundColor: kLightBgPrimary,

    colorScheme: const ColorScheme.light(
      primary:   kGreenPrimary,
      secondary: Color(0xFF2E7D32),
      surface:   kLightBgCard,
      error:     kError,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: kLightBgPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: kLightTextPrimary,
      ),
      iconTheme: const IconThemeData(color: kGreenPrimary),
      surfaceTintColor: Colors.transparent,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kGreenPrimary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusButton),
        ),
        textStyle: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600),
        elevation: 4,
        shadowColor: kGreenPrimary.withOpacity(0.4),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kGreenPrimary,
        side: const BorderSide(color: kGreenPrimary, width: 1.5),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusButton),
        ),
        textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),

    cardTheme: CardThemeData(
      color: kLightBgCard,
      elevation: 4,
      shadowColor: kGreenPrimary.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusCard),
        side: const BorderSide(color: kLightBgCardBorder, width: 1),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kLightBgCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusSmall),
        borderSide: const BorderSide(color: kLightBgCardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusSmall),
        borderSide: const BorderSide(color: kLightBgCardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusSmall),
        borderSide: const BorderSide(color: kGreenPrimary, width: 2),
      ),
      labelStyle: GoogleFonts.poppins(fontSize: 14, color: kLightTextSecondary),
      hintStyle: GoogleFonts.poppins(fontSize: 14, color: kLightTextSecondary.withOpacity(0.6)),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: kLightBgCard,
      selectedColor:   kGreenPrimary,
      labelStyle: GoogleFonts.poppins(fontSize: 14, color: kLightTextPrimary),
      side: const BorderSide(color: kLightBgCardBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusChip)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    ),

    dividerTheme: const DividerThemeData(
      color: kLightBgCardBorder,
      thickness: 1,
      space: 1,
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor:  kLightBgCard,
      contentTextStyle: GoogleFonts.poppins(fontSize: 14, color: kLightTextPrimary),
      behavior:         SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSmall)),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color:            kGreenPrimary,
      linearTrackColor: kLightBgCardBorder,
    ),

    textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
      bodyColor:    kLightTextPrimary,
      displayColor: kLightTextPrimary,
    ),
  );
}
