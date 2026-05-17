"""
AgriSutra NE — /recommend Router
==================================
POST /recommend/

This is the heart of the backend. Steps:
  1.  Receive RecommendRequest from Flutter (crop, yield, soil inputs for N/P/K)
  2.  Resolve each nutrient independently via FPEEngine (NEVER mix N/P/K inputs)
  3.  Enrich results with human-readable details from nutrient_utils
  4.  Compute total product for the farmer's actual land size
  5.  Build the application schedule (Urea: 50/25/25 split; SSP & MOP: 100% basal)
  6.  Return a fully-typed RecommendResponse that Flutter can render directly

Critical rules (from manual Part 11):
  - DO NOT modify fpe_engine.py or nutrient_utils.py
  - Resolve nitrogen → phosphorus → potassium INDEPENDENTLY
  - Always display detected fertility_class even when raw value was supplied
"""

from fastapi import APIRouter, HTTPException
from ..models.schemas import (
    RecommendRequest,
    RecommendResponse,
    NutrientResult,
    ApplicationScheduleItem,
    OrganicAlternatives,
    OrganicSource,
    WeatherSummary,
)
from ..fpe_engine import FPEEngine
from ..nutrient_utils import (
    get_nitrogen_details,
    get_phosphorus_details,
    get_potassium_details,
)
from ..output_enricher import enrich_output
from ..input_enricher import get_weather_context
import uuid
from datetime import datetime, timezone

router = APIRouter(prefix="/recommend", tags=["Recommendation"])

# 1 acre = 0.404686 hectares (exact conversion used throughout)
ACRES_TO_HA: float = 0.404686

# Maps internal crop key → display string shown to the farmer
CROP_DISPLAY_MAP: dict[str, str] = {
    "maize": "Maize",
    "kholar": "Kholar (Legume)",
}


def _resolve_soil_kwargs(soil_input, nutrient_key: str) -> dict:
    """
    Convert a SoilInput into the keyword-argument dict that FPEEngine expects.

    FPEEngine accepts EITHER:
      - fertility_class="low"|"medium"|"high"   (when farmer picked a class)
      - SN / SP / SK = <float>                  (when farmer entered a raw value)

    The `nutrient_key` must be "N", "P", or "K" — matching FPEEngine's parameter
    names (SN, SP, SK).
    """
    if soil_input.mode == "class":
        return {"fertility_class": soil_input.fertility_class}
    else:
        # raw_value presence is already validated by Pydantic (SoilInput validator)
        return {f"S{nutrient_key}": soil_input.raw_value}


def _get_fertility_class(soil_input, crop: str, nutrient_key: str) -> str:
    """
    Return the final fertility class string for display in the Flutter UI.

    When mode="class", we already have it from the request.
    When mode="value", we ask FPEEngine to resolve it from the raw value.
    This ensures Flutter always shows "Detected: MEDIUM" even for raw-value inputs,
    which builds farmer trust (Part 11, DO-NOT #6).
    """
    if soil_input.mode == "class":
        return soil_input.fertility_class
    return FPEEngine._resolve_class_from_value(
        crop, soil_input.raw_value, nutrient_key
    )


@router.post("/", response_model=RecommendResponse, summary="Get fertilizer recommendation")
def get_recommendation(req: RecommendRequest) -> RecommendResponse:
    """
    Main endpoint called by Flutter's input_wizard_screen.

    Returns a complete fertilizer prescription including:
    - Per-nutrient requirements (N, P, K) in kg/ha
    - Commercial product amounts (Urea, SSP, MOP) per ha AND for farmer's plot
    - Application schedule (Urea split 50/25/25; SSP & MOP fully basal)
    - Plain-language explanations for each nutrient
    - The equation used (for transparency / debugging)
    """
    crop = req.crop
    T = req.target_yield
    land_ha = req.land_size_acres * ACRES_TO_HA

    # ── STEP 1: Resolve soil kwargs for each nutrient independently ─────────────
    n_kwargs = _resolve_soil_kwargs(req.nitrogen_input, "N")
    p_kwargs = _resolve_soil_kwargs(req.phosphorus_input, "P")
    k_kwargs = _resolve_soil_kwargs(req.potassium_input, "K")

    # ── STEP 2: Call FPEEngine — each nutrient is INDEPENDENT ──────────────────
    try:
        n_res = FPEEngine.compute_N(crop, T, **n_kwargs)
    except ValueError as exc:
        raise HTTPException(
            status_code=422,
            detail=f"Nitrogen computation failed: {exc}",
        )

    try:
        p_res = FPEEngine.compute_P(crop, T, **p_kwargs)
    except ValueError as exc:
        raise HTTPException(
            status_code=422,
            detail=f"Phosphorus computation failed: {exc}",
        )

    try:
        k_res = FPEEngine.compute_K(crop, T, **k_kwargs)
    except ValueError as exc:
        raise HTTPException(
            status_code=422,
            detail=f"Potassium computation failed: {exc}",
        )

    # ── STEP 3: Clamp negative FPE values to 0 (CRITICAL — prevents UI crash) ──
    # output_enricher.enrich_output clamps all negative kg values to 0.0.
    # Negative values can occur on very high-fertility soils — scientifically
    # valid (no fertilizer needed) but would crash the Flutter card layout.
    fn_clamped, fp_clamped, fk_clamped, _ = enrich_output(
        n_res["FN"], p_res["FP"], k_res["FK"]
    )
    n_res["FN"]        = fn_clamped
    n_res["urea_kg_ha"] = round(fn_clamped / 0.46, 2)
    p_res["FP"]        = fp_clamped
    p_res["ssp_kg_ha"]  = round(fp_clamped / 0.16, 2)
    k_res["FK"]        = fk_clamped
    k_res["mop_kg_ha"]  = round(fk_clamped / 0.60, 2)

    # ── STEP 4: Enrich with human-readable details (nutrient_utils) ────────────
    # These functions return why / schedule / improvement / conversion strings.
    n_details = get_nitrogen_details(n_res["FN"], n_res["urea_kg_ha"])
    p_details = get_phosphorus_details(p_res["FP"], p_res["ssp_kg_ha"])
    k_details = get_potassium_details(k_res["FK"], k_res["mop_kg_ha"])

    # ── STEP 5: Resolve final fertility class for UI display ────────────────────
    n_fc = _get_fertility_class(req.nitrogen_input, crop, "N")
    p_fc = _get_fertility_class(req.phosphorus_input, crop, "P")
    k_fc = _get_fertility_class(req.potassium_input, crop, "K")

    # ── STEP 6: Extract commercial product amounts ──────────────────────────────
    urea = n_res["urea_kg_ha"]   # Urea kg/ha (clamped ≥ 0)
    ssp  = p_res["ssp_kg_ha"]    # SSP  kg/ha (clamped ≥ 0)
    mop  = k_res["mop_kg_ha"]    # MOP  kg/ha (clamped ≥ 0)

    # ── STEP 7: Build application schedule ─────────────────────────────────────
    # Rule:  Urea → 50% basal + 25% at 30 DAS + 25% at 60 DAS
    #        SSP  → 100% basal (phosphorus is immobile, always basal)
    #        MOP  → 100% basal
    urea_basal    = round(urea * 0.50, 1)
    urea_30_das   = round(urea * 0.25, 1)
    urea_60_das   = round(urea * 0.25, 1)

    if crop.lower() == "maize":
        application_schedule = [
            ApplicationScheduleItem(
                timing="0 day- 50 percent nitrogen as basal (During final land preparation)",
                description=(
                    f"Apply all SSP ({ssp} kg/ha)  +  All MOP ({mop} kg/ha)"
                    f"  +  {urea_basal} kg/ha Urea"
                ),
                days_after_sowing=0,
            ),
            ApplicationScheduleItem(
                timing="30 day- 25 percent at knee high stage after sowing",
                description=f"{urea_30_das} kg/ha Urea (First top-dressing)",
                days_after_sowing=30,
            ),
            ApplicationScheduleItem(
                timing="60 day- Next 25 percent after sowing",
                description=f"{urea_60_das} kg/ha Urea (Second top-dressing)",
                days_after_sowing=60,
            ),
        ]
    else:
        application_schedule = [
            ApplicationScheduleItem(
                timing="50% nitrogen as basal (During final land preparation)",
                description=(
                    f"Apply all SSP ({ssp} kg/ha)  +  All MOP ({mop} kg/ha)"
                    f"  +  {urea_basal} kg/ha Urea"
                ),
                days_after_sowing=0,
            ),
            ApplicationScheduleItem(
                timing="25% at knee high stage 30 Days after sowing",
                description=f"{urea_30_das} kg/ha Urea (First top-dressing)",
                days_after_sowing=30,
            ),
            ApplicationScheduleItem(
                timing="Next 25% at 60 Days after sowing",
                description=f"{urea_60_das} kg/ha Urea (Second top-dressing)",
                days_after_sowing=60,
            ),
        ]

    # ── STEP 8: Organic alternatives for all nutrients (always computed) ───────
    fn = fn_clamped
    fp = fp_clamped
    fk = fk_clamped

    # FYM calculations
    fym_n = fn / 5.0
    fym_p = fp / 4.6
    fym_k = fk / 6.0
    fym_max = max(fym_n, fym_p, fym_k)
    fym_lim = "Nitrogen (N)" if fym_max == fym_n else ("Phosphorus (P₂O₅)" if fym_max == fym_p else "Potassium (K₂O)")

    # Vermicompost calculations
    vc_n = fn / 15.0
    vc_p = fp / 26.1
    vc_k = fk / 14.6
    vc_max = max(vc_n, vc_p, vc_k)
    vc_lim = "Nitrogen (N)" if vc_max == vc_n else ("Phosphorus (P₂O₅)" if vc_max == vc_p else "Potassium (K₂O)")

    # PSNC calculations
    psnc_n = fn / 29.0
    psnc_p = fp / 10.9
    psnc_k = fk / 22.6
    psnc_max = max(psnc_n, psnc_p, psnc_k)
    psnc_lim = "Nitrogen (N)" if psnc_max == psnc_n else ("Phosphorus (P₂O₅)" if psnc_max == psnc_p else "Potassium (K₂O)")

    organic = OrganicAlternatives(
        fym=OrganicSource(t_ha=round(fym_max, 2), limiting_nutrient=fym_lim),
        vermicompost=OrganicSource(t_ha=round(vc_max, 2), limiting_nutrient=vc_lim),
        psnc=OrganicSource(t_ha=round(psnc_max, 2), limiting_nutrient=psnc_lim),
    )

    # ── STEP 9: NASA POWER weather context (best-effort, never blocks the response) ──
    weather: WeatherSummary | None = None
    try:
        wx = get_weather_context(req.lat or 25.9, req.lon or 94.3)
        if wx:
            rain = wx.get('avg_monthly_rainfall_mm', 0) or 0
            tmax = wx.get('avg_max_temp_c')
            tmin = wx.get('avg_min_temp_c')

            # Plain-language advice based on rainfall
            if rain > 80:
                advice = (
                    f"Monthly rainfall is {rain} mm — good moisture. "
                    "Apply basal dose just before sowing. "
                    "Top-dress Urea when soil is moist but not waterlogged."
                )
            elif rain > 30:
                advice = (
                    f"Monthly rainfall is {rain} mm — moderate. "
                    "Irrigate before top-dressing if no rain in 5 days."
                )
            else:
                advice = (
                    f"Monthly rainfall is {rain} mm — dry conditions. "
                    "Ensure irrigation before fertilizer application "
                    "to prevent nutrient burn."
                )
            weather = WeatherSummary(
                avg_monthly_rainfall_mm=rain,
                avg_max_temp_c=tmax,
                avg_min_temp_c=tmin,
                advice=advice,
            )
    except Exception:
        weather = None   # Silently skip — never block the prescription

    # ── STEP 10: Assemble and return the full response ─────────────────────────────
    return RecommendResponse(
        crop_display=CROP_DISPLAY_MAP.get(crop, crop.capitalize()),
        target_yield=T,
        land_size_acres=req.land_size_acres,

        nitrogen=NutrientResult(
            nutrient_name="Nitrogen",
            nutrient_symbol="N",
            fertilizer_name="Urea",
            required_kg_ha=n_res["FN"],
            product_kg_ha=urea,
            product_kg_total=round(urea * land_ha, 1),
            fertility_class_used=n_fc,
            equation_used=n_res["equation"],
            why=n_details["why"],
            schedule=n_details["schedule"],
            color_hex="#69F0AE",
            icon_name="leaf",
        ),

        phosphorus=NutrientResult(
            nutrient_name="Phosphorus",
            nutrient_symbol="P₂O₅",
            fertilizer_name="SSP",
            required_kg_ha=p_res["FP"],
            product_kg_ha=ssp,
            product_kg_total=round(ssp * land_ha, 1),
            fertility_class_used=p_fc,
            equation_used=p_res["equation"],
            why=p_details["why"],
            schedule=p_details["schedule"],
            color_hex="#81D4FA",
            icon_name="seed",
        ),

        potassium=NutrientResult(
            nutrient_name="Potassium",
            nutrient_symbol="K₂O",
            fertilizer_name="MOP",
            required_kg_ha=k_res["FK"],
            product_kg_ha=mop,
            product_kg_total=round(mop * land_ha, 1),
            fertility_class_used=k_fc,
            equation_used=k_res["equation"],
            why=k_details["why"],
            schedule=k_details["schedule"],
            color_hex="#FFCC80",
            icon_name="grain",
        ),

        application_schedule=application_schedule,
        organic_alternatives=organic,
        weather_summary=weather,
        recommendation_id=str(uuid.uuid4()),
        generated_at=datetime.now(timezone.utc).isoformat(),
    )
