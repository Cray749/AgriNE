// lib/widgets/step_indicator.dart
// ─────────────────────────────────────────────────────────────────────────────
// AgriSutra NE — Step Progress Indicator
// Shown at the top of the input_wizard_screen pages.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../core/theme.dart';

class StepIndicator extends StatelessWidget {
  final int currentStep;   // 1-based (1 = first step)
  final int totalSteps;
  final List<String> labels;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(totalSteps * 2 - 1, (index) {
          // Even indices → step circles; odd indices → connecting lines
          if (index.isOdd) {
            // Connecting line
            final int stepBefore = (index ~/ 2) + 1; // step number before this line
            final bool lineCompleted = currentStep > stepBefore;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 2,
                decoration: BoxDecoration(
                  color: lineCompleted ? kGreenPrimary : kBgCardBorder,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          } else {
            // Step circle
            final int stepNumber = (index ~/ 2) + 1;
            final bool isCompleted = currentStep > stepNumber;
            final bool isActive = currentStep == stepNumber;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? kGreenPrimary
                        : isActive
                            ? kGreenAccent
                            : kBgCard,
                    border: Border.all(
                      color: isCompleted || isActive
                          ? Colors.transparent
                          : kBgCardBorder,
                      width: 1.5,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: kGreenAccent.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : Text(
                            '$stepNumber',
                            style: TextStyle(
                              fontFamily: kFontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isActive ? kBgDark : kTextSecondary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                if (stepNumber <= labels.length)
                  Text(
                    labels[stepNumber - 1],
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? kGreenAccent
                          : isCompleted
                              ? kTextPrimary
                              : kTextSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            );
          }
        }),
      ),
    );
  }
}
