/// AgriSutra NE — Screen 5: Input Wizard
/// =========================================
/// The core input screen. Uses a PageView with 3 pages:
///
///   Page 1 — Crop & Yield:  Select Maize/Kholar, pick target yield
///   Page 2 — Soil Inputs:   N, P, K independently (class chip OR raw value)
///   Page 3 — Review:        Summary card + "Calculate" CTA → API call
///
/// Design rules (manual Part 10):
///   - PageView, NOT one long scroll — farmers get overwhelmed
///   - Step dots at the top so they always know where they are
///   - Next button disabled until required fields are filled
///   - Each nutrient (N, P, K) is INDEPENDENT — never mix their soil values
///   - SoilInputState is imported from models.dart (already defined there)
///
/// API call is in this file (_submitRequest). On success → /results with
/// the RecommendResponse as a route argument.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';
import '../core/theme_provider.dart';
import '../core/models.dart';
import '../core/api_client.dart';

class InputWizardScreen extends StatefulWidget {
  const InputWizardScreen({super.key});

  @override
  State<InputWizardScreen> createState() => _InputWizardScreenState();
}

class _InputWizardScreenState extends State<InputWizardScreen> {

  // ── PageView controller ──────────────────────────────────────────────────
  final _pageCtrl = PageController();
  int _currentPage = 0;

  // ── Page 1 state: Crop & Yield ───────────────────────────────────────────
  String? _crop;           // "maize" | "kholar"
  double? _targetYield;   // q/ha

  // ── Page 2 state: Soil inputs (one SoilInputState per nutrient) ──────────
  // SoilInputState is defined in core/models.dart — do NOT redefine here.
  final SoilInputState _nInput = SoilInputState();
  final SoilInputState _pInput = SoilInputState();
  final SoilInputState _kInput = SoilInputState();

  // ── Farmer profile (loaded from SharedPreferences) ───────────────────────
  double _landSizeAcres = 1.0;

  // ── Submission state ─────────────────────────────────────────────────────
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _landSizeAcres = prefs.getDouble('land_size_acres') ?? 1.0;
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  // ── Validation helpers ───────────────────────────────────────────────────

  bool get _page1Valid => _crop != null && _targetYield != null;

  bool get _page2Valid =>
      _nInput.isValid && _pInput.isValid && _kInput.isValid;

  // ── Navigation ───────────────────────────────────────────────────────────

  void _goToPage(int page) {
    setState(() => _currentPage = page);
    _pageCtrl.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  // ── API call ─────────────────────────────────────────────────────────────

  Future<void> _submitRequest() async {
    if (!_page1Valid || !_page2Valid) return;
    setState(() => _isLoading = true);

    try {
      final request = RecommendRequest(
        crop:             _crop!,
        targetYield:      _targetYield!,
        nitrogenInput:    _nInput.toSoilInput(),
        phosphorusInput:  _pInput.toSoilInput(),
        potassiumInput:   _kInput.toSoilInput(),
        landSizeAcres:    _landSizeAcres,
      );

      final response = await ApiClient.instance.getRecommendation(request);

      if (!mounted) return;
      Navigator.pushNamed(context, '/results', arguments: response);

    } on ApiException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      _showError('Something went wrong. Please try again.\n${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kBgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusCard)),
        title: Row(children: [
          const Icon(Icons.error_outline, color: kError, size: 22),
          const SizedBox(width: 8),
          Text('Error', style: kStyleHeadingM.copyWith(color: kError)),
        ]),
        content: Text(message, style: kStyleBodyM),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: kStyleBodyM.copyWith(color: kGreenAccent)),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(      appBar: AppBar(
        title: Text('Fertilizer Wizard', style: kStyleHeadingM),        elevation: 0,
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kGreenAccent, size: 20),
                onPressed: () => _goToPage(_currentPage - 1),
              )
            : null,
        actions: [
          // Theme toggle
          IconButton(
            icon: Icon(
              context.watch<ThemeProvider>().isDark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              color: ctxAccent(context),
              size: 22,
            ),
            tooltip: 'Toggle theme',
            onPressed: () => context.read<ThemeProvider>().toggle(),
          ),
          // Farmer profile
          IconButton(
            icon: Icon(Icons.account_circle_outlined,
                color: ctxAccent(context), size: 22),
            tooltip: 'My Profile',
            onPressed: () => Navigator.pushNamed(context, '/farmer_profile'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Step dot indicator
          _StepDots(currentPage: _currentPage, totalPages: 3),

          // PageView (swipe disabled — navigation only via buttons)
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (p) => setState(() => _currentPage = p),
              children: [
                _Page1CropYield(
                  selectedCrop:  _crop,
                  selectedYield: _targetYield,
                  onCropChanged:  (c) => setState(() { _crop = c; _targetYield = null; }),
                  onYieldChanged: (y) => setState(() => _targetYield = y),
                  onNext: _page1Valid ? () => _goToPage(1) : null,
                ),
                _Page2SoilInput(
                  crop:   _crop ?? 'maize',
                  nInput: _nInput,
                  pInput: _pInput,
                  kInput: _kInput,
                  onChanged: () => setState(() {}),
                  onBack: () => _goToPage(0),
                  onNext: _page2Valid ? () => _goToPage(2) : null,
                ),
                _Page3Review(
                  crop:          _crop         ?? '',
                  targetYield:   _targetYield  ?? 0,
                  landSizeAcres: _landSizeAcres,
                  nInput:        _nInput,
                  pInput:        _pInput,
                  kInput:        _kInput,
                  isLoading:     _isLoading,
                  onBack:        () => _goToPage(1),
                  onSubmit:      _submitRequest,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ════════════════════════════════════════════════════════════════════════════
//  PAGE 1 — CROP & YIELD
// ════════════════════════════════════════════════════════════════════════════

class _Page1CropYield extends StatelessWidget {
  final String? selectedCrop;
  final double? selectedYield;
  final ValueChanged<String>  onCropChanged;
  final ValueChanged<double>  onYieldChanged;
  final VoidCallback?         onNext;

  const _Page1CropYield({
    required this.selectedCrop,
    required this.selectedYield,
    required this.onCropChanged,
    required this.onYieldChanged,
    required this.onNext,
  });

  static const _yieldOptions = {
    'maize':  [40.0, 50.0],
    'kholar': [8.0, 10.0],
  };

  @override
  Widget build(BuildContext context) {
    final yields = _yieldOptions[selectedCrop] ?? [];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: kPaddingScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          kGapM,
          Text('What are you growing?', style: kStyleHeadingL),
          kGapS,
          Text(
            'Select your crop to get the right STCR formula.',
            style: kStyleBodyM,
          ),
          kGapL,

          // ── Two crop tap-cards ─────────────────────────────────────────
          Row(
            children: [
              Expanded(child: _CropCard(
                emoji:    '🌽',
                name:     'Maize',
                subtitle: 'Local / Hybrid',
                value:    'maize',
                selected: selectedCrop == 'maize',
                onTap:    () => onCropChanged('maize'),
              )),
              kGapHorizontalM,
              Expanded(child: _CropCard(
                emoji:    '🌿',
                name:     'Kholar',
                subtitle: 'Legume',
                value:    'kholar',
                selected: selectedCrop == 'kholar',
                onTap:    () => onCropChanged('kholar'),
              )),
            ],
          ),

          // ── Yield selection (appears after crop picked) ───────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            child: selectedCrop == null
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      kGapXL,
                      Text('What yield are you aiming for?', style: kStyleHeadingM),
                      kGapS,
                      Text('q/ha = quintals per hectare', style: kStyleBodyM),
                      kGapM,
                      Row(
                        children: yields.map((y) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: y == yields.last ? 0 : 12,
                            ),
                            child: _YieldChip(
                              label:    '${y.toInt()} q/ha',
                              selected: selectedYield == y,
                              onTap:    () => onYieldChanged(y),
                            ),
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
          ),

          kGapXL,

          // ── Next button ───────────────────────────────────────────────
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: onNext != null ? kGreenPrimary : kBgCard,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Next: Enter Soil Data',
                    style: kStyleHeadingM.copyWith(
                      color: onNext != null ? kTextHighlight : kTextSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: onNext != null ? kTextHighlight : kTextSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}


// ════════════════════════════════════════════════════════════════════════════
//  PAGE 2 — SOIL NUTRIENT INPUT
// ════════════════════════════════════════════════════════════════════════════

class _Page2SoilInput extends StatelessWidget {
  final String         crop;
  final SoilInputState nInput, pInput, kInput;
  final VoidCallback   onChanged, onBack;
  final VoidCallback?  onNext;

  const _Page2SoilInput({
    required this.crop,
    required this.nInput,
    required this.pInput,
    required this.kInput,
    required this.onChanged,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: kPaddingScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          kGapM,
          Text('Tell us about your soil', style: kStyleHeadingL),
          kGapS,
          Text(
            'Each nutrient is assessed separately — this is the scientific way.',
            style: kStyleBodyM,
          ),

          kGapL,

          // Three independent nutrient cards
          _NutrientInputCard(
            nutrientLabel: 'Nitrogen',
            symbol:        'N',
            emoji:         '🌿',
            accentColor:   kColorN,
            rangeHint:     'Typical: 150–400 kg/ha',
            lowLabel:      '< 225',
            medLabel:      '225–500',
            highLabel:     '> 500',
            state:         nInput,
            crop:          crop,
            nutrientKey:   'N',
            onChanged:     onChanged,
          ),

          kGapM,

          _NutrientInputCard(
            nutrientLabel: 'Phosphorus',
            symbol:        'P₂O₅',
            emoji:         '🔵',
            accentColor:   kColorP,
            rangeHint:     'Typical: 10–35 kg/ha',
            lowLabel:      '< 22',
            medLabel:      '22–55',
            highLabel:     '> 55',
            state:         pInput,
            crop:          crop,
            nutrientKey:   'P',
            onChanged:     onChanged,
          ),

          kGapM,

          _NutrientInputCard(
            nutrientLabel: 'Potassium',
            symbol:        'K₂O',
            emoji:         '🟡',
            accentColor:   kColorK,
            rangeHint:     'Typical: 100–300 kg/ha',
            lowLabel:      '< 137',
            medLabel:      '137–337',
            highLabel:     '> 337',
            state:         kInput,
            crop:          crop,
            nutrientKey:   'K',
            onChanged:     onChanged,
          ),

          kGapXL,

          // Back / Next row
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back_rounded, size: 18),
                      SizedBox(width: 6),
                      Text('Back'),
                    ],
                  ),
                ),
              ),
              kGapHorizontalM,
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: onNext != null ? kGreenPrimary : kBgCard,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Review & Submit',
                          style: kStyleHeadingM.copyWith(
                            color: onNext != null ? kTextHighlight : kTextSecondary,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded,
                          color: onNext != null ? kTextHighlight : kTextSecondary, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}


// ════════════════════════════════════════════════════════════════════════════
//  PAGE 3 — REVIEW & SUBMIT
// ════════════════════════════════════════════════════════════════════════════

class _Page3Review extends StatelessWidget {
  final String         crop;
  final double         targetYield, landSizeAcres;
  final SoilInputState nInput, pInput, kInput;
  final bool           isLoading;
  final VoidCallback   onBack, onSubmit;

  const _Page3Review({
    required this.crop,
    required this.targetYield,
    required this.landSizeAcres,
    required this.nInput,
    required this.pInput,
    required this.kInput,
    required this.isLoading,
    required this.onBack,
    required this.onSubmit,
  });

  String _inputLabel(SoilInputState s, String nutrientKey, String cropName) {
    if (s.mode == 'class') return s.fertilityClass.toUpperCase();
    final detected = s.detectClass(cropName, nutrientKey);
    return 'Raw: ${s.rawValue?.toStringAsFixed(0)} kg/ha  (${detected.toUpperCase()})';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildLoadingState();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: kPaddingScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          kGapM,
          Text('Review & Confirm', style: kStyleHeadingL),
          kGapS,
          Text(
            'Check your inputs before we calculate.',
            style: kStyleBodyM,
          ),

          kGapL,

          // ── Summary card ───────────────────────────────────────────────
          Container(
            padding: kPaddingCard,
            decoration: kCardDecoration(borderColor: kGreenAccent.withOpacity(0.3)),
            child: Column(
              children: [
                // Top two rows
                Row(
                  children: [
                    Expanded(child: _SummaryCell(
                      icon: Icons.grass_outlined,
                      label: 'Crop',
                      value: crop == 'maize' ? 'Maize 🌽' : 'Kholar 🌿',
                    )),
                    Container(width: 1, height: 50, color: kBgCardBorder),
                    Expanded(child: _SummaryCell(
                      icon: Icons.track_changes_outlined,
                      label: 'Target Yield',
                      value: '${targetYield.toInt()} q/ha',
                    )),
                  ],
                ),

                const Divider(color: kBgCardBorder, height: 20),

                _SummaryCell(
                  icon: Icons.crop_square_outlined,
                  label: 'Land Size',
                  value: '${landSizeAcres.toStringAsFixed(1)} acres'
                         ' (${(landSizeAcres * 0.404686).toStringAsFixed(2)} ha)',
                  fullWidth: true,
                ),

                const Divider(color: kBgCardBorder, height: 20),

                // Nutrient rows
                _NutrientSummaryRow(
                  color: kColorN, label: 'Nitrogen',
                  value: _inputLabel(nInput, 'N', crop),
                ),
                kGapS,
                _NutrientSummaryRow(
                  color: kColorP, label: 'Phosphorus',
                  value: _inputLabel(pInput, 'P', crop),
                ),
                kGapS,
                _NutrientSummaryRow(
                  color: kColorK, label: 'Potassium',
                  value: _inputLabel(kInput, 'K', crop),
                ),
              ],
            ),
          ),

          kGapXL,

          // ── Calculate CTA ──────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              onPressed: onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreenPrimary,
                elevation: 6,
                shadowColor: kGreenPrimary.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kRadiusButton),
                ),
              ),
              child: Text(
                '🔬  Calculate My Fertilizer Dose',
                style: kStyleHeadingM.copyWith(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          kGapM,

          // Back link
          Center(
            child: TextButton(
              onPressed: onBack,
              child: Text(
                '← Edit soil inputs',
                style: kStyleBodyM.copyWith(color: kGreenAccent),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Loading state — shown while API call is in progress
  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: kPaddingScreen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Continuously spinning leaf
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 6.28318), // 2π — full rotation
              duration: const Duration(seconds: 2),
              builder: (ctx, val, child) => Transform.rotate(
                angle: val,
                child: child,
              ),
              onEnd: () {},
              child: const Icon(Icons.eco_rounded, color: kGreenAccent, size: 64),
            ),
            kGapL,
            Text('Calculating your prescription…', style: kStyleHeadingM,
                textAlign: TextAlign.center),
            kGapS,
            const _AnimatedDots(),
            kGapL,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: kGreenPrimary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(kRadiusSmall),
                border: Border.all(color: kGreenAccent.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline, color: kGreenAccent, size: 16),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'First request may take up to 60 seconds\nwhile the server wakes up. Please wait ⏳',
                      style: kStyleBodyM,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ════════════════════════════════════════════════════════════════════════════
//  NUTRIENT INPUT CARD
//  One of these for N, P, K — completely independent state
// ════════════════════════════════════════════════════════════════════════════

class _NutrientInputCard extends StatefulWidget {
  final String         nutrientLabel, symbol, emoji, rangeHint;
  final String         lowLabel, medLabel, highLabel;
  final Color          accentColor;
  final SoilInputState state;
  final String         crop, nutrientKey;
  final VoidCallback   onChanged;

  const _NutrientInputCard({
    required this.nutrientLabel,
    required this.symbol,
    required this.emoji,
    required this.accentColor,
    required this.rangeHint,
    required this.lowLabel,
    required this.medLabel,
    required this.highLabel,
    required this.state,
    required this.crop,
    required this.nutrientKey,
    required this.onChanged,
  });

  @override
  State<_NutrientInputCard> createState() => _NutrientInputCardState();
}

class _NutrientInputCardState extends State<_NutrientInputCard> {
  final _valueCtrl  = TextEditingController();
  final _valueFocus = FocusNode();

  @override
  void dispose() {
    _valueCtrl.dispose();
    _valueFocus.dispose();
    super.dispose();
  }

  void _setMode(String mode) {
    setState(() => widget.state.mode = mode);
    widget.onChanged();
    if (mode == 'value') {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _valueFocus.requestFocus();
      });
    }
  }

  void _setClass(String fc) {
    setState(() => widget.state.fertilityClass = fc);
    widget.onChanged();
  }

  void _onValueChanged(String raw) {
    final val = double.tryParse(raw);
    setState(() => widget.state.rawValue = val);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final isValueMode = widget.state.mode == 'value';

    return Container(
      decoration: kNutrientCardDecoration(widget.accentColor),
      padding: kPaddingCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Card header ─────────────────────────────────────────────────
          Row(
            children: [
              Text(widget.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.nutrientLabel,
                    style: kStyleHeadingM.copyWith(color: widget.accentColor),
                  ),
                  Text(widget.symbol, style: kStyleLabel),
                ],
              ),
            ],
          ),

          kGapM,

          // ── Mode toggle ─────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: kBgDark,
              borderRadius: BorderRadius.circular(kRadiusSmall),
            ),
            child: Row(
              children: [
                _ModeToggleBtn(
                  label:    'No Test Report',
                  selected: !isValueMode,
                  onTap:    () => _setMode('class'),
                ),
                _ModeToggleBtn(
                  label:    'I Have Test Values',
                  selected: isValueMode,
                  onTap:    () => _setMode('value'),
                ),
              ],
            ),
          ),

          kGapM,

          // ── Class chips OR raw value field ──────────────────────────────
          if (!isValueMode) ...[
            Text(
              'How fertile is your soil\'s ${widget.nutrientLabel}?',
              style: kStyleBodyM,
            ),
            kGapM,
            Row(
              children: [
                Expanded(child: _FertilityChip(
                  label: '🔴 LOW',
                  range: widget.lowLabel,
                  unit:  'kg/ha',
                  color: kFertilityLow,
                  selected: widget.state.fertilityClass == 'low',
                  onTap: () => _setClass('low'),
                )),
                const SizedBox(width: 8),
                Expanded(child: _FertilityChip(
                  label: '🟡 MED',
                  range: widget.medLabel,
                  unit:  'kg/ha',
                  color: kFertilityMedium,
                  selected: widget.state.fertilityClass == 'medium',
                  onTap: () => _setClass('medium'),
                )),
                const SizedBox(width: 8),
                Expanded(child: _FertilityChip(
                  label: '🟢 HIGH',
                  range: widget.highLabel,
                  unit:  'kg/ha',
                  color: kFertilityHigh,
                  selected: widget.state.fertilityClass == 'high',
                  onTap: () => _setClass('high'),
                )),
              ],
            ),
          ] else ...[
            TextField(
              controller:   _valueCtrl,
              focusNode:    _valueFocus,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              style: kStyleBodyL.copyWith(color: kTextHighlight),
              onChanged: _onValueChanged,
              decoration: InputDecoration(
                labelText: 'Soil ${widget.nutrientLabel} value (kg/ha)',
                hintText:  widget.rangeHint,
                suffixText: 'kg/ha',
                suffixStyle: kStyleBodyM,
              ),
            ),

            // Auto-detected class display
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              child: widget.state.rawValue != null
                  ? Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, size: 14, color: kGreenAccent),
                          const SizedBox(width: 6),
                          Text('Detected: ', style: kStyleBodyM),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: fertilityClassColor(
                                widget.state.detectClass(widget.crop, widget.nutrientKey)
                              ).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(kRadiusChip),
                              border: Border.all(
                                color: fertilityClassColor(
                                  widget.state.detectClass(widget.crop, widget.nutrientKey)
                                ),
                              ),
                            ),
                            child: Text(
                              widget.state.detectClass(widget.crop, widget.nutrientKey).toUpperCase(),
                              style: kStyleLabel.copyWith(
                                color: fertilityClassColor(
                                  widget.state.detectClass(widget.crop, widget.nutrientKey)
                                ),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ],
      ),
    );
  }
}


// ════════════════════════════════════════════════════════════════════════════
//  SMALL REUSABLE WIDGETS
// ════════════════════════════════════════════════════════════════════════════

/// Large tap-card for crop selection (Page 1)
class _CropCard extends StatelessWidget {
  final String emoji, name, subtitle, value;
  final bool selected;
  final VoidCallback onTap;

  const _CropCard({
    required this.emoji,
    required this.name,
    required this.subtitle,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? kGreenPrimary.withOpacity(0.18) : kBgCard,
          borderRadius: BorderRadius.circular(kRadiusCard),
          border: Border.all(
            color: selected ? kGreenAccent : kBgCardBorder,
            width: selected ? 2.0 : 1.2,
          ),
          boxShadow: selected
              ? [BoxShadow(color: kGreenAccent.withOpacity(0.2), blurRadius: 12)]
              : [],
        ),
        child: Column(
          children: [
            AnimatedScale(
              scale: selected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 220),
              child: Text(emoji, style: const TextStyle(fontSize: 40)),
            ),
            kGapS,
            Text(
              name,
              style: kStyleHeadingM.copyWith(
                color: selected ? kGreenAccent : kTextHighlight,
              ),
              textAlign: TextAlign.center,
            ),
            kGapXS,
            Text(subtitle, style: kStyleLabel, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Yield chip button (Page 1)
class _YieldChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _YieldChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          color: selected ? kGreenPrimary : kBgCard,
          borderRadius: BorderRadius.circular(kRadiusButton),
          border: Border.all(
            color: selected ? kGreenAccent : kBgCardBorder,
            width: selected ? 2 : 1.2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: kStyleBodyL.copyWith(
            color: selected ? kTextHighlight : kTextSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

/// Mode toggle button inside a NutrientInputCard
class _ModeToggleBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeToggleBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? kGreenPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(kRadiusSmall - 2),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: kStyleLabel.copyWith(
              color: selected ? kTextHighlight : kTextSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Fertility class chip (LOW / MED / HIGH)
class _FertilityChip extends StatelessWidget {
  final String label, range, unit;
  final Color  color;
  final bool   selected;
  final VoidCallback onTap;

  const _FertilityChip({
    required this.label,
    required this.range,
    required this.unit,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.18) : kBgDark,
          borderRadius: BorderRadius.circular(kRadiusSmall),
          border: Border.all(
            color: selected ? color : kBgCardBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: kStyleLabel.copyWith(
                color: selected ? color : kTextSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 3),
            Text(
              range,
              style: kStyleLabel.copyWith(fontSize: 10, color: kTextSecondary),
              textAlign: TextAlign.center,
            ),
            Text(
              unit,
              style: kStyleLabel.copyWith(fontSize: 9, color: kTextSecondary.withOpacity(0.6)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Summary review cell (Page 3)
class _SummaryCell extends StatelessWidget {
  final IconData icon;
  final String   label, value;
  final bool     fullWidth;
  const _SummaryCell({required this.icon, required this.label, required this.value, this.fullWidth = false});

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: fullWidth ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: fullWidth ? MainAxisSize.min : MainAxisSize.max,
            mainAxisAlignment: fullWidth ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: kTextSecondary),
              const SizedBox(width: 5),
              Text(label, style: kStyleLabel),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: kStyleBodyM.copyWith(color: kTextHighlight, fontWeight: FontWeight.w600),
            textAlign: fullWidth ? TextAlign.start : TextAlign.center,
          ),
        ],
      ),
    );
    return fullWidth ? child : child;
  }
}

/// Nutrient summary row in the review card
class _NutrientSummaryRow extends StatelessWidget {
  final Color  color;
  final String label, value;
  const _NutrientSummaryRow({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 10),
        Text('$label:', style: kStyleBodyM),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            value,
            style: kStyleBodyM.copyWith(color: kTextHighlight, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// Animated "..." dots shown on the loading page
class _AnimatedDots extends StatefulWidget {
  const _AnimatedDots();
  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  int _dotCount = 1;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          setState(() => _dotCount = _dotCount == 3 ? 1 : _dotCount + 1);
          _ctrl.forward(from: 0);
        }
      })
      ..forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Text(
      '.' * _dotCount,
      style: kStyleHeadingL.copyWith(color: kGreenAccent, letterSpacing: 4),
    );
  }
}

/// Step dots indicator at the top of the wizard
class _StepDots extends StatelessWidget {
  final int currentPage, totalPages;
  const _StepDots({required this.currentPage, required this.totalPages});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalPages, (i) {
          final active = i == currentPage;
          final done   = i < currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width:  active ? 28 : 10,
            height: 10,
            decoration: BoxDecoration(
              color: active
                  ? kGreenAccent
                  : done
                      ? kGreenPrimary
                      : kBgCardBorder,
              borderRadius: BorderRadius.circular(5),
            ),
          );
        }),
      ),
    );
  }
}
