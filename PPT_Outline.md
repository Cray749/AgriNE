# AgriSutra NE - Project Presentation Outline

## Slide 1: Title Slide
- **Project Name:** AgriSutra NE (Agricultural Formula – North East)
- **Tagline:** Smart Farming for Northeast India
- **Mission:** Hyper-personalized, AI-powered fertilizer recommendations for the agro-climatic realities of Northeast India.
- **One-line Pitch:** *"AgriSutra NE tells every North-East farmer exactly what to put in their soil, why, and how much — in their own language."*

## Slide 2: The Problem & Target Audience
- **Target Audience:** Smallholder farmers (0.5–5 acres) with limited literacy in Northeast India (e.g., Kiphire, Assam, Nagaland), Progressive Farmers, and Agricultural Officers.
- **The Challenge:** Lack of accessible, scientifically-backed, and hyper-localized soil management guidance.
- **Current Limitation:** Complex soil test reports and generic fertilizer recommendations don't translate well to actionable field advice for local crops like Maize and Kholar.

## Slide 3: The Solution - Core Capabilities
1. **Robust FPE Engine:** Calculates exact Nitrogen (N), Phosphorus (P₂O₅), and Potassium (K₂O) needs based on STCR (Soil Test Crop Response) methodology and target yield.
2. **Smart Fallbacks:** Dynamically maps simple "Low/Medium/High" soil fertility classes to default values if a farmer lacks a formal soil test.
3. **Actionable Outputs:** Converts scientific nutrient values directly to commercial products (Urea, SSP, MOP) in exact kg/ha or total kg for the farmer's plot.
4. **Trust & Explainability:** Generates plain-language, AI-driven explanations (using LLMs) on *why* specific fertilizers are suggested.

## Slide 4: Frontend Architecture (Mobile-First)
- **Technology Stack:** Flutter (Dart) compiled to native Android APK.
- **Design Philosophy:** Mobile-first, optimized for cheap smartphones. High contrast (dark backgrounds, bright greens), large text, and minimal typing.
- **Key Screens:**
  - **Landing/Login:** Trust-building hero section and simple phone number + OTP login.
  - **Profile Setup:** Captures Name, District, and Land Size (slider).
  - **Input Wizard:** 3-step PageView for Crop Selection, Soil Nutrient Input (N/P/K independently), and Review.
  - **Results Dashboard:** Clear cards showing Urea/SSP/MOP amounts, an application schedule timeline, and expandable "Why?" sections.

## Slide 5: Backend Architecture & Data Flow
- **Technology Stack:** Python 3.10+, FastAPI, PostgreSQL, Firebase Auth (Phase 2).
- **Core Components:**
  - **`fpe_engine.py`:** The mathematical core implementing STCR equations.
  - **`output_enricher.py`:** Handles organic pathways (e.g., FYM credits) and clamps negative values.
  - **`input_enricher.py`:** Integrates NASA POWER API for real-time weather context (rainfall/temp).
  - **`routers/recommend.py`:** The main API endpoint (`POST /recommend`) coordinating inputs and generating the full `RecommendResponse`.
- **Data Flow:** Flutter (JSON) ➔ FastAPI ➔ FPE Engine ➔ Enrichment ➔ Flutter (UI).

## Slide 6: The Science (STCR Methodology)
- **What is STCR?** Soil Test Crop Response. A proven methodology to optimize yield while minimizing fertilizer waste.
- **Example Equation (Maize, Low Fertility):**
  - Fertilizer N = `3.93 * Target Yield - 0.26 * Soil Nitrogen`
- **Product Conversion:**
  - Urea (kg) = Fertilizer N / 0.46
  - SSP (kg) = Fertilizer P / 0.16
  - MOP (kg) = Fertilizer K / 0.60
- **Application Schedule:** Urea is split (50/25/25) across sowing and top dressing. SSP and MOP are 100% basal (at sowing).

## Slide 7: Recent Enhancements & Next Steps (Phase 1 & 2)
- **Completed (Phase 1):**
  - Full Flutter UI integration with state management and context-aware theming.
  - Integration of backend STCR math logic with the mobile frontend.
  - Extensible data models (`schemas.py` and `models.dart`).
- **Current/Next Steps (Phase 2):**
  - **Geolocation:** Integrating GPS-based location input to fetch NASA weather data.
  - **AI Explainability:** Implementing a Groq LLaMA-3.3-70B pipeline for dynamic, easy-to-understand summaries.
  - **Offline Support & PDF Export:** Delivering recommendations offline and enabling shareable PDF reports.
