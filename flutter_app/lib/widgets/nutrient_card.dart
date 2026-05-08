// lib/widgets/nutrient_card.dart
// ─────────────────────────────────────────────────────────────────────────────
// AgriSutra NE — Expandable Nutrient Result Card
// Used on results_screen.dart for N, P, and K results.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/models.dart';

class NutrientResultCard extends StatefulWidget {
  final NutrientResult result;
  final double landSizeAcres;
  final int animationDelayMs; // stagger cards: 0, 150, 300

  const NutrientResultCard({
    super.key,
    required this.result,
    required this.landSizeAcres,
    this.animationDelayMs = 0,
  });

  @override
  State<NutrientResultCard> createState() => _NutrientResultCardState();
}

class _NutrientResultCardState extends State<NutrientResultCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _expandAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  /// Returns the emoji icon for each nutrient
  String _getEmoji() {
    switch (widget.result.nutrientSymbol) {
      case 'N':
        return '🌿';
      case 'P₂O₅':
        return '🌱';
      case 'K₂O':
        return '🌾';
      default:
        return '🧪';
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color nutrientColor = widget.result.color;
    final r = widget.result;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: nutrientColor.withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: nutrientColor.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kRadiusCard),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: nutrientColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(_getEmoji(), style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.nutrientName.toUpperCase(),
                        style: TextStyle(
                          fontFamily: kFontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: nutrientColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        r.nutrientSymbol,
                        style: TextStyle(
                          fontFamily: kFontFamily,
                          fontSize: 11,
                          color: kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Fertility class badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getFertilityBadgeColor(r.fertilityClassUsed)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(kRadiusChip),
                      border: Border.all(
                        color: _getFertilityBadgeColor(r.fertilityClassUsed)
                            .withOpacity(0.6),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      r.fertilityClassUsed.toUpperCase(),
                      style: TextStyle(
                        fontFamily: kFontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getFertilityBadgeColor(r.fertilityClassUsed),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Main Values ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "Required Nutrient" row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Required Nutrient',
                        style: TextStyle(
                          fontFamily: kFontFamily,
                          fontSize: 13,
                          color: kTextSecondary,
                        ),
                      ),
                      Text(
                        '${r.requiredKgHa} kg/ha',
                        style: TextStyle(
                          fontFamily: kFontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: kTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Big product card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: nutrientColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: nutrientColor.withOpacity(0.25), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.fertilizerName,
                          style: TextStyle(
                            fontFamily: kFontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: kTextSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Per hectare value — big
                        Text(
                          '${r.productKgHa} kg/ha',
                          style: TextStyle(
                            fontFamily: kFontFamily,
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: nutrientColor,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Total for land
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: kBgDark,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.straighten,
                                  size: 14, color: kTextSecondary),
                              const SizedBox(width: 6),
                              Text(
                                'For your ${widget.landSizeAcres} acres: ',
                                style: TextStyle(
                                  fontFamily: kFontFamily,
                                  fontSize: 13,
                                  color: kTextSecondary,
                                ),
                              ),
                              Text(
                                '${r.productKgTotal} kg',
                                style: TextStyle(
                                  fontFamily: kFontFamily,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: kTextHighlight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Expandable "Why?" section ────────────────────────────────
            GestureDetector(
              onTap: _toggleExpand,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: nutrientColor.withOpacity(0.8)),
                    const SizedBox(width: 8),
                    Text(
                      'Why this amount?',
                      style: TextStyle(
                        fontFamily: kFontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: nutrientColor,
                      ),
                    ),
                    const Spacer(),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(Icons.keyboard_arrow_down,
                          color: nutrientColor, size: 20),
                    ),
                  ],
                ),
              ),
            ),

            // Expandable content
            SizeTransition(
              sizeFactor: _expandAnim,
              axisAlignment: -1,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kBgDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: nutrientColor.withOpacity(0.15), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Why
                      _ExpandRow(
                        icon: Icons.science_outlined,
                        color: nutrientColor,
                        title: 'Scientific Reason',
                        body: r.why,
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: kBgCardBorder, height: 1),
                      const SizedBox(height: 12),

                      // Schedule
                      _ExpandRow(
                        icon: Icons.calendar_today_outlined,
                        color: nutrientColor,
                        title: 'Application Schedule',
                        body: r.schedule,
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: kBgCardBorder, height: 1),
                      const SizedBox(height: 12),

                      // Equation
                      _ExpandRow(
                        icon: Icons.functions,
                        color: nutrientColor,
                        title: 'STCR Equation Used',
                        body: r.equationUsed,
                        isMonospace: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getFertilityBadgeColor(String fc) {
    switch (fc.toLowerCase()) {
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

/// Small helper widget for rows inside the expandable section
class _ExpandRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final bool isMonospace;

  const _ExpandRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    this.isMonospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: TextStyle(
            fontFamily: isMonospace ? 'monospace' : kFontFamily,
            fontSize: isMonospace ? 12 : 13,
            color: kTextPrimary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
