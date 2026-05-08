// lib/widgets/app_button.dart
// ─────────────────────────────────────────────────────────────────────────────
// AgriSutra NE — Reusable Button Widget
// Used across ALL screens for consistency.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../core/theme.dart';

enum AppButtonVariant { primary, secondary, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double height;
  final double? width;
  final double fontSize;

  const AppButton({
    super.key,
    required this.label,
    this.onTap,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.height = 56.0,
    this.width,
    this.fontSize = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPrimary = variant == AppButtonVariant.primary;
    final bool isDanger = variant == AppButtonVariant.danger;

    final Color bgColor = isDanger
        ? kError
        : isPrimary
            ? kGreenPrimary
            : Colors.transparent;

    final Color textColor = isPrimary || isDanger ? kTextHighlight : kGreenAccent;

    final Border? border = !isPrimary && !isDanger
        ? Border.all(color: kGreenAccent, width: 1.5)
        : null;

    return GestureDetector(
      onTap: (isLoading || onTap == null) ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(kRadiusButton),
          border: border,
          boxShadow: isPrimary && onTap != null
              ? [
                  BoxShadow(
                    color: kGreenPrimary.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kRadiusButton),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: (isLoading || onTap == null) ? null : onTap,
              splashColor: Colors.white.withOpacity(0.1),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: textColor,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, color: textColor, size: fontSize + 2),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            label,
                            style: TextStyle(
                              fontFamily: kFontFamily,
                              fontSize: fontSize,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                              letterSpacing: 0.3,
                            ),
                          ),
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
