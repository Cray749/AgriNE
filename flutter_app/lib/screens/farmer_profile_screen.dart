/// AgriSutra NE — Farmer Profile Screen
/// ========================================
/// Accessible from the wizard AppBar via the profile icon.
/// Stores all data locally in SharedPreferences — works fully offline.
///
/// Fields:
///   - Name, Phone, Village, District (text fields)
///   - Land size in acres (slider + text)
///   - Cropping history (list of season+crop+yield entries, stored as JSON)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';
import '../core/models.dart';

class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key});

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  // Controllers
  final _nameCtrl     = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _villageCtrl  = TextEditingController();
  final _districtCtrl = TextEditingController();

  double _landSizeAcres = 1.0;
  List<CropHistoryEntry> _history = [];

  bool _isSaving = false;
  bool _loaded   = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _villageCtrl.dispose();
    _districtCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameCtrl.text     = prefs.getString('farmer_name')     ?? '';
      _phoneCtrl.text    = prefs.getString('farmer_phone')    ?? '';
      _villageCtrl.text  = prefs.getString('farmer_village')  ?? '';
      _districtCtrl.text = prefs.getString('farmer_district') ?? '';
      _landSizeAcres     = prefs.getDouble('land_size_acres') ?? 1.0;

      final histJson = prefs.getString('cropping_history_json');
      if (histJson != null) {
        try {
          final list = jsonDecode(histJson) as List<dynamic>;
          _history = list
              .map((e) => CropHistoryEntry.fromJson(e as Map<String, dynamic>))
              .toList();
        } catch (_) {
          _history = [];
        }
      }
      _loaded = true;
    });
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('farmer_name',     _nameCtrl.text.trim());
    await prefs.setString('farmer_phone',    _phoneCtrl.text.trim());
    await prefs.setString('farmer_village',  _villageCtrl.text.trim());
    await prefs.setString('farmer_district', _districtCtrl.text.trim());
    await prefs.setDouble('land_size_acres', _landSizeAcres);
    await prefs.setString(
      'cropping_history_json',
      jsonEncode(_history.map((e) => e.toJson()).toList()),
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: kGreenAccent, size: 18),
            const SizedBox(width: 10),
            Text('Profile saved!',
                style: TextStyle(fontFamily: kFontFamily, color: kTextHighlight)),
          ],
        ),
        backgroundColor: kBgCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSmall)),
      ),
    );
  }

  void _addHistoryEntry() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddHistorySheet(
        onAdd: (entry) {
          setState(() => _history.insert(0, entry));
        },
      ),
    );
  }

  void _removeHistoryEntry(int index) {
    setState(() => _history.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(      appBar: AppBar(
        title: Text('My Farm Profile', style: kStyleHeadingM),        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: kGreenAccent, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: kGreenAccent))
                : const Icon(Icons.save_rounded, color: kGreenAccent, size: 18),
            label: Text('Save',
                style: TextStyle(
                    fontFamily: kFontFamily,
                    color: kGreenAccent,
                    fontWeight: FontWeight.w600)),
            onPressed: _isSaving ? null : _saveProfile,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator(color: kGreenAccent))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: kPaddingScreen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ────────────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: kGreenPrimary.withOpacity(0.15),
                          border: Border.all(color: kGreenAccent.withOpacity(0.4), width: 2),
                        ),
                        child: const Icon(Icons.person_rounded,
                            color: kGreenAccent, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Farmer Profile',
                              style: kStyleHeadingL.copyWith(fontSize: 20)),
                          Text('Your details are stored on this device only.',
                              style: kStyleBodyM),
                        ],
                      ),
                    ],
                  ),

                  kGapXL,

                  // ── Personal Details ──────────────────────────────────────
                  _SectionHeader(title: '👤 Personal Details'),
                  kGapM,
                  _ProfileField(
                    controller: _nameCtrl,
                    label: 'Full Name',
                    icon: Icons.person_outline,
                    inputType: TextInputType.name,
                  ),
                  kGapM,
                  _ProfileField(
                    controller: _phoneCtrl,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    inputType: TextInputType.phone,
                    maxLength: 10,
                  ),

                  kGapXL,

                  // ── Location ──────────────────────────────────────────────
                  _SectionHeader(title: '📍 Location'),
                  kGapM,
                  _ProfileField(
                    controller: _villageCtrl,
                    label: 'Village / Town',
                    icon: Icons.location_on_outlined,
                    inputType: TextInputType.streetAddress,
                  ),
                  kGapM,
                  _ProfileField(
                    controller: _districtCtrl,
                    label: 'District',
                    icon: Icons.map_outlined,
                    inputType: TextInputType.streetAddress,
                  ),

                  kGapXL,

                  // ── Land Size ─────────────────────────────────────────────
                  _SectionHeader(title: '🌾 Land Size'),
                  kGapM,
                  Container(
                    padding: kPaddingCard,
                    decoration: kCardDecoration(
                        borderColor: kGreenAccent.withOpacity(0.2)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total farm area',
                                style: kStyleBodyM),
                            Text(
                              '${_landSizeAcres.toStringAsFixed(1)} acres',
                              style: kStyleValueL.copyWith(
                                  color: kGreenAccent, fontSize: 20),
                            ),
                          ],
                        ),
                        Slider(
                          value: _landSizeAcres,
                          min: 0.5,
                          max: 20.0,
                          divisions: 39,
                          label: '${_landSizeAcres.toStringAsFixed(1)} ac',
                          onChanged: (v) =>
                              setState(() => _landSizeAcres = v),
                        ),
                        Text(
                          '≈ ${(_landSizeAcres * 0.404686).toStringAsFixed(2)} hectares',
                          style: kStyleBodyM,
                        ),
                      ],
                    ),
                  ),

                  kGapXL,

                  // ── Cropping History ──────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionHeader(title: '📅 Cropping History'),
                      TextButton.icon(
                        icon: const Icon(Icons.add_circle_outline,
                            color: kGreenAccent, size: 18),
                        label: Text('Add Season',
                            style: TextStyle(
                                fontFamily: kFontFamily,
                                color: kGreenAccent,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        onPressed: _addHistoryEntry,
                      ),
                    ],
                  ),
                  kGapS,

                  if (_history.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: kCardDecoration(),
                      child: Column(
                        children: [
                          const Icon(Icons.history, color: kTextSecondary, size: 40),
                          kGapS,
                          Text('No seasons recorded yet.',
                              style: kStyleBodyM, textAlign: TextAlign.center),
                          kGapXS,
                          Text('Tap "Add Season" to track your cropping history.',
                              style: kStyleBodyM, textAlign: TextAlign.center),
                        ],
                      ),
                    )
                  else
                    ...List.generate(_history.length, (i) {
                      final entry = _history[i];
                      return _HistoryEntryCard(
                        entry: entry,
                        onDelete: () => _removeHistoryEntry(i),
                      );
                    }),

                  kGapXL,

                  // ── Save button ───────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      child: _isSaving
                          ? const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2)
                          : const Text('Save Profile'),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: TextStyle(
          fontFamily: kFontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: kTextHighlight,
        ),
      );
}

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType inputType;
  final int? maxLength;

  const _ProfileField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.inputType,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      maxLength: maxLength,
      style: TextStyle(fontFamily: kFontFamily, color: kTextPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: kGreenAccent, size: 20),
        counterText: '',
      ),
    );
  }
}

class _HistoryEntryCard extends StatelessWidget {
  final CropHistoryEntry entry;
  final VoidCallback onDelete;

  const _HistoryEntryCard({required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final Color cropColor =
        entry.crop.toLowerCase() == 'maize' ? kColorN : kColorP;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: kNutrientCardDecoration(cropColor),
      child: Row(
        children: [
          Text(
            entry.crop.toLowerCase() == 'maize' ? '🌽' : '🌿',
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.season}  ·  ${entry.crop}',
                  style: TextStyle(
                    fontFamily: kFontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cropColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Yield achieved: ${entry.yield.toStringAsFixed(1)} q/ha',
                  style: kStyleBodyM,
                ),
                if (entry.notes.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(entry.notes,
                      style: kStyleBodyM.copyWith(
                          color: kTextSecondary.withOpacity(0.7))),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: kError, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Add History Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AddHistorySheet extends StatefulWidget {
  final ValueChanged<CropHistoryEntry> onAdd;
  const _AddHistorySheet({required this.onAdd});

  @override
  State<_AddHistorySheet> createState() => _AddHistorySheetState();
}

class _AddHistorySheetState extends State<_AddHistorySheet> {
  String _selectedSeason = 'Kharif 2025';
  String _selectedCrop   = 'Maize';
  final _yieldCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  static const _seasons = [
    'Kharif 2023', 'Rabi 2023-24',
    'Kharif 2024', 'Rabi 2024-25',
    'Kharif 2025', 'Rabi 2025-26',
  ];
  static const _crops = ['Maize', 'Kholar'];

  @override
  void dispose() {
    _yieldCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPad),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: kBgCardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Add Crop Season',
                  style: kStyleHeadingM.copyWith(color: kTextHighlight)),
              IconButton(
                icon: const Icon(Icons.close, color: kTextSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          kGapM,

          // Season dropdown
          Text('Season', style: kStyleBodyM),
          kGapXS,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: kBgDark,
              borderRadius: BorderRadius.circular(kRadiusSmall),
              border: Border.all(color: kBgCardBorder),
            ),
            child: DropdownButton<String>(
              value: _selectedSeason,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              dropdownColor: kBgCard,
              style: TextStyle(
                  fontFamily: kFontFamily, color: kTextPrimary, fontSize: 15),
              items: _seasons
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedSeason = v!),
            ),
          ),

          kGapM,

          // Crop dropdown
          Text('Crop', style: kStyleBodyM),
          kGapXS,
          Row(
            children: _crops.map((c) {
              final selected = _selectedCrop == c;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: c == _crops.last ? 0 : 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCrop = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? kGreenPrimary.withOpacity(0.3)
                            : kBgDark,
                        borderRadius: BorderRadius.circular(kRadiusSmall),
                        border: Border.all(
                            color:
                                selected ? kGreenAccent : kBgCardBorder),
                      ),
                      child: Text(
                        c == 'Maize' ? '🌽  Maize' : '🌿  Kholar',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: kFontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: selected ? kGreenAccent : kTextSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          kGapM,

          // Yield achieved
          Text('Actual Yield Achieved (q/ha)', style: kStyleBodyM),
          kGapXS,
          TextField(
            controller: _yieldCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(fontFamily: kFontFamily, color: kTextPrimary),
            decoration: const InputDecoration(
              hintText: 'e.g. 38.5',
              prefixIcon:
                  Icon(Icons.track_changes_outlined, color: kGreenAccent, size: 20),
            ),
          ),

          kGapM,

          // Notes (optional)
          Text('Notes (optional)', style: kStyleBodyM),
          kGapXS,
          TextField(
            controller: _notesCtrl,
            style: TextStyle(fontFamily: kFontFamily, color: kTextPrimary),
            decoration: const InputDecoration(
              hintText: 'e.g. Good rainfall, used organic fertilizer',
              prefixIcon: Icon(Icons.notes_rounded, color: kGreenAccent, size: 20),
            ),
          ),

          kGapL,

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                final yield = double.tryParse(_yieldCtrl.text.trim());
                if (yield == null || yield <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a valid yield value.')),
                  );
                  return;
                }
                widget.onAdd(CropHistoryEntry(
                  season: _selectedSeason,
                  crop:   _selectedCrop,
                  yield:  yield,
                  notes:  _notesCtrl.text.trim(),
                ));
                Navigator.pop(context);
              },
              child: const Text('Add to History'),
            ),
          ),
        ],
      ),
    );
  }
}
