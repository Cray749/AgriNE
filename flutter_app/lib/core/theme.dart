/// AgriSutra NE — Design System & Theme
/// ========================================
/// SINGLE SOURCE OF TRUTH for all visual constants.
///
/// Rules:
///   1. Never hardcode a color, font size, or padding anywhere in the app.
///      Always import from this file.
///   2. The color palette is optimised for dark-mode on cheap Android screens
///      (low brightness, AMOLED panels) used by farmers in bright daylight.
///   3. Minimum body font: 16sp. Minimum touch target: 48×48px.
///      These are non-negotiable for a 40-45 year old rural user base.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ════════════════════════════════════════════════════════════════════════════
//  COLOUR PALETTE
// ════════════════════════════════════════════════════════════════════════════

// ── Primary greens (trust, nature, agriculture) ─────────────────────────────
const Color kGreenPrimary = Color(0xFF2E7D32); // Deep forest green — buttons, headers
const Color kGreenAccent  = Color(0xFF69F0AE); // Bright mint — CTAs, highlighted values
const Color kGreenLight   = Color(0xFFE8F5E9); // Very light green — subtle backgrounds
const String kFontFamily = 'Poppins';

// ── Backgrounds ─────────────────────────────────────────────────────────────
const Color kBgDark       = Color(0xFF0F1117); // Near-black — main scaffold background
const Color kBgCard       = Color(0xFF1A2420); // Slightly lighter card surface
const Color kBgCardBorder = Color(0xFF2D4A3E); // Card border / divider lines

// ── Text ────────────────────────────────────────────────────────────────────
const Color kTextPrimary   = Color(0xFFE0E0E0); // Off-white — main body text
const Color kTextSecondary = Color(0xFF90A4AE); // Cool grey — labels, subtitles
const Color kTextHighlight = Color(0xFFFFFFFF); // Pure white — critical values

// ── Nutrient-specific (maps exactly to N → P → K, never swap these) ─────────
const Color kColorN = Color(0xFF69F0AE); // Mint green — Nitrogen  / Urea
const Color kColorP = Color(0xFF81D4FA); // Sky blue   — Phosphorus / SSP
const Color kColorK = Color(0xFFFFCC80); // Warm amber — Potassium  / MOP

// ── Status ──────────────────────────────────────────────────────────────────
const Color kSuccess = Color(0xFF4CAF50);
const Color kWarning = Color(0xFFFF9800);
const Color kError   = Color(0xFFE53935);

// ── Fertility class colours (used in chips on wizard and results) ────────────
const Color kFertilityLow    = Color(0xFFEF5350); // Red   — Low fertility
const Color kFertilityMedium = Color(0xFFFFCA28); // Amber — Medium fertility
const Color kFertilityHigh   = Color(0xFF66BB6A); // Green — High fertility


// ════════════════════════════════════════════════════════════════════════════
//  TYPOGRAPHY  (Poppins via google_fonts)
// ════════════════════════════════════════════════════════════════════════════
//
// Usage:  Text("Hello", style: kStyleHeadingXL)
// All sizes are in logical pixels (sp ≡ lp in Flutter).

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
  fontSize: 16, // ← Minimum for farmer readability. Do NOT go below this.
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
/// Must be unmissable even in bright sunlight.
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

/// Convenience: copy a style with a different color.
extension TextStyleX on TextStyle {
  TextStyle withColor(Color c) => copyWith(color: c);
  TextStyle withSize(double s)  => copyWith(fontSize: s);
  TextStyle bold()              => copyWith(fontWeight: FontWeight.w700);
}


// ════════════════════════════════════════════════════════════════════════════
//  SPACING & SHAPE
// ════════════════════════════════════════════════════════════════════════════

// ── Border radii ─────────────────────────────────────────────────────────────
const double kRadiusCard   = 16.0;  // Main content cards
const double kRadiusButton = 12.0;  // Buttons
const double kRadiusChip   = 24.0;  // Pill-shaped selection chips
const double kRadiusSmall  = 8.0;   // Inner elements, badges

// ── Padding ──────────────────────────────────────────────────────────────────
const EdgeInsets kPaddingScreen = EdgeInsets.symmetric(horizontal: 20, vertical: 16);
const EdgeInsets kPaddingCard   = EdgeInsets.all(20);
const EdgeInsets kPaddingButton = EdgeInsets.symmetric(horizontal: 24, vertical: 16);

// ── Standard gaps ────────────────────────────────────────────────────────────
const SizedBox kGapXS = SizedBox(height: 4);
const SizedBox kGapS  = SizedBox(height: 8);
const SizedBox kGapM  = SizedBox(height: 16);
const SizedBox kGapL  = SizedBox(height: 24);
const SizedBox kGapXL = SizedBox(height: 32);

const SizedBox kGapHorizontalS = SizedBox(width: 8);
const SizedBox kGapHorizontalM = SizedBox(width: 16);


// ════════════════════════════════════════════════════════════════════════════
//  CARD DECORATION  (used throughout the app for consistency)
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

/// A card with a colored top-border accent — used for nutrient result cards.
BoxDecoration kNutrientCardDecoration(Color accentColor) => BoxDecoration(
  color: kBgCard,
  borderRadius: BorderRadius.circular(kRadiusCard),
  border: Border.all(color: accentColor.withOpacity(0.45), width: 1.5),
  boxShadow: [
    BoxShadow(
      color: accentColor.withOpacity(0.12),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ],
);

/// Inner card (used for "Why?" expandable sections inside result cards).
BoxDecoration kInnerCardDecoration() => BoxDecoration(
  color: kBgDark,
  borderRadius: BorderRadius.circular(kRadiusSmall),
  border: Border.all(color: kBgCardBorder.withOpacity(0.6)),
);


// ════════════════════════════════════════════════════════════════════════════
//  FERTILITY CLASS HELPERS
// ════════════════════════════════════════════════════════════════════════════

/// Returns the display color for a fertility class string.
Color fertilityClassColor(String fc) {
  switch (fc.toLowerCase()) {
    case 'low':    return kFertilityLow;
    case 'high':   return kFertilityHigh;
    default:       return kFertilityMedium;
  }
}

/// Returns the display label with emoji for a fertility class.
String fertilityClassLabel(String fc) {
  switch (fc.toLowerCase()) {
    case 'low':    return '🔴 LOW';
    case 'high':   return '🟢 HIGH';
    default:       return '🟡 MEDIUM';
  }
}


// ════════════════════════════════════════════════════════════════════════════
//  MATERIAL THEME  (passed into MaterialApp)
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

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: kBgDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: kStyleHeadingM,
      iconTheme: const IconThemeData(color: kGreenAccent),
    ),

    // ElevatedButton default style (all buttons derived from this)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kGreenPrimary,
        foregroundColor: kTextHighlight,
        minimumSize: const Size(double.infinity, 56), // full-width, 56px tall
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusButton),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        elevation: 3,
      ),
    ),

    // OutlinedButton (secondary actions)
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kGreenAccent,
        side: const BorderSide(color: kGreenAccent, width: 1.5),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusButton),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // TextField / Input decoration
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
        borderSide: const BorderSide(color: kGreenAccent, width: 1.8),
      ),
      labelStyle: kStyleBodyM,
      hintStyle: kStyleBodyM.withColor(kTextSecondary.withOpacity(0.6)),
    ),

    // Slider
    sliderTheme: const SliderThemeData(
      activeTrackColor:   kGreenPrimary,
      inactiveTrackColor: kBgCardBorder,
      thumbColor:         kGreenAccent,
      overlayColor:       Color(0x2269F0AE),
      valueIndicatorColor: kGreenPrimary,
    ),

    // Chip
    chipTheme: ChipThemeData(
      backgroundColor:   kBgCard,
      selectedColor:     kGreenPrimary,
      labelStyle:        kStyleBodyM,
      side:              const BorderSide(color: kBgCardBorder),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusChip),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color:     kBgCardBorder,
      thickness: 1,
      space:     1,
    ),

    // SnackBar
    snackBarTheme: SnackBarThemeData(
      backgroundColor:  kBgCard,
      contentTextStyle: kStyleBodyM.withColor(kTextPrimary),
      behavior:         SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusSmall),
      ),
    ),

    // Progress indicator
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color:           kGreenAccent,
      linearTrackColor: kBgCardBorder,
    ),

    textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
      bodyColor:    kTextPrimary,
      displayColor: kTextHighlight,
    ),
  );
}
