/// AgriSutra NE — Screen 4: Profile Setup
/// ==========================================
/// Shown ONCE after first login. Collects:
///   - Farmer name  (free text, min 2 chars)
///   - District     (dropdown, 10 NE options)
///   - Land size    (slider 0.5–10.0 acres, step 0.5)
///
/// All data is saved to SharedPreferences with these exact keys:
///   'farmer_name'      → String
///   'farmer_district'  → String
///   'land_size_acres'  → double
///
/// These keys are read by:
///   - splash_screen.dart  → hasProfile routing check
///   - input_wizard_screen → default land_size_acres for the request
///
/// Routing: On save → /wizard (replaces the stack so Back cannot return here)

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen>
    with SingleTickerProviderStateMixin {

  // ── Form state ───────────────────────────────────────────────────────────
  final _formKey        = GlobalKey<FormState>();
  final _nameCtrl       = TextEditingController();
  final _nameFocus      = FocusNode();
  String _district      = 'Kiphire';   // Default: most target farmers are here
  double _landSize      = 2.0;          // Default: 2 acres (typical smallholder)
  bool   _isSaving      = false;

  // Conversion constant from theme/models
  static const double _acresToHa = 0.404686;

  // ── Districts (manual, Part 10, Screen 4) ───────────────────────────────
  static const List<String> _districts = [
    'Kiphire', 'Phek', 'Kohima', 'Wokha', 'Dimapur',
    'Kamrup', 'Barpeta', 'Nagaon', 'Golaghat', 'Other',
  ];

  // ── Entry animation ──────────────────────────────────────────────────────
  late final AnimationController _entryCtrl;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fade  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameFocus.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── Save & navigate ──────────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('farmer_name',     _nameCtrl.text.trim());
    await prefs.setString('farmer_district', _district);
    await prefs.setDouble('land_size_acres', _landSize);

    if (!mounted) return;
    // pushReplacement so Back cannot return to setup
    Navigator.pushReplacementNamed(context, '/wizard');
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      appBar: AppBar(
        title: Text('Your Profile', style: kStyleHeadingM),
        backgroundColor: kBgDark,
        elevation: 0,
        // No back button — this is part of the one-way onboarding flow
        automaticallyImplyLeading: false,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: kPaddingScreen,
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Progress indicator (step 1 of multi-step onboarding) ─
                    _OnboardingStepBadge(step: 1, total: 2, label: 'Profile Setup'),

                    kGapL,

                    // ── Step header ──────────────────────────────────────────
                    Text('Tell us about yourself', style: kStyleHeadingL),
                    kGapS,
                    Text(
                      'We personalise recommendations for your land and location.',
                      style: kStyleBodyM,
                    ),

                    kGapXL,

                    // ── Field 1: Name ────────────────────────────────────────
                    _SectionLabel(label: '👤  Your Name'),
                    kGapS,
                    TextFormField(
                      controller:     _nameCtrl,
                      focusNode:      _nameFocus,
                      textCapitalization: TextCapitalization.words,
                      textInputAction:    TextInputAction.done,
                      style: kStyleBodyL.copyWith(
                        fontSize: 20,
                        color: kTextHighlight,
                      ),
                      onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Ranjit Kumar',
                        prefixIcon: Icon(Icons.person_outline, color: kGreenAccent),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().length < 2) {
                          return 'Please enter your name (at least 2 characters)';
                        }
                        return null;
                      },
                    ),

                    kGapXL,

                    // ── Field 2: District ────────────────────────────────────
                    _SectionLabel(label: '📍  Your District'),
                    kGapS,
                    _DistrictDropdown(
                      value:     _district,
                      districts: _districts,
                      onChanged: (val) { if (val != null) setState(() => _district = val); },
                    ),

                    kGapXL,

                    // ── Field 3: Land size slider ────────────────────────────
                    _SectionLabel(label: '🌾  How much land do you farm?'),
                    kGapM,
                    _LandSizeSlider(
                      value:     _landSize,
                      onChanged: (val) => setState(() => _landSize = val),
                    ),

                    kGapXL,

                    // ── Profile preview card ─────────────────────────────────
                    _ProfilePreviewCard(
                      name:     _nameCtrl.text.isEmpty ? 'Your name' : _nameCtrl.text.trim(),
                      district: _district,
                      acres:    _landSize,
                    ),

                    kGapXL,

                    // ── Save button ──────────────────────────────────────────
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        child: _isSaving
                            ? const SizedBox(
                                width: 24, height: 24,
                                child: CircularProgressIndicator(
                                  color: kTextHighlight, strokeWidth: 2.5),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Save & Start'),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 20),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// ════════════════════════════════════════════════════════════════════════════
//  DISTRICT DROPDOWN  — card-like row with arrow icon
// ════════════════════════════════════════════════════════════════════════════

class _DistrictDropdown extends StatelessWidget {
  final String value;
  final List<String> districts;
  final ValueChanged<String?> onChanged;

  const _DistrictDropdown({
    required this.value,
    required this.districts,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: kCardDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: kBgCard,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: kGreenAccent),
          style: kStyleBodyL.copyWith(color: kTextHighlight, fontSize: 18),
          items: districts.map((d) => DropdownMenuItem(
            value: d,
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, color: kGreenAccent, size: 18),
                const SizedBox(width: 10),
                Text(d),
              ],
            ),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}


// ════════════════════════════════════════════════════════════════════════════
//  LAND SIZE SLIDER
// ════════════════════════════════════════════════════════════════════════════

class _LandSizeSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  static const double _acresToHa = 0.404686;

  const _LandSizeSlider({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final ha = (value * _acresToHa);
    return Column(
      children: [
        // Live display card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: kNutrientCardDecoration(kGreenAccent),
          child: Column(
            children: [
              Text(
                '${value.toStringAsFixed(1)} Acres',
                style: kStyleValueL.copyWith(color: kGreenAccent, fontSize: 32),
              ),
              kGapXS,
              Text(
                '= ${ha.toStringAsFixed(2)} hectares',
                style: kStyleLabel,
              ),
            ],
          ),
        ),

        kGapM,

        // Slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
            valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
            valueIndicatorTextStyle: kStyleBodyM.copyWith(color: kTextHighlight),
          ),
          child: Slider(
            value: value,
            min: 0.5,
            max: 10.0,
            divisions: 19,
            label: '${value.toStringAsFixed(1)} ac',
            onChanged: onChanged,
          ),
        ),

        // Min/max labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0.5 acres', style: kStyleLabel),
              Text('10.0 acres', style: kStyleLabel),
            ],
          ),
        ),
      ],
    );
  }
}


// ════════════════════════════════════════════════════════════════════════════
//  PROFILE PREVIEW CARD  — live preview of what will be saved
// ════════════════════════════════════════════════════════════════════════════

class _ProfilePreviewCard extends StatelessWidget {
  final String name, district;
  final double acres;
  static const double _acresToHa = 0.404686;

  const _ProfilePreviewCard({
    required this.name,
    required this.district,
    required this.acres,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: kPaddingCard,
      decoration: kCardDecoration(borderColor: kGreenPrimary.withOpacity(0.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.preview_outlined, color: kGreenAccent, size: 16),
              const SizedBox(width: 6),
              Text('Profile Preview', style: kStyleLabel.copyWith(color: kGreenAccent)),
            ],
          ),
          const Divider(color: kBgCardBorder, height: 20),
          _PreviewRow(icon: Icons.person_outline,     label: 'Name',     value: name),
          kGapS,
          _PreviewRow(icon: Icons.location_on_outlined, label: 'District', value: district),
          kGapS,
          _PreviewRow(
            icon:  Icons.crop_square_outlined,
            label: 'Land',
            value: '${acres.toStringAsFixed(1)} acres'
                   ' (${(acres * _acresToHa).toStringAsFixed(2)} ha)',
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final IconData icon;
  final String   label, value;
  const _PreviewRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: kTextSecondary, size: 16),
        const SizedBox(width: 8),
        Text('$label: ', style: kStyleBodyM),
        Flexible(
          child: Text(
            value,
            style: kStyleBodyM.copyWith(color: kTextHighlight, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}


// ════════════════════════════════════════════════════════════════════════════
//  SHARED SMALL WIDGETS
// ════════════════════════════════════════════════════════════════════════════

/// Onboarding step badge — "Step 1 of 2 · Profile Setup"
class _OnboardingStepBadge extends StatelessWidget {
  final int step, total;
  final String label;
  const _OnboardingStepBadge({required this.step, required this.total, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: kGreenPrimary.withOpacity(0.18),
            borderRadius: BorderRadius.circular(kRadiusChip),
            border: Border.all(color: kGreenPrimary.withOpacity(0.4)),
          ),
          child: Text(
            'Step $step of $total  ·  $label',
            style: kStyleLabel.copyWith(color: kGreenAccent),
          ),
        ),
      ],
    );
  }
}

/// Bold section label above a form field
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label, style: kStyleBodyL.copyWith(fontWeight: FontWeight.w600));
  }
}
