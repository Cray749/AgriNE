/// AgriSutra NE — Dart Data Models
/// ==================================
/// These classes MUST stay in sync with `backend/models/schemas.py`.
/// JSON field names use snake_case (matching Python backend).
/// Dart property names use camelCase (Dart convention).
///
/// Data flow:
///   Flutter sends:    RecommendRequest   →  toJson()  → POST /recommend/
///   Flutter receives: RecommendResponse  ← fromJson() ← 200 response body
///
/// SoilInputState is a mutable helper for the wizard UI — it is NOT sent
/// to the backend directly. Call .toSoilInput() to get the sendable object.

import 'package:flutter/material.dart';
import 'theme.dart';


// ════════════════════════════════════════════════════════════════════════════
//  REQUEST MODELS (Flutter → Backend)
// ════════════════════════════════════════════════════════════════════════════

/// Mirrors `SoilInput` in schemas.py.
///
/// The farmer picks EITHER a fertility class OR enters a raw soil-test value.
/// Never set both. The backend validates this and will return 422 if invalid.
class SoilInput {
  /// "class" — farmer selected Low / Medium / High
  /// "value" — farmer entered a raw kg/ha number from their soil test
  final String mode;

  /// Required when mode == "class". One of: "low", "medium", "high".
  final String? fertilityClass;

  /// Required when mode == "value". Positive number in kg/ha.
  final double? rawValue;

  const SoilInput({
    required this.mode,
    this.fertilityClass,
    this.rawValue,
  });

  Map<String, dynamic> toJson() => {
    'mode': mode,
    // Only include the field relevant to the chosen mode.
    // Backend ignores extras but keeping it clean avoids confusion.
    if (fertilityClass != null) 'fertility_class': fertilityClass,
    if (rawValue != null)       'raw_value': rawValue,
  };

  /// Named constructors for convenience in the wizard.
  const SoilInput.fromClass(String fc)
      : mode = 'class',
        fertilityClass = fc,
        rawValue = null;

  const SoilInput.fromValue(double val)
      : mode = 'value',
        rawValue = val,
        fertilityClass = null;
}


/// Mirrors `RecommendRequest` in schemas.py.
///
/// Sent when the farmer taps "Get Recommendation" on the wizard's review page.
class RecommendRequest {
  /// "maize" or "kholar" (lowercase, must match FPEEngine crop names exactly)
  final String crop;

  /// Target yield in quintals per hectare (q/ha). E.g. 40.0 for maize.
  final double targetYield;

  /// Nitrogen soil input — resolved independently from P and K.
  final SoilInput nitrogenInput;

  /// Phosphorus soil input — resolved independently from N and K.
  final SoilInput phosphorusInput;

  /// Potassium soil input — resolved independently from N and P.
  final SoilInput potassiumInput;

  /// Farmer's land size in acres. Used only to scale product_kg_total.
  /// Default: 1.0 acre. Loaded from SharedPreferences (farmer profile).
  final double landSizeAcres;

  const RecommendRequest({
    required this.crop,
    required this.targetYield,
    required this.nitrogenInput,
    required this.phosphorusInput,
    required this.potassiumInput,
    this.landSizeAcres = 1.0,
    this.lat = 25.9,
    this.lon = 94.3,
  });

  /// GPS coordinates for NASA POWER weather lookup.
  /// Defaults to Kiphire, Nagaland if not provided.
  final double lat;
  final double lon;

  Map<String, dynamic> toJson() => {
    'crop':              crop,
    'target_yield':      targetYield,
    'nitrogen_input':    nitrogenInput.toJson(),
    'phosphorus_input':  phosphorusInput.toJson(),
    'potassium_input':   potassiumInput.toJson(),
    'land_size_acres':   landSizeAcres,
    'lat':               lat,
    'lon':               lon,
  };
}


// ════════════════════════════════════════════════════════════════════════════
//  RESPONSE MODELS (Backend → Flutter)
// ════════════════════════════════════════════════════════════════════════════

/// Mirrors `NutrientResult` in schemas.py.
///
/// One of these exists for each of N, P, K in the response.
/// Used by NutrientResultCard widget on the results screen.
class NutrientResult {
  final String nutrientName;       // "Nitrogen", "Phosphorus", "Potassium"
  final String nutrientSymbol;     // "N", "P₂O₅", "K₂O"
  final String fertilizerName;     // "Urea", "SSP", "MOP"
  final double requiredKgHa;       // FN / FP / FK — raw nutrient needed kg/ha
  final double productKgHa;        // Commercial product kg/ha
  final double productKgTotal;     // productKgHa × farmer's hectares
  final String fertilityClassUsed; // "low" | "medium" | "high"
  final String equationUsed;       // e.g. "FN = 118.2 kg/ha [SN=150, T=40, Class=low]"
  final String why;                // Plain-language explanation for the farmer
  final String schedule;           // Application timing string
  final String colorHex;           // "#69F0AE" — backend drives the UI color
  final String iconName;           // "leaf" | "seed" | "grain"

  const NutrientResult({
    required this.nutrientName,
    required this.nutrientSymbol,
    required this.fertilizerName,
    required this.requiredKgHa,
    required this.productKgHa,
    required this.productKgTotal,
    required this.fertilityClassUsed,
    required this.equationUsed,
    required this.why,
    required this.schedule,
    required this.colorHex,
    required this.iconName,
  });

  factory NutrientResult.fromJson(Map<String, dynamic> j) => NutrientResult(
    nutrientName:       j['nutrient_name']        as String,
    nutrientSymbol:     j['nutrient_symbol']       as String,
    fertilizerName:     j['fertilizer_name']       as String,
    requiredKgHa:       (j['required_kg_ha']       as num).toDouble(),
    productKgHa:        (j['product_kg_ha']        as num).toDouble(),
    productKgTotal:     (j['product_kg_total']     as num).toDouble(),
    fertilityClassUsed: j['fertility_class_used']  as String,
    equationUsed:       j['equation_used']         as String,
    why:                j['why']                   as String,
    schedule:           j['schedule']              as String,
    colorHex:           j['color_hex']             as String,
    iconName:           j['icon_name']             as String,
  );

  /// Convert the hex string from the backend into a Flutter Color.
  /// Backend sends e.g. "#69F0AE" → we need Color(0xFF69F0AE).
  Color get color {
    final hex = colorHex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  /// Returns the appropriate icon for the nutrient based on icon_name.
  IconData get icon {
    switch (iconName) {
      case 'seed':  return Icons.spa_outlined;
      case 'grain': return Icons.grass_outlined;
      default:      return Icons.eco_outlined;   // leaf (Nitrogen/Urea)
    }
  }

  /// Returns the fertility class display string with emoji, e.g. "🔴 LOW".
  String get fertilityLabel => fertilityClassLabel(fertilityClassUsed);

  /// Returns the display color for the fertility class badge.
  Color get fertilityColor => fertilityClassColor(fertilityClassUsed);
}


/// Mirrors `ApplicationScheduleItem` in schemas.py.
///
/// One item per timing event (day 0, 30, 60). Displayed as a vertical timeline
/// on the results screen.
class ScheduleItem {
  final String timing;          // "At Sowing (Basal)"
  final String description;     // Full instruction text
  final int daysAfterSowing;    // 0, 30, or 60 — used for timeline ordering

  const ScheduleItem({
    required this.timing,
    required this.description,
    required this.daysAfterSowing,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> j) => ScheduleItem(
    timing:          j['timing']             as String,
    description:     j['description']        as String,
    daysAfterSowing: j['days_after_sowing']  as int,
  );
}


/// Mirrors `OrganicSource` in schemas.py.
class OrganicSource {
  final double tHa;
  final String limitingNutrient;

  const OrganicSource({
    required this.tHa,
    required this.limitingNutrient,
  });

  factory OrganicSource.fromJson(Map<String, dynamic> j) => OrganicSource(
    tHa: (j['t_ha'] as num).toDouble(),
    limitingNutrient: j['limiting_nutrient'] as String,
  );
}

/// Mirrors `OrganicAlternatives` in schemas.py.
///
/// Always included in the response. The farmer can choose to go organic.
class OrganicAlternatives {
  final OrganicSource fym;
  final OrganicSource vermicompost;
  final OrganicSource psnc;

  const OrganicAlternatives({
    required this.fym,
    required this.vermicompost,
    required this.psnc,
  });

  factory OrganicAlternatives.fromJson(Map<String, dynamic> j) {
    // Check if we are receiving the OLD backend format
    if (j.containsKey('fym_t_ha')) {
      return OrganicAlternatives(
        fym: OrganicSource(
          tHa: (j['fym_t_ha'] as num).toDouble(),
          limitingNutrient: 'Nitrogen (N)',
        ),
        vermicompost: OrganicSource(
          tHa: (j['vermicompost_t_ha'] as num).toDouble(),
          limitingNutrient: 'Nitrogen (N)',
        ),
        psnc: OrganicSource(
          tHa: (j['psnc_t_ha'] as num).toDouble(),
          limitingNutrient: 'Nitrogen (N)',
        ),
      );
    }
    
    // New format
    return OrganicAlternatives(
      fym:          OrganicSource.fromJson(j['fym'] as Map<String, dynamic>),
      vermicompost: OrganicSource.fromJson(j['vermicompost'] as Map<String, dynamic>),
      psnc:         OrganicSource.fromJson(j['psnc'] as Map<String, dynamic>),
    );
  }
}


/// Mirrors `WeatherSummary` in schemas.py.
///
/// May be null if the NASA POWER API was unreachable.
class WeatherSummary {
  final double? avgMonthlyRainfallMm;
  final double? avgMaxTempC;
  final double? avgMinTempC;
  final String  advice;   // Plain-language timing advice

  const WeatherSummary({
    this.avgMonthlyRainfallMm,
    this.avgMaxTempC,
    this.avgMinTempC,
    required this.advice,
  });

  factory WeatherSummary.fromJson(Map<String, dynamic> j) => WeatherSummary(
    avgMonthlyRainfallMm: j['avg_monthly_rainfall_mm'] == null
        ? null
        : (j['avg_monthly_rainfall_mm'] as num).toDouble(),
    avgMaxTempC: j['avg_max_temp_c'] == null
        ? null
        : (j['avg_max_temp_c'] as num).toDouble(),
    avgMinTempC: j['avg_min_temp_c'] == null
        ? null
        : (j['avg_min_temp_c'] as num).toDouble(),
    advice: j['advice'] as String? ?? '',
  );
}


/// Mirrors `RecommendResponse` in schemas.py.
///
/// The complete response from POST /recommend/.
/// Passed as a route argument from input_wizard_screen to results_screen:
///   Navigator.pushNamed(context, '/results', arguments: response)
class RecommendResponse {
  final String cropDisplay;
  final double targetYield;
  final double landSizeAcres;
  final NutrientResult nitrogen;
  final NutrientResult phosphorus;
  final NutrientResult potassium;
  final List<ScheduleItem> applicationSchedule;
  final OrganicAlternatives organicAlternatives;  // Always present
  final WeatherSummary?     weatherSummary;        // null if API was unreachable
  final String recommendationId;
  final String generatedAt;

  final String? explainableSummary; // AI-driven explainable summary (optional)

  const RecommendResponse({
    required this.cropDisplay,
    required this.targetYield,
    required this.landSizeAcres,
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.applicationSchedule,
    required this.organicAlternatives,
    this.weatherSummary,
    this.explainableSummary,
    required this.recommendationId,
    required this.generatedAt,
  });

  factory RecommendResponse.fromJson(Map<String, dynamic> j) => RecommendResponse(
    cropDisplay:   j['crop_display']    as String,
    targetYield:   (j['target_yield']   as num).toDouble(),
    landSizeAcres: (j['land_size_acres'] as num).toDouble(),
    nitrogen:      NutrientResult.fromJson(j['nitrogen']   as Map<String, dynamic>),
    phosphorus:    NutrientResult.fromJson(j['phosphorus'] as Map<String, dynamic>),
    potassium:     NutrientResult.fromJson(j['potassium']  as Map<String, dynamic>),
    applicationSchedule: (j['application_schedule'] as List<dynamic>)
        .map((item) => ScheduleItem.fromJson(item as Map<String, dynamic>))
        .toList(),
    organicAlternatives: OrganicAlternatives.fromJson(
        j['organic_alternatives'] as Map<String, dynamic>),
    weatherSummary: j['weather_summary'] == null
        ? null
        : WeatherSummary.fromJson(j['weather_summary'] as Map<String, dynamic>),
    recommendationId: j['recommendation_id'] as String,
    generatedAt:      j['generated_at']      as String,
    explainableSummary: j['explainable_summary'] as String?,
  );

  /// Convenience: all three nutrient results as an ordered list.
  List<NutrientResult> get nutrients => [nitrogen, phosphorus, potassium];
}


// ════════════════════════════════════════════════════════════════════════════
//  WIZARD UI STATE HELPER  (NOT sent to backend directly)
// ════════════════════════════════════════════════════════════════════════════

/// Mutable state for one nutrient's input tile on the wizard's soil page.
///
/// Each of N, P, K has its own independent SoilInputState instance.
/// When the farmer finishes page 2, call .toSoilInput() on each to build
/// the RecommendRequest.
class SoilInputState {
  /// "class" = farmer picked Low/Medium/High chip
  /// "value" = farmer typed a soil-test number
  String mode = 'class';

  /// The fertility class chip selected. Default: "medium" (safest assumption).
  String fertilityClass = 'medium';

  /// The raw soil-test number the farmer typed (only valid when mode == "value").
  double? rawValue;

  /// Whether this nutrient's input is fully valid and ready to submit.
  bool get isValid {
    if (mode == 'class') return true; // fertilityClass always has a default
    return rawValue != null && rawValue! > 0;
  }

  /// Converts UI state → the immutable SoilInput object for the API request.
  SoilInput toSoilInput() {
    if (mode == 'class') {
      return SoilInput.fromClass(fertilityClass);
    } else {
      return SoilInput.fromValue(rawValue!);
    }
  }

  /// Detect and return the fertility class label for the UI "Detected: X" display.
  /// Only meaningful when mode == "value" and rawValue is set.
  /// Thresholds mirror FPEEngine._resolve_class_from_value() in fpe_engine.py.
  String detectClass(String crop, String nutrient) {
    if (rawValue == null) return '—';
    final v = rawValue!;
    if (crop == 'maize') {
      switch (nutrient) {
        case 'N': return v < 225 ? 'low' : (v > 500 ? 'high' : 'medium');
        case 'P': return v < 22  ? 'low' : (v > 55  ? 'high' : 'medium');
        case 'K': return v < 137 ? 'low' : (v > 337 ? 'high' : 'medium');
      }
    } else {
      switch (nutrient) {
        case 'N': return v < 225 ? 'low' : (v > 450 ? 'high' : 'medium');
        case 'P': return v < 22.5 ? 'low' : (v > 55 ? 'high' : 'medium');
        case 'K': return v < 137 ? 'low' : (v > 337 ? 'high' : 'medium');
      }
    }
    return 'medium';
  }
}


// ════════════════════════════════════════════════════════════════════════════
//  CROPPING HISTORY  (stored locally in SharedPreferences)
// ════════════════════════════════════════════════════════════════════════════

/// One entry in the farmer's cropping history log.
/// Serialised as a JSON object inside a JSON array string.
class CropHistoryEntry {
  final String season; // "Kharif 2025", "Rabi 2025-26"
  final String crop;   // "Maize", "Kholar"
  final double yield;  // actual yield achieved in q/ha
  final String notes;  // optional free text

  const CropHistoryEntry({
    required this.season,
    required this.crop,
    required this.yield,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
    'season': season,
    'crop':   crop,
    'yield':  yield,
    'notes':  notes,
  };

  factory CropHistoryEntry.fromJson(Map<String, dynamic> j) => CropHistoryEntry(
    season: j['season'] as String,
    crop:   j['crop']   as String,
    yield:  (j['yield'] as num).toDouble(),
    notes:  j['notes']  as String? ?? '',
  );
}
