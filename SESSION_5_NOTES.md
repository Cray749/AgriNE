# 🌾 AgriSutra NE — Session 5 Deliverables & Integration Guide

## Files Delivered (copy into your Flutter project exactly as-is)

```
lib/
  screens/
    results_screen.dart      ← Screen 6 (the full results display)
  widgets/
    app_button.dart          ← Reusable button (all screens)
    nutrient_card.dart       ← Expandable N/P/K detail card
    fertilizer_result_card.dart ← Compact at-a-glance card
    step_indicator.dart      ← Progress dots for wizard
    soil_input_tile.dart     ← Soil input tile for wizard Page 2
```

---

## 1. Add `share_plus` to pubspec.yaml

`results_screen.dart` uses `share_plus` for the Share button.
Add this to `pubspec.yaml` under `dependencies`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.1
  google_fonts: ^6.2.1
  shared_preferences: ^2.2.3
  share_plus: ^9.0.0      # ← ADD THIS
```

Then run:
```bash
flutter pub get
```

---

## 2. Verify your `core/theme.dart` has these constants

`results_screen.dart` and the widgets reference these from theme.dart.
Make sure ALL of these are declared:

```dart
// Colors
const Color kGreenPrimary    = Color(0xFF2E7D32);
const Color kGreenAccent     = Color(0xFF69F0AE);
const Color kBgDark          = Color(0xFF0F1117);
const Color kBgCard          = Color(0xFF1A2420);
const Color kBgCardBorder    = Color(0xFF2D4A3E);
const Color kTextPrimary     = Color(0xFFE0E0E0);
const Color kTextSecondary   = Color(0xFF90A4AE);
const Color kTextHighlight   = Color(0xFFFFFFFF);
const Color kColorN          = Color(0xFF69F0AE);
const Color kColorP          = Color(0xFF81D4FA);
const Color kColorK          = Color(0xFFFFCC80);
const Color kSuccess         = Color(0xFF4CAF50);
const Color kWarning         = Color(0xFFFF9800);
const Color kError           = Color(0xFFE53935);

// Spacing
const double kRadiusCard     = 16.0;
const double kRadiusButton   = 12.0;
const double kRadiusChip     = 24.0;
const EdgeInsets kPaddingScreen = EdgeInsets.symmetric(horizontal: 20, vertical: 16);

// Font
const String kFontFamily = 'Poppins';
```

---

## 3. Verify your `core/models.dart` has `ScheduleItem`

The results screen uses `ScheduleItem`. Check your models.dart has:
```dart
class ScheduleItem {
  final String timing;
  final String description;
  final int daysAfterSowing;
  // ... fromJson factory
}
```
And `RecommendResponse.applicationSchedule` is `List<ScheduleItem>`.

---

## 4. Route wiring in `main.dart`

The `/results` route must accept `RecommendResponse` as arguments.
In your `main.dart` routes map this should already exist from the build manual:
```dart
'/results': (ctx) => const ResultsScreen(),
```
`results_screen.dart` reads the argument with:
```dart
final RecommendResponse data =
    ModalRoute.of(context)!.settings.arguments as RecommendResponse;
```
And the wizard calls it with:
```dart
Navigator.pushNamed(context, '/results', arguments: response);
```

---

## 5. Use `SoilInputTile` in `input_wizard_screen.dart` (Page 2)

If your existing Page 2 doesn't use `SoilInputTile` yet, here's how to integrate it:

```dart
import '../widgets/soil_input_tile.dart';

// In your wizard state:
final SoilInputState _nInput = SoilInputState();
final SoilInputState _pInput = SoilInputState();
final SoilInputState _kInput = SoilInputState();

// In Page 2 body:
SoilInputTile(
  nutrientName: 'Nitrogen',
  nutrientSymbol: 'N',
  color: kColorN,
  emoji: '🌿',
  crop: _selectedCrop,           // 'maize' or 'kholar'
  state: _nInput,
  onChanged: (s) => setState(() => _nInput = s),  // NOTE: make _nInput non-final
),
SoilInputTile(
  nutrientName: 'Phosphorus',
  nutrientSymbol: 'P',           // NOTE: symbol 'P' — tile resolves P₂O₅ internally
  color: kColorP,
  emoji: '🌱',
  crop: _selectedCrop,
  state: _pInput,
  onChanged: (s) => setState(() => _pInput = s),
),
SoilInputTile(
  nutrientName: 'Potassium',
  nutrientSymbol: 'K',
  color: kColorK,
  emoji: '🌾',
  crop: _selectedCrop,
  state: _kInput,
  onChanged: (s) => setState(() => _kInput = s),
),
```

Building the request in Page 3 / submit:
```dart
final request = RecommendRequest(
  crop: _selectedCrop,
  targetYield: _selectedYield,
  nitrogenInput: SoilInput(
    mode: _nInput.mode,
    fertilityClass: _nInput.mode == 'class' ? _nInput.fertilityClass : null,
    rawValue: _nInput.rawValue,
  ),
  phosphorusInput: SoilInput(
    mode: _pInput.mode,
    fertilityClass: _pInput.mode == 'class' ? _pInput.fertilityClass : null,
    rawValue: _pInput.rawValue,
  ),
  potassiumInput: SoilInput(
    mode: _kInput.mode,
    fertilityClass: _kInput.mode == 'class' ? _kInput.fertilityClass : null,
    rawValue: _kInput.rawValue,
  ),
  landSizeAcres: _landSize,
);
```

---

## 6. Use `StepIndicator` in `input_wizard_screen.dart`

Place at the top of your PageView builder:
```dart
StepIndicator(
  currentStep: _currentPage + 1,  // PageView is 0-indexed
  totalSteps: 3,
  labels: const ['Crop', 'Soil', 'Review'],
),
```

---

## 7. Quick test after wiring

1. Start your FastAPI backend: `uvicorn backend.main:app --reload`
2. Run Flutter: `flutter run`
3. Complete the wizard with: Maize, 40 q/ha, Low N, Medium P, High K, 2 acres
4. Expected results_screen:
   - Urea: ~257 kg/ha | Total: ~208 kg for 2 acres
   - SSP:  ~285 kg/ha | Total: ~231 kg
   - MOP:  ~28.7 kg/ha | Total: ~23.2 kg
5. Tap "Why this amount?" on Nitrogen card — expandable should show the STCR equation.
6. Tap "Share Recommendation" — Android share sheet opens with a text summary.

---

## Summary of what Session 5 added

| File | What it does |
|------|-------------|
| `results_screen.dart` | Full Screen 6 with all 4 sections (banner, summary, cards, schedule, buttons) |
| `nutrient_card.dart` | Expandable N/P/K card with "Why?", equation, and schedule |
| `fertilizer_result_card.dart` | Compact at-a-glance card (used in the 3-column quick summary) |
| `app_button.dart` | Consistent button used across ALL screens |
| `step_indicator.dart` | Wizard step dots with completed/active/future states |
| `soil_input_tile.dart` | Full soil input tile (class chips OR raw value + auto-detect) |
