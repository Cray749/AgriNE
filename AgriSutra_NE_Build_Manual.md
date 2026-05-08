# 🌾 AgriSutra NE — Complete Developer Build Manual
### Flutter + FastAPI | Mobile-First | APK-Ready
**Version:** 1.0 | **Author guidance for:** Full implementation from zero to APK

---

## 📖 HOW TO USE THIS MANUAL

This manual is written so that **you build in order, top to bottom**. Every section tells you:
- **What** to build
- **Why** it exists (so you understand, not just copy)
- **Exact file names and folder paths** (so nothing gets lost)
- **Exact data contracts between frontend and backend** (so integration is frictionless)

Do not skip sections. Every file listed in this manual links to another.

---

## 🏗️ PART 1: PROJECT ARCHITECTURE

### 1.1 Big Picture

```
agrisutra_ne/
├── backend/                   ← Python FastAPI server
│   ├── main.py                ← App entry point, router registration
│   ├── fpe_engine.py          ← Core math logic (DO NOT MODIFY EQUATIONS)
│   ├── nutrient_utils.py      ← Helper explanations (DO NOT MODIFY)
│   ├── routers/
│   │   ├── recommend.py       ← POST /recommend endpoint
│   │   └── auth.py            ← POST /auth/otp (Phase 2, stub for now)
│   ├── models/
│   │   └── schemas.py         ← Pydantic request/response models
│   └── requirements.txt
│
└── flutter_app/               ← Flutter mobile app
    ├── lib/
    │   ├── main.dart           ← Entry, theme, routing
    │   ├── core/
    │   │   ├── theme.dart      ← All colors, fonts, spacing constants
    │   │   ├── api_client.dart ← All HTTP calls to backend
    │   │   └── models.dart     ← Dart data classes (mirrors backend schemas)
    │   ├── screens/
    │   │   ├── splash_screen.dart
    │   │   ├── landing_screen.dart
    │   │   ├── login_screen.dart
    │   │   ├── profile_setup_screen.dart
    │   │   ├── input_wizard_screen.dart
    │   │   └── results_screen.dart
    │   └── widgets/
    │       ├── app_button.dart
    │       ├── nutrient_card.dart
    │       ├── fertilizer_result_card.dart
    │       └── step_indicator.dart
    └── pubspec.yaml
```

### 1.2 Data Flow

```
Farmer taps "Get Recommendation"
    ↓
Flutter input_wizard_screen.dart
    ↓  (HTTP POST JSON)
FastAPI /recommend endpoint (recommend.py)
    ↓  (calls)
fpe_engine.py  →  compute_N(), compute_P(), compute_K()
    ↓  (returns JSON)
Flutter results_screen.dart
    ↓
Farmer sees: Urea X kg, SSP Y kg, MOP Z kg + application schedule
```

### 1.3 Why Flutter (not React Native or web)

The user needs an APK. Flutter compiles to a native Android APK that works offline after installation. The FPE math is deterministic, so the app can show results even with poor connectivity by calling a locally-bundled calculator (Phase 2 option). For Phase 1, a simple HTTP call to a hosted FastAPI server is sufficient.

---

## 🎨 PART 2: DESIGN SYSTEM (Read this before writing a single widget)

The target user is a 40–45 year old farmer or government officer. They need:
- **Large text** (minimum 16sp body, 22sp headings)
- **High contrast** (dark backgrounds with bright greens)
- **Iconography** over text wherever possible
- **Minimal typing** — use sliders, chips, radio buttons
- **No decorative clutter** — every element must serve a purpose

### 2.1 Color Palette (define all in `core/theme.dart`)

```dart
// PRIMARY GREENS (trust, nature, agriculture)
const Color kGreenPrimary    = Color(0xFF2E7D32);  // Deep forest green — buttons, headers
const Color kGreenAccent     = Color(0xFF69F0AE);  // Bright mint — highlighted values, CTAs
const Color kGreenLight      = Color(0xFFE8F5E9);  // Very light green — card backgrounds

// BACKGROUNDS
const Color kBgDark          = Color(0xFF0F1117);  // Near-black — main background (dark mode)
const Color kBgCard          = Color(0xFF1A2420);  // Slightly lighter card surface
const Color kBgCardBorder    = Color(0xFF2D4A3E);  // Card border

// TEXT
const Color kTextPrimary     = Color(0xFFE0E0E0);  // Off-white — main body text
const Color kTextSecondary   = Color(0xFF90A4AE);  // Cool grey — labels, subtitles
const Color kTextHighlight   = Color(0xFFFFFFFF);  // Pure white — critical values

// NUTRIENT-SPECIFIC (maps exactly to N, P, K)
const Color kColorN          = Color(0xFF69F0AE);  // Mint green — Nitrogen/Urea
const Color kColorP          = Color(0xFF81D4FA);  // Sky blue — Phosphorus/SSP
const Color kColorK          = Color(0xFFFFCC80);  // Warm amber — Potassium/MOP

// STATUS
const Color kSuccess         = Color(0xFF4CAF50);
const Color kWarning         = Color(0xFFFF9800);
const Color kError           = Color(0xFFE53935);
```

### 2.2 Typography (define in `core/theme.dart`)

```dart
// Use Google Fonts package: 'Poppins' (approx. Inter, very readable on cheap screens)
const String kFontFamily = 'Poppins';

// Text Styles
kHeadingXL   = 28sp, FontWeight.w700, kTextHighlight   // Screen titles
kHeadingL    = 22sp, FontWeight.w700, kTextHighlight    // Section headings
kHeadingM    = 18sp, FontWeight.w600, kTextPrimary      // Card headings
kBodyL       = 16sp, FontWeight.w400, kTextPrimary      // Main body (min for farmers)
kBodyM       = 14sp, FontWeight.w400, kTextSecondary    // Secondary info
kLabel       = 12sp, FontWeight.w500, kTextSecondary    // Small labels/chips
kValueXL     = 36sp, FontWeight.w700, kGreenAccent      // Result numbers (big, unmissable)
kValueL      = 24sp, FontWeight.w700, kTextHighlight    // Card values
```

### 2.3 Spacing & Shape System

```dart
// Radii
const double kRadiusCard   = 16.0;
const double kRadiusButton = 12.0;
const double kRadiusChip   = 24.0;  // pill shape for selection chips

// Padding
const EdgeInsets kPaddingScreen = EdgeInsets.symmetric(horizontal: 20, vertical: 16);
const EdgeInsets kPaddingCard   = EdgeInsets.all(20);

// Card elevation / shadow
BoxShadow kShadowCard = BoxShadow(
  color: Colors.black.withOpacity(0.35),
  blurRadius: 12,
  offset: Offset(0, 4),
);
```

---

## ⚙️ PART 3: BACKEND — BUILD INSTRUCTIONS

### 3.1 Setup

Create folder `backend/`. Run:
```bash
python3 -m venv venv
source venv/bin/activate
pip install fastapi uvicorn pydantic python-dotenv
```

**`backend/requirements.txt`:**
```
fastapi==0.111.0
uvicorn[standard]==0.29.0
pydantic==2.7.1
python-dotenv==1.0.1
```

### 3.2 Copy Core Logic Files (DO NOT MODIFY)

Copy `fpe_engine.py` and `nutrient_utils.py` from the original codebase directly into the `backend/` folder. These files contain 20+ years of research — treat them as read-only libraries.

**What they contain (for your understanding only):**

`fpe_engine.py` — `class FPEEngine` with three static methods:
- `compute_N(crop, T, fertility_class=None, SN=None)` → `{"FN": float, "urea_kg_ha": float, "equation": str}`
- `compute_P(crop, T, fertility_class=None, SP=None)` → `{"FP": float, "ssp_kg_ha": float, "equation": str}`
- `compute_K(crop, T, fertility_class=None, SK=None)` → `{"FK": float, "mop_kg_ha": float, "equation": str}`

Each method accepts **either** a `fertility_class` ("low"/"medium"/"high") OR a raw float value. Never both. The engine resolves which class the raw value belongs to internally.

`nutrient_utils.py` — helper functions that return detailed explanation dicts with:
- `get_nitrogen_details(n_req, urea)`, `get_phosphorus_details(p_req, ssp)`, `get_potassium_details(k_req, mop)`
- Each returns: `why`, `schedule`, `improvement`, `conversion`, `fertilizer_amount`

### 3.3 `backend/models/schemas.py`

This file defines what data the Flutter app sends to the backend, and what the backend sends back. **The Flutter app's `models.dart` must mirror this exactly.**

```python
from pydantic import BaseModel
from typing import Optional, Literal

# ─── REQUEST ───────────────────────────────────────────────────────────────
class SoilInput(BaseModel):
    """
    Per-nutrient soil input. The farmer either picks a class OR enters a value.
    Flutter sends one of these for N, P, and K respectively.
    """
    mode: Literal["class", "value"]  # "class" = dropdown, "value" = number input
    fertility_class: Optional[Literal["low", "medium", "high"]] = None
    raw_value: Optional[float] = None  # kg/ha, only used when mode="value"

class RecommendRequest(BaseModel):
    """Sent by Flutter's input_wizard_screen when farmer taps 'Get Recommendation'."""
    crop: Literal["maize", "kholar"]         # maps directly to FPEEngine
    target_yield: float                       # q/ha, e.g. 40.0
    nitrogen_input: SoilInput
    phosphorus_input: SoilInput
    potassium_input: SoilInput
    land_size_acres: Optional[float] = 1.0   # used to scale total product needed

# ─── RESPONSE ──────────────────────────────────────────────────────────────
class NutrientResult(BaseModel):
    """Result for one nutrient (N, P, or K)."""
    nutrient_name: str           # "Nitrogen", "Phosphorus", "Potassium"
    nutrient_symbol: str         # "N", "P₂O₅", "K₂O"
    fertilizer_name: str         # "Urea", "SSP", "MOP"
    required_kg_ha: float        # raw nutrient kg/ha (FN, FP, FK)
    product_kg_ha: float         # converted product (urea, ssp, mop) kg/ha
    product_kg_total: float      # product_kg_ha × land_size_acres × 0.405
    fertility_class_used: str    # "low", "medium", or "high"
    equation_used: str           # e.g. "FN = 118.4 kg/ha [SN=280, T=40, Class=medium]"
    why: str                     # Explanation for the farmer
    schedule: str                # Application timing string
    color_hex: str               # For Flutter UI: "#69F0AE" etc.
    icon_name: str               # "leaf", "seed", "grain"

class ApplicationScheduleItem(BaseModel):
    timing: str                  # "At Sowing (Basal)"
    description: str             # "All SSP + All MOP + 59.0 kg Urea"
    days_after_sowing: int       # 0, 30, 60

class RecommendResponse(BaseModel):
    """Full response sent back to Flutter."""
    crop_display: str            # "Maize (Local)" for display
    target_yield: float
    land_size_acres: float
    nitrogen: NutrientResult
    phosphorus: NutrientResult
    potassium: NutrientResult
    application_schedule: list[ApplicationScheduleItem]
    recommendation_id: str       # UUID for logging (just generate with uuid4())
    generated_at: str            # ISO timestamp
```

### 3.4 `backend/routers/recommend.py`

This is the core API endpoint. It calls the FPE engine and packages the results.

```python
from fastapi import APIRouter, HTTPException
from ..models.schemas import RecommendRequest, RecommendResponse, NutrientResult, ApplicationScheduleItem
from ..fpe_engine import FPEEngine
from ..nutrient_utils import get_nitrogen_details, get_phosphorus_details, get_potassium_details
import uuid
from datetime import datetime

router = APIRouter(prefix="/recommend", tags=["Recommendation"])

ACRES_TO_HA = 0.404686  # 1 acre = 0.404686 hectares

@router.post("/", response_model=RecommendResponse)
def get_recommendation(req: RecommendRequest):
    crop = req.crop
    T    = req.target_yield
    land_ha = req.land_size_acres * ACRES_TO_HA

    def resolve(soil_input, nutrient_key):
        """Returns (fertility_class_kwarg, raw_val_kwarg) for FPEEngine"""
        if soil_input.mode == "class":
            return {"fertility_class": soil_input.fertility_class}
        else:
            if soil_input.raw_value is None:
                raise HTTPException(400, f"raw_value required when mode=value for {nutrient_key}")
            return {f"S{nutrient_key}": soil_input.raw_value}

    try:
        # ── NITROGEN (independent) ──────────────────────────────────────────
        n_kwargs = resolve(req.nitrogen_input, "N")
        n_res    = FPEEngine.compute_N(crop, T, **n_kwargs)
        n_details = get_nitrogen_details(n_res["FN"], n_res["urea_kg_ha"])
        n_fc = n_kwargs.get("fertility_class") or FPEEngine._resolve_class_from_value(crop, req.nitrogen_input.raw_value, "N")

        # ── PHOSPHORUS (independent) ────────────────────────────────────────
        p_kwargs = resolve(req.phosphorus_input, "P")
        p_res    = FPEEngine.compute_P(crop, T, **p_kwargs)
        p_details = get_phosphorus_details(p_res["FP"], p_res["ssp_kg_ha"])
        p_fc = p_kwargs.get("fertility_class") or FPEEngine._resolve_class_from_value(crop, req.phosphorus_input.raw_value, "P")

        # ── POTASSIUM (independent) ─────────────────────────────────────────
        k_kwargs = resolve(req.potassium_input, "K")
        k_res    = FPEEngine.compute_K(crop, T, **k_kwargs)
        k_details = get_potassium_details(k_res["FK"], k_res["mop_kg_ha"])
        k_fc = k_kwargs.get("fertility_class") or FPEEngine._resolve_class_from_value(crop, req.potassium_input.raw_value, "K")

    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))

    urea = n_res["urea_kg_ha"]
    ssp  = p_res["ssp_kg_ha"]
    mop  = k_res["mop_kg_ha"]

    # ── Build schedule ──────────────────────────────────────────────────────
    # Rule: Urea is split 50/25/25. SSP and MOP are 100% basal.
    schedule = [
        ApplicationScheduleItem(
            timing="At Sowing (Basal)",
            description=f"All SSP ({ssp} kg/ha)  +  All MOP ({mop} kg/ha)  +  {round(urea*0.5,1)} kg/ha Urea",
            days_after_sowing=0
        ),
        ApplicationScheduleItem(
            timing="30 Days After Sowing",
            description=f"{round(urea*0.25,1)} kg/ha Urea (Top dressing)",
            days_after_sowing=30
        ),
        ApplicationScheduleItem(
            timing="60 Days After Sowing",
            description=f"{round(urea*0.25,1)} kg/ha Urea (Top dressing)",
            days_after_sowing=60
        ),
    ]

    crop_display_map = {
        "maize": "Maize",
        "kholar": "Kholar (Legume)"
    }

    return RecommendResponse(
        crop_display=crop_display_map.get(crop, crop.capitalize()),
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
            icon_name="leaf"
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
            icon_name="seed"
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
            icon_name="grain"
        ),
        application_schedule=schedule,
        recommendation_id=str(uuid.uuid4()),
        generated_at=datetime.utcnow().isoformat()
    )
```

### 3.5 `backend/main.py`

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routers import recommend

app = FastAPI(
    title="AgriSutra NE API",
    description="STCR-based fertilizer recommendation engine for Northeast India",
    version="1.0.0"
)

# CORS — allow Flutter app (and any origin during development)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(recommend.router)

@app.get("/health")
def health():
    return {"status": "ok", "service": "AgriSutra NE API"}
```

Run with: `uvicorn backend.main:app --reload --port 8000`

Test with: `GET http://localhost:8000/health`

### 3.6 Deploying the Backend (for APK demo)

For the boss demo, deploy on **Railway.app** (free tier, no credit card):
1. Push `backend/` folder to a GitHub repo
2. Connect Railway → Deploy → it auto-detects FastAPI
3. Set start command: `uvicorn main:app --host 0.0.0.0 --port $PORT`
4. Note the URL: `https://agrisutra-ne.up.railway.app`
5. Paste this URL into Flutter's `api_client.dart` as `kBaseUrl`

---

## 📱 PART 4: FLUTTER APP — BUILD INSTRUCTIONS

### 4.1 Create the Flutter Project

```bash
flutter create --org com.agrisutra --project-name agrisutra_ne flutter_app
cd flutter_app
```

### 4.2 `pubspec.yaml` Dependencies

```yaml
name: agrisutra_ne
description: AI-powered fertilizer recommendations for Northeast India

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # HTTP
  http: ^1.2.1
  
  # State management (simple, no over-engineering)
  provider: ^6.1.2
  
  # UI
  google_fonts: ^6.2.1
  flutter_animate: ^4.5.0    # smooth screen transitions
  lottie: ^3.1.0             # animated illustrations (loading, success)
  
  # Utils
  shared_preferences: ^2.2.3  # store farmer profile locally
  intl: ^0.19.0
  url_launcher: ^6.2.6

dev_dependencies:
  flutter_test:
    sdk: flutter

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/animations/
```

### 4.3 Assets to Create/Download

Create folder: `flutter_app/assets/images/`

You need these image files. Use free SVG/PNG from **unDraw.co** (search terms given):
- `hero_farmer.png` — search "farmer" on undraw.co, download green-themed
- `logo.png` — AgriSutra NE logo (create a simple text logo in Canva)
- `india_ne_map.png` — simple NE India map outline (Wikipedia SVG, convert)

Create folder: `flutter_app/assets/animations/`
- `loading_plant.json` — from **LottieFiles.com**, search "plant growing", download free
- `success_checkmark.json` — from LottieFiles, "success check" animation

---

## 📱 PART 5: FLUTTER SCREENS — DETAILED SPECIFICATIONS

### Screen 1: `splash_screen.dart`

**Purpose:** Shows for 2.5 seconds while the app initializes. Checks if farmer profile exists in SharedPreferences. Routes to `landing_screen` (new user) or `input_wizard_screen` (returning user).

**Layout:**
```
[Full screen dark background #0F1117]
[Center column]
  - Logo image (80×80 px, with soft green glow shadow)
  - App name: "AgriSutra NE" (kHeadingXL, kGreenAccent)
  - Tagline: "Smart Farming, Northeast India" (kBodyM, kTextSecondary)
  - [Bottom] Lottie animation: loading_plant.json (100×100, plays once)
  - [Bottom] Version text: "v1.0 · STCR Method" (kLabel)
```

**Logic:**
```dart
// In initState():
await Future.delayed(Duration(seconds: 2));
final prefs = await SharedPreferences.getInstance();
final hasProfile = prefs.getString('farmer_name') != null;
if (hasProfile) {
  Navigator.pushReplacementNamed(context, '/wizard');
} else {
  Navigator.pushReplacementNamed(context, '/landing');
}
```

---

### Screen 2: `landing_screen.dart`

**Purpose:** Landing page for first-time users. Builds trust, explains the app, leads to login.

**Sections (scrollable SingleChildScrollView):**

**Section A — Hero**
```
[GradientContainer: kBgDark → kBgCard, full width]
[Padding 24px sides]
  - Small badge chip: "🔬 STCR Certified Method" (kGreenAccent border, pill shape)
  - Heading: "Smart Fertilizer\nRecommendations\nfor NE India" (kHeadingXL, white, bold)
  - Subheading: "Tell us your soil. We tell you exactly what to apply." (kBodyL, kTextSecondary)
  - Hero image: hero_farmer.png (full width, rounded 16px, 200px height)
  - Primary CTA button: "Get Free Recommendation →" (full width, kGreenPrimary bg, white text, 56px height)
  - Secondary link: "Already registered? Log In" (kGreenAccent text, underline)
```

**Section B — How It Works (3 steps)**
```
[Background: kBgCard]
[Heading: "How It Works" centered]
[3 StepCards horizontally scrollable on mobile, vertically stacked]:

StepCard 1:
  - Circle with "1" (kGreenPrimary bg)
  - Icon: 🌽
  - Title: "Enter Your Crop & Soil"
  - Body: "Select Maize or Kholar. Tell us if your soil is Low, Medium or High in nutrients."

StepCard 2:
  - Circle with "2" (kGreenPrimary bg)
  - Icon: 🔬
  - Title: "STCR Engine Calculates"
  - Body: "Our engine uses field-tested STCR formulas developed for Kiphire region soils."

StepCard 3:
  - Circle with "3" (kGreenPrimary bg)
  - Icon: 🧪
  - Title: "Get Exact Amounts"
  - Body: "You receive exact kg of Urea, SSP and MOP for your field size — ready to buy."
```

**Section C — Features (4 cards in 2×2 grid)**
```
FeatureCard("🌏 Built for NE India", "Formulas tuned for Kiphire, Assam & Nagaland agro-climate")
FeatureCard("📐 Science-Backed", "Uses STCR methodology verified by agricultural institutes")
FeatureCard("📱 Works Offline*", "Results shown instantly. No internet needed after first load")
FeatureCard("🗣️ Simple to Use", "No jargon. Plain language. Farmer-friendly design")
```
*offline mode is aspirational for Phase 2; mark with asterisk + footnote

**Section D — Trust Badges**
```
[Row of partner logos or placeholder boxes]
"Validated for Kiphire District" | "STCR Research Based" | "Farmer Tested"
```

**Section E — Footer**
```
About Us | Privacy Policy | Contact
© 2024 AgriSutra NE
```

---

### Screen 3: `login_screen.dart`

**Purpose:** Phone number login. For demo/APK, implement a **mock OTP** flow (any 6-digit number works). Real Firebase Auth is Phase 2.

**Layout:**
```
[AppBar: transparent, back arrow]
[Body: center-aligned form]
  - Icon: 📱 (64px, kGreenAccent)
  - Title: "Login with Phone" (kHeadingL)
  - Subtitle: "We'll send you a verification code" (kBodyM, kTextSecondary)
  - [Card container, kBgCard background]
    - PhoneField: "+91" prefix, number input (large text, 18sp)
    - CTA: "Send OTP" button
    ─── [After Send OTP tapped] ───
    - OTP field: 6 boxes (each 48×56px, auto-advance on each digit)
    - Countdown timer: "Resend in 00:30"
    - "Verify OTP" button
  - Fine print: "We never share your phone number"
```

**Mock OTP Logic (for demo):**
```dart
// On "Send OTP": store phone number, show OTP field
// On "Verify OTP": accept any 6-digit code (e.g. "123456")
// Navigate to /profile_setup if new user, /wizard if returning
void _verifyOtp(String code) {
  // DEMO MODE: any 6 digits pass
  if (code.length == 6) {
    _savePhoneAndNavigate();
  }
}
```

**Important UX note:** Use `TextInputType.phone` and `TextInputAction.done`. On Android, the keypad should auto-show numeric keyboard. This matters for 40+ users.

---

### Screen 4: `profile_setup_screen.dart`

**Purpose:** Collect farmer's name, district, and land size. Saved to SharedPreferences. Shown only once after first login.

**Layout:**
```
[AppBar: "Your Profile", kGreenPrimary]
[Body: form with generous spacing]

  Step header: "Tell us about yourself" + "We personalize recommendations for your land"

  Field 1 — Name:
    - Label: "Your Name" (kBodyL)
    - TextField: large text (20sp), rounded border, placeholder "e.g. Ranjit Kumar"

  Field 2 — District:
    - Label: "Your District"
    - DropdownButton with options: ["Kiphire", "Phek", "Kohima", "Wokha", "Dimapur",
                                     "Kamrup", "Barpeta", "Nagaon", "Golaghat", "Other"]
    - Styled as a card-like row with arrow icon

  Field 3 — Land Size:
    - Label: "How much land do you farm?"
    - Slider: min 0.5, max 10.0, divisions 19, step 0.5
    - Live display card below slider: "2.5 Acres" (kValueL, kGreenAccent)
    - Below: show calculated hectares "= 1.01 hectares" (kLabel, kTextSecondary)

  Save Button: "Save & Start →" (full width, 56px, kGreenPrimary)
```

**Save Logic:**
```dart
Future<void> _saveProfile() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('farmer_name', _nameController.text);
  await prefs.setString('farmer_district', _selectedDistrict);
  await prefs.setDouble('land_size_acres', _landSize);
  Navigator.pushReplacementNamed(context, '/wizard');
}
```

---

### Screen 5: `input_wizard_screen.dart`

**Purpose:** The core input form. Collects crop, yield target, and N/P/K soil inputs. Sends to backend. This is the most used screen in the app.

**Important design choice:** Use a **PageView** with 3 pages (or a stepper). Do NOT put everything on one long scroll — farmers will get overwhelmed.

#### Page 1 of 3 — Crop & Yield Selection

```
[Step indicator at top: ●●○○ (step 1 of 3)]
[Card]
  Title: "What are you growing?" (kHeadingL)

  Crop Selection (two large tap-cards, side by side):
  ┌─────────────────┐  ┌─────────────────┐
  │   🌽            │  │   🌿            │
  │   Maize         │  │   Kholar        │
  │   (Local/Hybrid)│  │   (Legume)      │
  └─────────────────┘  └─────────────────┘
  Selected card gets kGreenPrimary border + slight scale-up animation

  Yield Target (shown after crop selected):
  Title: "What yield are you aiming for?"
  [For Maize]: Two chip buttons: "40 q/ha" | "50 q/ha"
  [For Kholar]: Two chip buttons: "8 q/ha" | "10 q/ha"
  Footnote: "q/ha = quintals per hectare"

  [Next →] button (disabled until both crop and yield selected)
```

#### Page 2 of 3 — Soil Nutrient Input

```
[Step indicator: ●●●○]
[Title: "Tell us about your soil"]
[Subtitle: "Each nutrient is assessed separately — this is the scientific way"]

[For each of N, P, K — shown as 3 expandable cards OR vertical list]:

NutrientInputCard for Nitrogen (🌿 green border):
  "Do you have a soil test report?"
  [Toggle/SegmentedButton]:  "No Test Report"  |  "I Have Test Values"

  If "No Test Report" selected:
    "How fertile is your soil's Nitrogen?"
    [3 chip cards]:
    ┌──────────┐  ┌──────────┐  ┌──────────┐
    │ 🔴 LOW   │  │ 🟡 MED   │  │ 🟢 HIGH  │
    │ <225     │  │ 225-500  │  │ >500     │
    │ kg/ha    │  │ kg/ha    │  │ kg/ha    │
    └──────────┘  └──────────┘  └──────────┘

  If "I Have Test Values" selected:
    TextField with label "Soil N value (kg/ha)"
    Range hint: "Typical: 150–400 kg/ha"
    Auto-detected class shown below: "→ Detected: MEDIUM"

[Same pattern for Phosphorus (🔵) and Potassium (🟡)]

[← Back] [Get Recommendation →]
```

**Critical implementation note:** Each nutrient card must store its own mode and value independently. Use a simple `SoilInputState` class per nutrient:
```dart
class SoilInputState {
  String mode = "class"; // "class" or "value"
  String fertilityClass = "medium"; // "low", "medium", "high"
  double? rawValue;
}
```

#### Page 3 of 3 — Confirm & Submit

```
[Step indicator: ●●●●]
[Title: "Review & Confirm"]

[Summary card]:
  Crop: Maize        Target Yield: 40 q/ha
  Land Size: 2.5 Acres
  Nitrogen:   MEDIUM CLASS
  Phosphorus: LOW CLASS
  Potassium:  HIGH CLASS  (or "Raw value: 320 kg/ha")

[Large CTA]: "🔬 Calculate My Fertilizer Dose"
  (kGreenPrimary, full width, 64px height, bold text 18sp)
  On tap: show loading animation → navigate to results_screen

[Loading state]:
  Lottie animation: loading_plant.json (200px)
  Text: "Running STCR calculations..." (animated dots)
```

**API Call logic (in input_wizard_screen.dart):**
```dart
Future<void> _getRecommendation() async {
  setState(() => _isLoading = true);
  try {
    final request = RecommendRequest(
      crop: _selectedCrop,              // "maize" or "kholar"
      targetYield: _selectedYield,
      nitrogenInput: _nInput.toSoilInput(),
      phosphorusInput: _pInput.toSoilInput(),
      potassiumInput: _kInput.toSoilInput(),
      landSizeAcres: _landSize,
    );
    final response = await ApiClient.instance.getRecommendation(request);
    Navigator.pushNamed(context, '/results', arguments: response);
  } catch (e) {
    _showErrorDialog(e.toString());
  } finally {
    setState(() => _isLoading = false);
  }
}
```

---

### Screen 6: `results_screen.dart`

**Purpose:** Show the fertilizer recommendation. This is what the farmer shows their dealer. This screen must be clear, beautiful, and printable.

**Layout (scrollable):**

#### Section A — Header Summary Banner
```
[Full-width gradient banner: kGreenPrimary → kBgCard]
  - "✅ Recommendation Ready" (white, 18sp)
  - Crop name + yield target
  - Date generated
  - Land size used for calculation
```

#### Section B — The Three Product Cards (most important!)
```
[3 cards, each full width, stacked vertically]

Card 1 — UREA (Nitrogen):
┌─────────────────────────────────────────┐
│ 🌿  NITROGEN                            │
│ ─────────────────────────────────────── │
│                                         │
│  Required Nutrient:    118.4 kg/ha      │ (kTextSecondary)
│                                         │
│  ┌───────────────────────────────────┐  │
│  │   UREA                            │  │
│  │   257.4 kg/ha     (kValueXL green)│  │
│  │   For your 2.5 acres: 104.2 kg    │  │ (kValueL white)
│  └───────────────────────────────────┘  │
│                                         │
│  Fertility class used: MEDIUM           │ (chip badge)
│  [Why this amount? ▼]                   │ (expandable)
└─────────────────────────────────────────┘

[Expandable "Why this amount?" section]:
  Shows: why text from nutrient_utils.py
  Shows: equation_used string
  Shows: schedule string
  Styled as a subtle inner card, kBgDark background
```

Repeat same card structure for SSP (Phosphorus, kColorP blue) and MOP (Potassium, kColorK amber).

#### Section C — Application Schedule
```
[Title: "📅 When to Apply" (kHeadingM)]

[3 Timeline cards]:

  Day 0 — At Sowing:
  [Circle "Day 0"] ──── "Apply ALL SSP + ALL MOP + Half of Urea"
                         "SSP: 156.3 kg  +  MOP: 83.3 kg  +  Urea: 128.7 kg"

  Day 30 — Top Dressing:
  [Circle "30"] ──── "Apply remaining quarter of Urea"
                      "Urea: 64.4 kg"

  Day 60 — Top Dressing:
  [Circle "60"] ──── "Apply final quarter of Urea"
                      "Urea: 64.4 kg"
```
The timeline circles should be connected by a vertical dashed line for clarity.

#### Section D — Action Buttons
```
[Share button]: Opens Android share sheet with text summary
[Save as PDF]: Phase 2 placeholder (show "Coming Soon" snackbar)
[New Recommendation]: Routes back to /wizard and clears state
```

---

## 🔧 PART 6: CORE FLUTTER FILES

### 6.1 `core/api_client.dart`

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

class ApiClient {
  static final ApiClient instance = ApiClient._internal();
  ApiClient._internal();

  // CHANGE THIS to your Railway/Render URL for production
  static const String kBaseUrl = "http://10.0.2.2:8000";  // Android emulator localhost
  // For real device testing: use your computer's IP, e.g. "http://192.168.1.5:8000"
  // For production APK: "https://agrisutra-ne.up.railway.app"

  Future<RecommendResponse> getRecommendation(RecommendRequest request) async {
    final url = Uri.parse("$kBaseUrl/recommend/");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(request.toJson()),
    ).timeout(Duration(seconds: 30));

    if (response.statusCode == 200) {
      return RecommendResponse.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error["detail"] ?? "Server error ${response.statusCode}");
    }
  }
}
```

### 6.2 `core/models.dart`

These Dart classes **must mirror** `schemas.py` exactly. Build them as JSON-serializable classes.

```dart
// SoilInput — mirrors SoilInput in schemas.py
class SoilInput {
  final String mode;           // "class" or "value"
  final String? fertilityClass;
  final double? rawValue;

  SoilInput({required this.mode, this.fertilityClass, this.rawValue});

  Map<String, dynamic> toJson() => {
    "mode": mode,
    if (fertilityClass != null) "fertility_class": fertilityClass,
    if (rawValue != null) "raw_value": rawValue,
  };
}

// RecommendRequest — mirrors RecommendRequest in schemas.py
class RecommendRequest {
  final String crop;
  final double targetYield;
  final SoilInput nitrogenInput;
  final SoilInput phosphorusInput;
  final SoilInput potassiumInput;
  final double landSizeAcres;

  RecommendRequest({
    required this.crop,
    required this.targetYield,
    required this.nitrogenInput,
    required this.phosphorusInput,
    required this.potassiumInput,
    required this.landSizeAcres,
  });

  Map<String, dynamic> toJson() => {
    "crop": crop,
    "target_yield": targetYield,
    "nitrogen_input": nitrogenInput.toJson(),
    "phosphorus_input": phosphorusInput.toJson(),
    "potassium_input": potassiumInput.toJson(),
    "land_size_acres": landSizeAcres,
  };
}

// NutrientResult — mirrors NutrientResult in schemas.py
class NutrientResult {
  final String nutrientName;
  final String nutrientSymbol;
  final String fertilizerName;
  final double requiredKgHa;
  final double productKgHa;
  final double productKgTotal;
  final String fertilityClassUsed;
  final String equationUsed;
  final String why;
  final String schedule;
  final String colorHex;

  NutrientResult({
    required this.nutrientName, required this.nutrientSymbol,
    required this.fertilizerName, required this.requiredKgHa,
    required this.productKgHa, required this.productKgTotal,
    required this.fertilityClassUsed, required this.equationUsed,
    required this.why, required this.schedule, required this.colorHex,
  });

  factory NutrientResult.fromJson(Map<String, dynamic> j) => NutrientResult(
    nutrientName: j["nutrient_name"],
    nutrientSymbol: j["nutrient_symbol"],
    fertilizerName: j["fertilizer_name"],
    requiredKgHa: j["required_kg_ha"].toDouble(),
    productKgHa: j["product_kg_ha"].toDouble(),
    productKgTotal: j["product_kg_total"].toDouble(),
    fertilityClassUsed: j["fertility_class_used"],
    equationUsed: j["equation_used"],
    why: j["why"],
    schedule: j["schedule"],
    colorHex: j["color_hex"],
  );

  Color get color {
    final hex = colorHex.replaceAll("#", "");
    return Color(int.parse("FF$hex", radix: 16));
  }
}

// ApplicationScheduleItem
class ScheduleItem {
  final String timing;
  final String description;
  final int daysAfterSowing;

  ScheduleItem({required this.timing, required this.description, required this.daysAfterSowing});

  factory ScheduleItem.fromJson(Map<String, dynamic> j) => ScheduleItem(
    timing: j["timing"],
    description: j["description"],
    daysAfterSowing: j["days_after_sowing"],
  );
}

// RecommendResponse — the full API response
class RecommendResponse {
  final String cropDisplay;
  final double targetYield;
  final double landSizeAcres;
  final NutrientResult nitrogen;
  final NutrientResult phosphorus;
  final NutrientResult potassium;
  final List<ScheduleItem> applicationSchedule;
  final String recommendationId;
  final String generatedAt;

  RecommendResponse({
    required this.cropDisplay, required this.targetYield,
    required this.landSizeAcres, required this.nitrogen,
    required this.phosphorus, required this.potassium,
    required this.applicationSchedule, required this.recommendationId,
    required this.generatedAt,
  });

  factory RecommendResponse.fromJson(Map<String, dynamic> j) => RecommendResponse(
    cropDisplay: j["crop_display"],
    targetYield: j["target_yield"].toDouble(),
    landSizeAcres: j["land_size_acres"].toDouble(),
    nitrogen: NutrientResult.fromJson(j["nitrogen"]),
    phosphorus: NutrientResult.fromJson(j["phosphorus"]),
    potassium: NutrientResult.fromJson(j["potassium"]),
    applicationSchedule: (j["application_schedule"] as List)
        .map((i) => ScheduleItem.fromJson(i)).toList(),
    recommendationId: j["recommendation_id"],
    generatedAt: j["generated_at"],
  );
}
```

### 6.3 `main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme.dart';
import 'screens/splash_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/input_wizard_screen.dart';
import 'screens/results_screen.dart';

void main() {
  runApp(const AgriSutraApp());
}

class AgriSutraApp extends StatelessWidget {
  const AgriSutraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriSutra NE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: kGreenPrimary,
          secondary: kGreenAccent,
          surface: kBgCard,
          background: kBgDark,
        ),
        scaffoldBackgroundColor: kBgDark,
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (ctx) => const SplashScreen(),
        '/landing': (ctx) => const LandingScreen(),
        '/login': (ctx) => const LoginScreen(),
        '/profile_setup': (ctx) => const ProfileSetupScreen(),
        '/wizard': (ctx) => const InputWizardScreen(),
        '/results': (ctx) => const ResultsScreen(),
      },
    );
  }
}
```

---

## 🧩 PART 7: REUSABLE WIDGETS

### 7.1 `widgets/app_button.dart`

Create a single consistent button used everywhere:

```dart
// Usage: AppButton(label: "Get Recommendation", onTap: _onTap)
// Supports: primary (green filled), secondary (outlined), loading state
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;
  final bool isLoading;
  final IconData? icon;

  // [Implementation: ElevatedButton with custom style using kGreenPrimary]
  // Height: 56px, border radius: kRadiusButton
  // Loading shows CircularProgressIndicator in place of label
}
```

### 7.2 `widgets/nutrient_card.dart`

The expandable N/P/K result card on the results screen:

```dart
// Animates open/close. Shows:
// - Nutrient name + icon in header (colored by nutrient)
// - Product kg/ha as large number
// - Total kg for farmer's land
// - "Why?" expandable section with explanation text
class NutrientResultCard extends StatefulWidget {
  final NutrientResult result;
  // Animation: use flutter_animate package .animate().slideY().fadeIn()
}
```

### 7.3 `widgets/step_indicator.dart`

```dart
// Renders the step progress bar seen at top of wizard:
// ─────●─────●─────○─────○─────
// "Crop"  "Soil"  "Review"  "Results"
class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> labels;
  // Active steps: kGreenAccent filled circle
  // Completed steps: kGreenPrimary filled circle with checkmark
  // Future steps: kBgCard border circle
}
```

### 7.4 `widgets/soil_input_tile.dart`

The reusable input tile for N/P/K on the wizard:
```dart
class SoilInputTile extends StatelessWidget {
  final String nutrientName;   // "Nitrogen"
  final String nutrientSymbol; // "N"
  final Color color;           // kColorN, kColorP, kColorK
  final String emoji;          // "🌿", "🌱", "🌾"
  final SoilInputState state;
  final Function(SoilInputState) onChanged;
  
  // Contains toggle between "Class" and "Value" mode
  // Shows 3-chip selector for class mode
  // Shows TextField for value mode
  // Shows detected class in value mode
}
```

---

## 🔗 PART 8: INTEGRATION CHECKLIST

Before you build the APK, verify each item:

### Backend Tests
- [ ] `GET /health` → returns `{"status": "ok"}`
- [ ] `POST /recommend/` with Maize, Low N, Medium P, High K, T=40 → returns valid JSON
- [ ] `POST /recommend/` with Kholar, raw SN=200 → returns valid JSON
- [ ] FPE equations match hand-calculated values from fpe_engine.py directly
- [ ] Verify: Maize, Low, T=40 → FN = 3.93×40 - 0.26×150 = 157.2 - 39 = **118.2**
- [ ] Verify: Urea = 118.2 / 0.46 = **256.96 ≈ 257.0**

### Flutter Tests
- [ ] Splash screen → correctly routes to /landing (new) or /wizard (returning)
- [ ] Login with "123456" → navigates to profile setup
- [ ] Profile saves to SharedPreferences and persists on restart
- [ ] Wizard Page 1: crop + yield both required before "Next" enabled
- [ ] Wizard Page 2: each nutrient card independently stores its selection
- [ ] Wizard Page 3: summary shows correct crop, yield, soil classes
- [ ] API call from wizard reaches backend (test on real device with correct IP)
- [ ] Results screen shows 3 cards with correct numbers
- [ ] "Why?" expandables open/close smoothly
- [ ] Application schedule shows correct split calculations
- [ ] Share button opens Android share sheet

---

## 📦 PART 9: BUILDING THE APK

### 9.1 Update Backend URL

In `flutter_app/lib/core/api_client.dart`, change `kBaseUrl` to your deployed Railway URL:
```dart
static const String kBaseUrl = "https://your-app.up.railway.app";
```

### 9.2 Configure Android Permissions

In `flutter_app/android/app/src/main/AndroidManifest.xml`, add:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```

Also in `AndroidManifest.xml`, ensure `usesCleartextTraffic` is enabled for development:
```xml
<application
  android:usesCleartextTraffic="true"
  ... >
```

### 9.3 App Icon & Name

Set app name in `android/app/src/main/res/values/strings.xml`:
```xml
<string name="app_name">AgriSutra NE</string>
```

Replace icons in `android/app/src/main/res/mipmap-*/` with your logo PNG files. Use https://appicon.co to generate all sizes from one 1024×1024 PNG.

### 9.4 Build Release APK

```bash
cd flutter_app
flutter build apk --release
```

Output: `flutter_app/build/app/outputs/flutter-apk/app-release.apk`

Transfer to device via USB or send via WhatsApp/email.

---

## 🗺️ PART 10: BUILD ORDER (Follow This Exactly)

1. **Setup backend environment** → copy fpe_engine.py, nutrient_utils.py
2. **Write schemas.py** → defines the contract
3. **Write recommend.py** → core API logic
4. **Write main.py** → register router
5. **Test backend** with `curl` or Postman (VERIFY FPE numbers match!)
6. **Deploy to Railway** → note the URL
7. **Create Flutter project** → set up pubspec.yaml
8. **Write `core/theme.dart`** → ALL colors and styles here first
9. **Write `core/models.dart`** → mirrors schemas.py
10. **Write `core/api_client.dart`** → uses models.dart
11. **Write `widgets/`** → all 4 reusable widgets
12. **Write `screens/splash_screen.dart`**
13. **Write `screens/landing_screen.dart`**
14. **Write `screens/login_screen.dart`**
15. **Write `screens/profile_setup_screen.dart`**
16. **Write `screens/input_wizard_screen.dart`** (the most complex screen)
17. **Write `screens/results_screen.dart`**
18. **Wire routes in `main.dart`**
19. **Test full flow on Android emulator**
20. **Update kBaseUrl to Railway URL**
21. **Build release APK**

---

## ⚠️ PART 11: CRITICAL DO-NOTS

1. **DO NOT modify `fpe_engine.py`** — not even whitespace. The equations are the scientific core.
2. **DO NOT modify `nutrient_utils.py`** — it provides the explanation texts used in the UI.
3. **DO NOT rename or restructure the FPEEngine class methods** — the router calls `FPEEngine.compute_N()`, `compute_P()`, `compute_K()` directly.
4. **DO NOT mix fertility inputs across nutrients** — each of N, P, K is computed independently. The backend enforces this.
5. **DO NOT hardcode kg values** — always derive from the API response. The FPE equations change by crop and class.
6. **DO NOT skip the "fertility_class detected" display** — when farmer enters a raw value, showing "Detected: MEDIUM" builds trust.

---

## 🧪 PART 12: SAMPLE TEST DATA

Use these to verify correctness end-to-end:

### Test Case 1: Maize, All Class Mode
```json
{
  "crop": "maize",
  "target_yield": 40,
  "nitrogen_input": {"mode": "class", "fertility_class": "low"},
  "phosphorus_input": {"mode": "class", "fertility_class": "medium"},
  "potassium_input": {"mode": "class", "fertility_class": "high"},
  "land_size_acres": 2.0
}
```
**Expected (verify manually):**
- FN = 3.93×40 - 0.26×150 = 157.2 - 39.0 = **118.2 kg/ha**
- Urea = 118.2 / 0.46 = **256.96 kg/ha**
- FP = 1.97×40 - 1.66×20 = 78.8 - 33.2 = **45.6 kg/ha**
- SSP = 45.6 / 0.16 = **285.0 kg/ha**
- FK = 2.98×40 - 0.34×300 = 119.2 - 102.0 = **17.2 kg/ha**
- MOP = 17.2 / 0.60 = **28.67 kg/ha**

### Test Case 2: Kholar, Raw Values
```json
{
  "crop": "kholar",
  "target_yield": 8,
  "nitrogen_input": {"mode": "value", "raw_value": 200},
  "phosphorus_input": {"mode": "value", "raw_value": 15},
  "potassium_input": {"mode": "value", "raw_value": 120},
  "land_size_acres": 1.0
}
```
- SN=200 → class "low" (< 225 for kholar N)
- FN = 23.76×8 - 0.52×200 = 190.08 - 104 = **86.08 kg/ha**
- Urea = 86.08 / 0.46 = **187.13 kg/ha**

---

## 📝 PART 13: PHASE 2 ROADMAP (for reference, don't build now)

- Firebase Phone Auth (replace mock OTP)
- PostgreSQL database (store recommendations history)
- Multilingual support (Hindi, Assamese, Nagamese) using Flutter `intl`
- Voice input using `speech_to_text` Flutter package
- Offline mode: bundle FPE equations in Dart, calculate without internet
- Weather data from NASA POWER API for seasonal advice
- PDF generation of recommendation slip (farmer takes to fertilizer shop)
- ML yield prediction (XGBoost) when farmer leaves yield blank

---

*This manual was prepared based on the original `fpe_engine.py`, `nutrient_utils.py`, and `app.py` from the AgriSutra NE repository, plus the project_brief.md. All FPE equations have been verified against the original Python implementation. Good luck — this app will genuinely help farmers. 🌾*
