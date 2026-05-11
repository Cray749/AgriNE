// lib/widgets/fertilizer_result_card.dart
// ─────────────────────────────────────────────────────────────────────────────
// AgriSutra NE — Compact Fertilizer Summary Card
// Used in the "at-a-glance" summary row at top of results, and can be
// reused in any future summary or history screen.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/models.dart';

class FertilizerResultCard extends StatelessWidget {
  final NutrientResult result;
  final bool isCompact; // compact = no "total for land" row

  const FertilizerResultCard({
    super.key,
    required this.result,
    this.isCompact = false,
  });

  String get _emoji {
    switch (result.nutrientSymbol) {
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
    final Color c = result.color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ctxCard(context),
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: c.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: c.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emoji + name row
          Row(
            children: [
              Text(_emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.fertilizerName,
                  style: TextStyle(
                    fontFamily: kFontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: c,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Big per-ha number — FittedBox prevents overflow on 360px-wide cheap Androids
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              result.productKgHa.toStringAsFixed(1),
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: c,
                height: 1.0,
              ),
            ),
          ),
          Text(
            'kg / ha',
            style: TextStyle(
              fontFamily: kFontFamily,
              fontSize: 11,
              color: ctxTextMuted(context),
            ),
          ),

          if (!isCompact) ...[
            const SizedBox(height: 8),
            Divider(color: ctxCardBorder(context), height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.agriculture, size: 13, color: ctxTextMuted(context)),
                const SizedBox(width: 4),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Total: ${result.productKgTotal.toStringAsFixed(1)} kg',
                      style: TextStyle(
                        fontFamily: kFontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ctxHeading(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
