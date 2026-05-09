"""
AgriSutra NE — Pydantic Schemas
================================
Defines the data contract between the Flutter app and the FastAPI backend.
The Flutter `core/models.dart` file must mirror every field name and type here.

Key Design Principle:
    Each of N, P, K is INDEPENDENT. SoilInput is used once per nutrient.
    Never mix fertility inputs across nutrients.
"""

from pydantic import BaseModel, model_validator
from typing import Optional, Literal


# ─── REQUEST MODELS ────────────────────────────────────────────────────────────

class SoilInput(BaseModel):
    """
    Per-nutrient soil input block.
    The farmer either picks a fertility class (easy mode) OR enters a raw value
    (advanced mode). Flutter sends one SoilInput for each of N, P, K.

    Validation rules:
      - mode="class"  → fertility_class must be set,  raw_value is ignored
      - mode="value"  → raw_value must be set (> 0),  fertility_class is optional
                        (FPEEngine resolves it internally from the raw value)
    """
    mode: Literal["class", "value"]
    fertility_class: Optional[Literal["low", "medium", "high"]] = None
    raw_value: Optional[float] = None  # kg/ha, only relevant when mode="value"

    @model_validator(mode="after")
    def check_fields_match_mode(self) -> "SoilInput":
        if self.mode == "class" and self.fertility_class is None:
            raise ValueError(
                "fertility_class is required when mode is 'class'. "
                "Expected one of: 'low', 'medium', 'high'."
            )
        if self.mode == "value" and (self.raw_value is None or self.raw_value <= 0):
            raise ValueError(
                "raw_value must be a positive number when mode is 'value'. "
                "Enter the soil test value in kg/ha."
            )
        return self


class RecommendRequest(BaseModel):
    """
    Full request payload sent by Flutter's input_wizard_screen.dart
    when the farmer taps 'Get Recommendation'.

    Field notes:
      - crop:            Exactly "maize" or "kholar" (lowercase, matches FPEEngine).
      - target_yield:    Quintals per hectare (q/ha). Typical Maize range: 20–60.
      - *_input:         Independent soil data per nutrient. Never share across N/P/K.
      - land_size_acres: Used ONLY to compute product_kg_total for the farmer's plot.
                         The FPE equations are always per-hectare. Default = 1.0 acre.
    """
    crop: Literal["maize", "kholar"]
    target_yield: float                         # q/ha, e.g. 40.0
    nitrogen_input: SoilInput
    phosphorus_input: SoilInput
    potassium_input: SoilInput
    land_size_acres: Optional[float] = 1.0      # 1 acre ≈ 0.4047 ha
    # GPS coordinates — used to fetch NASA POWER weather context
    # Kiphire, Nagaland defaults if omitted
    lat: Optional[float] = 25.9
    lon: Optional[float] = 94.3

    @model_validator(mode="after")
    def check_target_yield(self) -> "RecommendRequest":
        if self.target_yield <= 0:
            raise ValueError("target_yield must be a positive number.")
        return self


# ─── RESPONSE MODELS ───────────────────────────────────────────────────────────

class NutrientResult(BaseModel):
    """
    Result for a single nutrient (N, P, or K).
    Flutter maps this to a NutrientCard widget.

    Color and icon fields drive the UI theming so the backend controls
    how each nutrient is displayed — the Flutter widget just reads them.
    """
    nutrient_name: str           # "Nitrogen", "Phosphorus", "Potassium"
    nutrient_symbol: str         # "N", "P₂O₅", "K₂O"
    fertilizer_name: str         # "Urea", "SSP", "MOP"
    required_kg_ha: float        # Raw nutrient needed (FN / FP / FK) in kg/ha
    product_kg_ha: float         # Actual commercial product kg/ha (urea / ssp / mop)
    product_kg_total: float      # product_kg_ha × farmer's land in ha
    fertility_class_used: str    # "low" | "medium" | "high"  (always resolved)
    equation_used: str           # Full equation string e.g. "FN = 118.2 kg/ha [SN=150, T=40, Class=low]"
    why: str                     # Plain-language explanation for the farmer
    schedule: str                # Application timing string from nutrient_utils
    color_hex: str               # Flutter UI color: "#69F0AE" / "#81D4FA" / "#FFCC80"
    icon_name: str               # "leaf" / "seed" / "grain"  (maps to Flutter icon)


class ApplicationScheduleItem(BaseModel):
    """
    One row in the application schedule table shown on the results screen.
    Urea is split 50 / 25 / 25. SSP and MOP are 100% basal.
    """
    timing: str             # "At Sowing (Basal)", "30 Days After Sowing", etc.
    description: str        # Human-readable description of what to apply
    days_after_sowing: int  # 0, 30, 60 — used by Flutter to sort / display timeline


class OrganicAlternatives(BaseModel):
    """
    Organic alternatives to meet the nitrogen requirement.
    Computed as: FYM = FN/5, Vermicompost = FN/15, PSNC = FN/29 (t/ha).
    These are ONLY for nitrogen — P and K always come from SSP/MOP.
    """
    fym_t_ha: float         # Farm Yard Manure in tonnes/ha
    vermicompost_t_ha: float
    psnc_t_ha: float        # Poultry Slurry Nutrient Compost
    nitrogen_offset_kg_ha: float   # How much FN is covered if organic is chosen


class WeatherSummary(BaseModel):
    """
    Weather context fetched from NASA POWER API via input_enricher.
    Shown on the results screen to help the farmer decide timing.
    None if the API call failed or timed out.
    """
    avg_monthly_rainfall_mm: Optional[float] = None
    avg_max_temp_c: Optional[float] = None
    avg_min_temp_c: Optional[float] = None
    advice: str = ""   # Short plain-language timing advice based on weather


class RecommendResponse(BaseModel):
    """
    Complete response returned to the Flutter results_screen.dart.

    The Flutter app should display:
      1. A header with crop_display, target_yield, land_size_acres
      2. Three NutrientResult cards (nitrogen, phosphorus, potassium)
      3. An ApplicationSchedule table
      4. Organic alternatives section (if farmer wants organic)
      5. Weather context banner
      6. A small footer with recommendation_id and generated_at
    """
    crop_display: str
    target_yield: float
    land_size_acres: float
    nitrogen: NutrientResult
    phosphorus: NutrientResult
    potassium: NutrientResult
    application_schedule: list[ApplicationScheduleItem]
    organic_alternatives: OrganicAlternatives      # Always computed — farmer decides
    weather_summary: Optional[WeatherSummary] = None
    recommendation_id: str
    generated_at: str
