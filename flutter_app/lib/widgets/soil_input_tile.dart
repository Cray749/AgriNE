// lib/widgets/soil_input_tile.dart
// ─────────────────────────────────────────────────────────────────────────────
// AgriSutra NE — Soil Input Tile Widget
// Used on input_wizard_screen.dart Page 2 for each of N, P, K.
// Handles the toggle between "Class mode" (Low/Med/High chips)
// and "Value mode" (raw number entry with auto-detect).
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';

/// Holds state for one nutrient's soil input.
class SoilInputState {
  String mode;           // "class" or "value"
  String fertilityClass; // "low", "medium", "high"
  double? rawValue;

  SoilInputState({
    this.mode = 'class',
    this.fertilityClass = 'medium',
    this.rawValue,
  });

  /// Converts to a JSON map matching the backend SoilInput schema.
  Map<String, dynamic> toJson() {
    if (mode == 'class') {
      return {'mode': 'class', 'fertility_class': fertilityClass};
    } else {
      return {'mode': 'value', 'raw_value': rawValue};
    }
  }
}

class SoilInputTile extends StatefulWidget {
  final String nutrientName;   // "Nitrogen"
  final String nutrientSymbol; // "N"
  final Color color;
  final String emoji;          // "🌿"
  final String crop;           // needed for threshold hints
  final SoilInputState state;
  final ValueChanged<SoilInputState> onChanged;

  const SoilInputTile({
    super.key,
    required this.nutrientName,
    required this.nutrientSymbol,
    required this.color,
    required this.emoji,
    required this.crop,
    required this.state,
    required this.onChanged,
  });

  @override
  State<SoilInputTile> createState() => _SoilInputTileState();
}

class _SoilInputTileState extends State<SoilInputTile> {
  late TextEditingController _valueCtrl;
  String? _detectedClass;

  @override
  void initState() {
    super.initState();
    _valueCtrl = TextEditingController(
      text: widget.state.rawValue?.toString() ?? '',
    );
    if (widget.state.mode == 'value' && widget.state.rawValue != null) {
      _detectedClass = _resolveClass(widget.state.rawValue!);
    }
  }

  @override
  void dispose() {
    _valueCtrl.dispose();
    super.dispose();
  }

  // ── Thresholds (matches fpe_engine.py exactly) ────────────────────────────
  String _resolveClass(double val) {
    final sym = widget.nutrientSymbol;
    final crop = widget.crop.toLowerCase();

    if (sym == 'N') {
      if (crop.contains('kholar')) {
        return val < 225 ? 'low' : (val > 450 ? 'high' : 'medium');
      }
      return val < 225 ? 'low' : (val > 500 ? 'high' : 'medium');
    } else if (sym == 'P') {
      return val < 22 ? 'low' : (val > 55 ? 'high' : 'medium');
    } else {
      // K
      return val < 137 ? 'low' : (val > 337 ? 'high' : 'medium');
    }
  }

  String _thresholdHint() {
    final sym = widget.nutrientSymbol;
    final crop = widget.crop.toLowerCase();
    if (sym == 'N') {
      return crop.contains('kholar')
          ? 'Low <225 | Medium 225–450 | High >450 kg/ha'
          : 'Low <225 | Medium 225–500 | High >500 kg/ha';
    } else if (sym == 'P') {
      return 'Low <22 | Medium 22–55 | High >55 kg/ha';
    } else {
      return 'Low <137 | Medium 137–337 | High >337 kg/ha';
    }
  }

  void _onValueChanged(String val) {
    final double? parsed = double.tryParse(val);
    setState(() {
      if (parsed != null) {
        _detectedClass = _resolveClass(parsed);
      } else {
        _detectedClass = null;
      }
    });
    final updated = SoilInputState(
      mode: 'value',
      fertilityClass: _detectedClass ?? 'medium',
      rawValue: parsed,
    );
    widget.onChanged(updated);
  }

  void _onModeToggle(bool useValue) {
    setState(() {
      _detectedClass = null;
      _valueCtrl.clear();
    });
    widget.onChanged(SoilInputState(
      mode: useValue ? 'value' : 'class',
      fertilityClass: widget.state.fertilityClass,
      rawValue: null,
    ));
  }

  void _onClassSelected(String fc) {
    widget.onChanged(SoilInputState(
      mode: 'class',
      fertilityClass: fc,
      rawValue: null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bool isValueMode = widget.state.mode == 'value';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(
          color: widget.color.withOpacity(0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────────────
          Row(
            children: [
              Text(widget.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text(
                widget.nutrientName,
                style: TextStyle(
                  fontFamily: kFontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: widget.color,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${widget.nutrientSymbol})',
                style: TextStyle(
                  fontFamily: kFontFamily,
                  fontSize: 13,
                  color: kTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Mode toggle ──────────────────────────────────────────────────
          Row(
            children: [
              Text(
                'Do you have a soil test report?',
                style: TextStyle(
                  fontFamily: kFontFamily,
                  fontSize: 13,
                  color: kTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: kBgDark,
              borderRadius: BorderRadius.circular(kRadiusButton),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onModeToggle(false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !isValueMode
                            ? widget.color.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(kRadiusButton),
                        border: !isValueMode
                            ? Border.all(
                                color: widget.color.withOpacity(0.5), width: 1)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          'No Test Report',
                          style: TextStyle(
                            fontFamily: kFontFamily,
                            fontSize: 13,
                            fontWeight: !isValueMode
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color:
                                !isValueMode ? widget.color : kTextSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onModeToggle(true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isValueMode
                            ? widget.color.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(kRadiusButton),
                        border: isValueMode
                            ? Border.all(
                                color: widget.color.withOpacity(0.5), width: 1)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          'I Have Values',
                          style: TextStyle(
                            fontFamily: kFontFamily,
                            fontSize: 13,
                            fontWeight: isValueMode
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color:
                                isValueMode ? widget.color : kTextSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Class mode: 3 chips ──────────────────────────────────────────
          if (!isValueMode) _buildClassChips(),

          // ── Value mode: text field ───────────────────────────────────────
          if (isValueMode) _buildValueInput(),
        ],
      ),
    );
  }

  Widget _buildClassChips() {
    final chips = [
      {'fc': 'low', 'label': '🔴 LOW', 'color': kError},
      {'fc': 'medium', 'label': '🟡 MED', 'color': kWarning},
      {'fc': 'high', 'label': '🟢 HIGH', 'color': kSuccess},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How fertile is your soil\'s ${widget.nutrientName}?',
          style: TextStyle(
            fontFamily: kFontFamily,
            fontSize: 13,
            color: kTextSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: chips.map((chip) {
            final bool selected =
                widget.state.fertilityClass == chip['fc'];
            final Color chipColor = chip['color'] as Color;
            return Expanded(
              child: GestureDetector(
                onTap: () => _onClassSelected(chip['fc'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(
                      right: chips.indexOf(chip) < 2 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: selected
                        ? chipColor.withOpacity(0.15)
                        : kBgDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? chipColor : kBgCardBorder,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        chip['label'] as String,
                        style: TextStyle(
                          fontFamily: kFontFamily,
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: selected ? chipColor : kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          _thresholdHint(),
          style: TextStyle(
            fontFamily: kFontFamily,
            fontSize: 11,
            color: kTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildValueInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter soil ${widget.nutrientName} value (kg/ha)',
          style: TextStyle(
            fontFamily: kFontFamily,
            fontSize: 13,
            color: kTextSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _valueCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          onChanged: _onValueChanged,
          style: TextStyle(
            fontFamily: kFontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: kTextHighlight,
          ),
          decoration: InputDecoration(
            hintText: '0.0',
            hintStyle: TextStyle(color: kTextSecondary, fontSize: 20),
            suffixText: 'kg/ha',
            suffixStyle: TextStyle(
                fontFamily: kFontFamily,
                color: kTextSecondary,
                fontSize: 14),
            filled: true,
            fillColor: kBgDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: widget.color.withOpacity(0.3), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: kBgCardBorder, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: widget.color, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _thresholdHint(),
          style: TextStyle(
            fontFamily: kFontFamily,
            fontSize: 11,
            color: kTextSecondary,
          ),
        ),
        // Auto-detected class badge
        if (_detectedClass != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 14, color: kGreenAccent),
              const SizedBox(width: 6),
              Text(
                'Detected: ',
                style: TextStyle(
                  fontFamily: kFontFamily,
                  fontSize: 13,
                  color: kTextSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: _classColor(_detectedClass!).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(kRadiusChip),
                  border: Border.all(
                    color: _classColor(_detectedClass!).withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  _detectedClass!.toUpperCase(),
                  style: TextStyle(
                    fontFamily: kFontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _classColor(_detectedClass!),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Color _classColor(String fc) {
    switch (fc) {
      case 'low':
        return kError;
      case 'medium':
        return kWarning;
      case 'high':
        return kSuccess;
      default:
        return kTextSecondary;
    }
  }
}
