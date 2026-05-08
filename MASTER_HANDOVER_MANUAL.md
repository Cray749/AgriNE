# 🌾 AgriSutra NE — Master Handover & Continuation Manual
### For: New Claude Session / New Developer Onboarding
**Version:** 2.0 | **Date:** May 2026 | **Status:** Session 4 complete, Session 5 + fixes pending

---

## 📌 HOW TO USE THIS DOCUMENT

This manual exists so that ANY new Claude session (or developer) can pick up exactly where work stopped, with **zero context loss**. Paste the entire content of this file as your first message in a new chat, attach the current zip of the codebase, and say *"Continue from SESSION 5 of this manual."*

Every section is self-contained. Read top to bottom on first pass. Jump to specific sections when making targeted changes.

---

## 🗂️ PART 1: PROJECT SNAPSHOT

### What Is AgriSutra NE?
A mobile-first Flutter + FastAPI app that gives Northeast India farmers exact fertilizer prescriptions (Urea / SSP / MOP in kg) using the **STCR (Soil Test Crop Response)** scientific method. Targeted at Kiphire, Assam, Nagaland. Primary crops: **Maize** and **Kholar** (legume).

### Current Repository Structure
```
AgriReeti/
├── backend/
│   ├── __init__.py
│   ├── fpe_engine.py          ← Core math. NEVER MODIFY EQUATIONS.
│   ├── nutrient_utils.py      ← Explanation text helpers. DO NOT MODIFY.
│   ├── input_enricher.py      ← NEW (from zip): NASA weather API
│   ├── output_enricher.py     ← NEW (from zip): FYM organic pathway + clamp
│   ├── delivery.py            ← NEW (from zip): SQLite history + PDF
│   ├── main.py                ← FastAPI entry point, CORS, router registration
│   ├── models/
│   │   ├── __init__.py
│   │   └── schemas.py         ← Pydantic request/response models
│   ├── routers/
│   │   ├── __init__.py
│   │   └── recommend.py       ← POST /recommend/ endpoint
│   └── requirements.txt
│
├── flutter_app/
│   ├── pubspec.yaml
│   ├── assets/
│   │   ├── images/hero_farmer.png
│   │   └── animations/        ← (empty, Lottie JSONs go here)
│   └── lib/
│       ├── main.dart           ← MaterialApp, theme, routes
│       ├── core/
│       │   ├── theme.dart      ← ALL colors/fonts/spacing constants
│       │   ├── models.dart     ← Dart mirrors of schemas.py
│       │   └── api_client.dart ← HTTP singleton, ApiException type
│       ├── screens/
│       │   ├── splash_screen.dart       ✅ COMPLETE
│       │   ├── landing_screen.dart      ✅ COMPLETE
│       │   ├── login_screen.dart        ✅ COMPLETE
│       │   ├── profile_setup_screen.dart ✅ COMPLETE
│       │   ├── input_wizard_screen.dart ✅ COMPLETE
│       │   └── results_screen.dart      ⚠️  STUB — needs full Session 5 build
│       └── widgets/
│           ├── app_button.dart
│           ├── fertilizer_result_card.dart
│           ├── nutrient_card.dart
│           ├── soil_input_tile.dart
│           └── step_indicator.dart
│
├── render.yaml                ← Render.com deployment blueprint
└── project_brief.md
```

---

## ⚙️ PART 2: BACKEND — WHAT EXISTS & WHAT CHANGED

### 2.1 Core Logic Files (DO NOT MODIFY EQUATIONS)

| File | Purpose | Changed in v2? |
|------|---------|---------------|
| `fpe_engine.py` | STCR math: compute_N, compute_P, compute_K | ❌ No change |
| `nutrient_utils.py` | Returns why/schedule/conversion strings | ❌ No change |

### 2.2 New Files from the Boss's Zip

These three files are **new** and must be copied into `backend/` and integrated:

#### `output_enricher.py` — FYM Organic Pathway
```python
def enrich_output(FN, FP, FK, go_organic=False, fym_tonnes=None):
```
- Clamps all negative FPE values to 0.0 (CRITICAL — without this, negative kg values crash the UI)
- If farmer chooses organic pathway: deducts FYM nutrient credits from FP and FK
  - FYM provides: 2.5 kg P₂O₅ per tonne, 5.0 kg K₂O per tonne
- Returns: `(FN, FP, FK, explanation_string)`

**Integration point:** In `backend/routers/recommend.py`, after calling FPEEngine, call:
```python
from ..output_enricher import enrich_output
FN, FP, FK, fym_msg = enrich_output(n_res["FN"], p_res["FP"], k_res["FK"])
# Then use the clamped FN/FP/FK for all downstream calculations
```

#### `input_enricher.py` — NASA Weather Context
```python
def get_weather_context(lat, lon):
```
- Fetches monthly rainfall from NASA POWER API for given GPS coordinates
- Returns `{"avg_monthly_rainfall_mm": X}` or `None` on failure (graceful)
- Used in Phase 2 for weather-adjusted recommendations

**Integration point:** Optional for now. Add `lat`/`lon` fields to `RecommendRequest` (optional, default None) and call this function in `recommend.py` if lat/lon are provided.

#### `delivery.py` — History & PDF
- `save_to_history(...)` → SQLite `history.db` (local to server)
- `generate_pdf_report(...)` → FPDF2-generated prescription PDF
- **Integration point:** Call `save_to_history()` at the end of every `/recommend/` call. PDF endpoint can be Phase 2.

### 2.3 Updated `backend/requirements.txt`
Add these new dependencies (append to existing file):
```
fpdf2>=2.7.9
requests>=2.31.0
```

---

## 📱 PART 3: ALL PENDING FLUTTER CHANGES

These are the complete list of changes needed, in priority order:

### Change 1 — Fix "Right Overflow by 19 pixels" in Results Screen ⚠️ URGENT
**File:** `flutter_app/lib/screens/results_screen.dart`
**Problem:** In the "What to Buy" section, the three cards (Urea/SSP/MOP) show values that overflow horizontally. See attached screenshot.
**Root cause:** The value text (e.g. "138.26") uses `kStyleValueXL` (36sp) inside a `Row` with fixed card widths. On narrow screens (360px wide cheapo Android), the three cards can't fit.
**Fix:**
```dart
// WRONG — overflows:
Text('${nutrient.productKgHa}', style: kStyleValueXL)

// CORRECT — use FittedBox to auto-shrink:
FittedBox(
  fit: BoxFit.scaleDown,
  alignment: Alignment.centerLeft,
  child: Text(
    nutrient.productKgHa.toStringAsFixed(1),
    style: kStyleValueXL,
  ),
)
```
Also wrap each card in `Expanded` (not fixed width) and add `overflow: TextOverflow.ellipsis` as fallback.

**Full card layout fix for the 3-column row:**
```dart
Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: response.nutrients.map((n) => Expanded(
    child: _ProductCard(nutrient: n), // each card stretches equally
  )).toList(),
)
```

### Change 2 — Light / Dark Theme Toggle
**Files to change:**
- `flutter_app/lib/core/theme.dart` — add light theme colors + `buildLightTheme()`
- `flutter_app/lib/main.dart` — add `ThemeProvider` using `provider` package
- `flutter_app/lib/screens/profile_setup_screen.dart` OR add a settings icon in AppBar

**Step-by-step:**

**Step A — `theme.dart`:** Add light palette constants:
```dart
// LIGHT THEME COLORS
const Color kLightBgPrimary   = Color(0xFFF1F8E9);  // Soft warm white-green
const Color kLightBgCard      = Color(0xFFFFFFFF);
const Color kLightBgCardBorder= Color(0xFFDCEDC8);
const Color kLightTextPrimary = Color(0xFF1B2E1A);
const Color kLightTextSecondary = Color(0xFF558B2F);

ThemeData buildLightTheme() {
  // Mirror of buildAppTheme() but with light colors
  // Primary: Color(0xFF2E7D32), Surface: white, Text: dark
}
```

**Step B — Create `ThemeProvider`** in `flutter_app/lib/core/theme_provider.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = true;
  bool get isDark => _isDark;

  ThemeProvider() { _loadTheme(); }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('is_dark_theme') ?? true;
    notifyListeners();
  }

  Future<void> toggle() async {
    _isDark = !_isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_theme', _isDark);
    notifyListeners();
  }
}
```

**Step C — `main.dart`:** Wrap `MaterialApp` in `ChangeNotifierProvider`:
```dart
import 'package:provider/provider.dart';
import 'core/theme_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const AgriSutraApp(),
    ),
  );
}

class AgriSutraApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      theme:      buildLightTheme(),
      darkTheme:  buildAppTheme(),
      themeMode:  themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
      // ... rest of MaterialApp unchanged
    );
  }
}
```

**Step D — Add toggle button** to the AppBar in `input_wizard_screen.dart` or as a FAB on `profile_setup_screen.dart`:
```dart
IconButton(
  icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: kGreenAccent),
  onPressed: () => context.read<ThemeProvider>().toggle(),
)
```

### Change 3 — ICAR Logo on Splash Screen
**File:** `flutter_app/lib/screens/splash_screen.dart`
**Asset needed:** `flutter_app/assets/images/icar_logo.png`
  - Download from: https://icar.org.in (official ICAR logo)
  - OR use the placeholder approach below until the file is added

**Current code** in `splash_screen.dart` around line 100:
```dart
// Logo circle — REPLACE this Container:
Container(
  width: 92, height: 92,
  decoration: BoxDecoration(shape: BoxShape.circle, ...),
  child: const Icon(Icons.eco_rounded, color: kGreenAccent, size: 46),
)
```

**Replace with:**
```dart
// With asset (when icar_logo.png is in assets/images/):
Container(
  width: 96, height: 96,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: Colors.white,  // ICAR logo needs white bg
    boxShadow: [BoxShadow(color: kGreenAccent.withOpacity(0.30), blurRadius: 28)],
  ),
  clipBehavior: Clip.antiAlias,
  child: Padding(
    padding: const EdgeInsets.all(8),
    child: Image.asset(
      'assets/images/icar_logo.png',
      fit: BoxFit.contain,
    ),
  ),
)
```

**pubspec.yaml** — ensure `assets/images/` is listed (it already is).

### Change 4 — Farmer Profile Section
**New file:** `flutter_app/lib/screens/farmer_profile_screen.dart`

This is a NEW screen, not a replacement. Add it to `main.dart` routes as `/farmer_profile`.

**Fields to collect/display:**
- Name (already in SharedPreferences as `farmer_name`)
- Phone (already in SharedPreferences as `farmer_phone`)
- Village (new key: `farmer_village`)
- District (already as `farmer_district`)
- Land size (already as `land_size_acres`)
- **Cropping History** (new key: `cropping_history_json` — stored as JSON string list)

**Cropping history data model:**
```dart
class CropHistoryEntry {
  final String season;   // "Kharif 2025", "Rabi 2025-26"
  final String crop;     // "Maize", "Kholar"
  final double yield;    // Actual yield achieved
  final String notes;    // Optional free text

  Map<String, dynamic> toJson() => {
    'season': season, 'crop': crop, 'yield': yield, 'notes': notes
  };
  factory CropHistoryEntry.fromJson(Map j) => CropHistoryEntry(
    season: j['season'], crop: j['crop'],
    yield: (j['yield'] as num).toDouble(), notes: j['notes'] ?? '',
  );
}
```

**How to access it:** Add a profile icon button to the AppBar of `input_wizard_screen.dart`:
```dart
actions: [
  IconButton(
    icon: const Icon(Icons.account_circle_outlined, color: kGreenAccent),
    onPressed: () => Navigator.pushNamed(context, '/farmer_profile'),
  ),
]
```

**SharedPreferences keys for profile screen:**
```
farmer_name        → String
farmer_phone       → String
farmer_village     → String  (NEW)
farmer_district    → String
land_size_acres    → double
cropping_history_json → String (JSON array)
```

### Change 5 — Improved Design Theme
**File:** `flutter_app/lib/core/theme.dart`

**New palette (replaces existing — keep same constant names for zero-impact on other files):**
```dart
// GREENS — richer, deeper, more trustworthy
const Color kGreenPrimary = Color(0xFF1B5E20);  // Deep ICAR-grade forest green
const Color kGreenAccent  = Color(0xFF00E676);  // Vivid spring green (legible on dark)
const Color kGreenLight   = Color(0xFFE8F5E9);

// BACKGROUNDS — warmer dark (less harsh than pure black)
const Color kBgDark       = Color(0xFF111814);  // Warm near-black with green tint
const Color kBgCard       = Color(0xFF1C2B22);  // Richer card surface
const Color kBgCardBorder = Color(0xFF2D4A35);

// YELLOW — harvest gold (replaces previous amber for K)
const Color kColorK       = Color(0xFFFFD600);  // Pure harvest yellow — vivid on dark

// BLUE — sky/water (P keeps sky blue but richer)
const Color kColorP       = Color(0xFF40C4FF);  // Bright sky blue — legible on dark cards

// GREEN (N stays mint but slightly brighter)
const Color kColorN       = Color(0xFF69F0AE);  // Same — already perfect

// NEW — accent gradients for header banners
const List<Color> kGradientHeader = [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)];
```

Also upgrade `buildAppTheme()`:
- `ElevatedButton` → add gradient using `LinearGradient` on a custom `ButtonStyle`
- `AppBar` → use subtle gradient instead of flat `kBgDark`
- `Card` → increase elevation to 8, add `shadowColor: kGreenAccent.withOpacity(0.2)`
- `BottomNavigationBar` (if added later) → styled dark with green selected indicator

---

## 🚀 PART 4: BACKEND DEPLOYMENT ON RENDER.COM

This is how your boss in Assam can run the app 24/7 without you starting anything locally.

### 4.1 One-Time Setup (do this once, takes ~15 minutes)

**Step 1 — Push code to GitHub**
```bash
# In your AgriReeti/ folder:
git init
git add .
git commit -m "Initial AgriSutra NE backend"
git remote add origin https://github.com/YOUR_USERNAME/agrisutra-ne.git
git push -u origin main
```

**Step 2 — Create Render account**
- Go to https://render.com
- Sign up with GitHub (free tier is sufficient)
- Click "New +" → "Web Service"

**Step 3 — Deploy the FastAPI backend**
- Connect your GitHub repo
- Set these fields:
  - **Name:** `agrisutra-backend`
  - **Root Directory:** ` ` (leave blank — repo root)
  - **Runtime:** Python 3
  - **Build Command:** `pip install -r backend/requirements.txt`
  - **Start Command:** `uvicorn backend.main:app --host 0.0.0.0 --port $PORT`
  - **Plan:** Free

**Step 4 — Wait for build** (~3–5 minutes first time)

**Step 5 — Get your live URL**
After deploy, Render gives you a URL like:
`https://agrisutra-backend.onrender.com`

**Step 6 — Test it immediately**
```
GET https://agrisutra-backend.onrender.com/health
→ {"status": "ok", "service": "AgriSutra NE API"}
```

### 4.2 Update Flutter App to Use Production URL

**File:** `flutter_app/lib/core/api_client.dart`

**Change line:**
```dart
// BEFORE (local dev):
static const String kBaseUrl = 'http://10.0.2.2:8000';

// AFTER (production):
static const String kBaseUrl = 'https://agrisutra-backend.onrender.com';
```

Then rebuild and reinstall the APK on your boss's phone.

### 4.3 Important Notes About Free Render Tier

⚠️ **Cold Start Warning:** Render free tier "sleeps" after 15 minutes of no requests. The first request after sleep takes 30–60 seconds. Solutions:
1. **UptimeRobot** (free): Set up a monitor to ping `/health` every 14 minutes → server stays awake permanently.
   - Go to https://uptimerobot.com → New Monitor → HTTP(S) → URL: your Render health endpoint → 14-minute interval
2. Alternatively, tell your boss the first tap may be slow — subsequent taps are instant.

### 4.4 Using the Existing render.yaml (Blueprint Deploy)

The `render.yaml` already in the zip deploys all three services automatically:
```bash
# After pushing render.yaml to GitHub:
# Go to Render Dashboard → New → Blueprint → select your repo
# Render reads render.yaml and creates all services automatically
```

The render.yaml specifies:
- `agrisutra-backend` → FastAPI (free plan)
- `agrisutra-streamlit` → Streamlit UI (free plan)
- `agrisutra-flutter` → Flutter web static site (free plan)

---

## 🔨 PART 5: COMPLETE SESSION 5 — results_screen.dart

Session 5 is the final Flutter screen. The `results_screen.dart` is currently a stub (27 lines).

### 5.1 What Results Screen Must Show

**Section A — Header Banner:**
- Full-width gradient (kGreenPrimary → kBgCard)
- "✅ Recommendation Ready" title
- Crop name, target yield, date, land size info chips

**Section B — "What to Buy" (3 product cards, MOST IMPORTANT):**
- Three cards: Urea (N, mint green), SSP (P, sky blue), MOP (K, harvest yellow)
- Each card shows:
  - Product name + emoji
  - `product_kg_ha` → BIG number (use `FittedBox` to prevent overflow!)
  - "kg / ha"
  - `product_kg_total` → "Total: X kg" (for farmer's actual land)
- Cards must be in a `Row` of `Expanded` widgets, NOT fixed widths
- Dealer tip text below: "Show these numbers to your fertilizer dealer"

**Section C — Application Schedule Timeline:**
- 3 timeline items (Day 0, Day 30, Day 60)
- Connected by dashed vertical line
- Each item: circle with day number + instruction text

**Section D — "Why this amount?" expandable per nutrient:**
- Tappable expander shows: `why` text, `schedule` string, `equation_used`

**Section E — Action buttons:**
- Share (text summary via `Share.share()`)
- New Recommendation (Navigator.pushReplacementNamed → /wizard)
- Save PDF (Phase 2 — shows snackbar "Coming soon")

### 5.2 Key Implementation Detail — Route Argument
The results screen receives its data as a route argument:
```dart
// In results_screen.dart:
@override
Widget build(BuildContext context) {
  final response = ModalRoute.of(context)!.settings.arguments as RecommendResponse;
  // Use response.nitrogen, response.phosphorus, response.potassium
}
```

### 5.3 Overflow Fix (Critical)
```dart
// ALWAYS use FittedBox for kg/ha values:
FittedBox(
  fit: BoxFit.scaleDown,
  child: Text(
    '${nutrient.productKgHa.toStringAsFixed(1)}',
    style: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      color: nutrient.color,
    ),
  ),
)
```

---

## 📋 PART 6: HOW TO START A NEW CHAT SESSION

When this chat runs out of credits:

1. **Open a new Claude chat** (free or new account)
2. **Attach the current codebase zip** (download AgriReeti folder as zip)
3. **Attach this manual** (MASTER_HANDOVER_MANUAL.md)
4. **Paste this opening prompt:**

```
I am continuing development of AgriSutra NE — a Flutter + FastAPI fertilizer 
recommendation app for Northeast India. The attached zip is the complete current 
codebase and the attached manual is the handover document.

Please read MASTER_HANDOVER_MANUAL.md first, then:
[STATE WHICH TASK YOU WANT — e.g.]:
- "Build Session 5: results_screen.dart with the overflow fix"
- "Implement Change 2: Light/Dark theme toggle"
- "Deploy backend to Render and update api_client.dart"
- "Build the farmer profile screen (Change 4)"

Do NOT change fpe_engine.py or nutrient_utils.py equations.
```

---

## 🔑 PART 7: CRITICAL RULES — READ BEFORE EVERY SESSION

1. **NEVER modify equations** in `fpe_engine.py` or `nutrient_utils.py`
2. **N, P, K are always independent** — never share soil inputs across nutrients
3. **SharedPreferences keys** (must be consistent across ALL files):
   - `farmer_name` → String
   - `farmer_phone` → String
   - `farmer_district` → String
   - `farmer_village` → String (new in v2)
   - `land_size_acres` → double
   - `is_dark_theme` → bool (new in v2)
   - `cropping_history_json` → String (JSON, new in v2)
4. **Route strings** (must match main.dart exactly):
   - `/` → SplashScreen
   - `/landing` → LandingScreen
   - `/login` → LoginScreen
   - `/profile_setup` → ProfileSetupScreen
   - `/wizard` → InputWizardScreen
   - `/results` → ResultsScreen (receives `RecommendResponse` as argument)
   - `/farmer_profile` → FarmerProfileScreen (new in v2)
5. **Backend URL** for dev vs prod:
   - Android emulator: `http://10.0.2.2:8000`
   - Physical device (same WiFi): `http://192.168.X.X:8000`
   - Production: `https://agrisutra-backend.onrender.com`
6. **FittedBox rule**: All `product_kg_ha` and `product_kg_total` values on result cards MUST be wrapped in `FittedBox(fit: BoxFit.scaleDown)` to prevent overflow on small screens.

---

## 🧪 PART 8: QUICK TEST CHECKLIST

Run this after every session to confirm nothing broke:

### Backend Test (Postman or browser)
```bash
# 1. Health check
GET http://localhost:8000/health
Expected: {"status": "ok", "service": "AgriSutra NE API"}

# 2. Full recommendation
POST http://localhost:8000/recommend/
Body:
{
  "crop": "maize",
  "target_yield": 40,
  "nitrogen_input": {"mode": "class", "fertility_class": "low"},
  "phosphorus_input": {"mode": "class", "fertility_class": "medium"},
  "potassium_input": {"mode": "class", "fertility_class": "high"},
  "land_size_acres": 2.0
}
Expected: nitrogen.required_kg_ha = 118.2, nitrogen.product_kg_ha = 256.96
```

### Flutter Test
```bash
flutter pub get && flutter run
```
Flow: Splash → Landing → Login (any 10-digit + 6-digit OTP) → Profile Setup → Wizard → Results

---

## 📦 PART 9: NEW FILES TO COPY INTO BACKEND

These files from the boss's zip must be placed in `backend/`:
- `output_enricher.py` → `backend/output_enricher.py`
- `input_enricher.py`  → `backend/input_enricher.py`
- `delivery.py`         → `backend/delivery.py`
- `render.yaml`         → `AgriReeti/render.yaml` (repo root, already there)

Update `backend/requirements.txt` — append:
```
fpdf2>=2.7.9
requests>=2.31.0
```

---

## 💡 PART 10: ARCHITECTURE DECISIONS LOG

| Decision | Reason |
|----------|--------|
| Flutter (not React Native) | Native APK, works on cheap Android, no JS bridge |
| Dark theme default | Farmers use phones in bright sunlight — dark bg reduces glare |
| SharedPreferences (not database) | No server needed for profile; works fully offline |
| PageView wizard (not single scroll) | Prevents overwhelm for low-literacy users |
| FPEEngine equations unchanged | Validated by ICAR; any change invalidates the science |
| FittedBox for values | Handles 300px to 430px Android screens without layout work |
| Render.com free tier | Zero cost, no credit card needed, one-click deploy from GitHub |
| UptimeRobot ping | Prevents Render cold starts without paying for paid tier |
| provider package | Simple state (theme toggle only) — no Redux/Riverpod overengineering |

---

*End of MASTER_HANDOVER_MANUAL.md — AgriSutra NE v2.0*
*This document is self-sufficient. A new Claude session reading only this file + the codebase zip can continue development without any other context.*
