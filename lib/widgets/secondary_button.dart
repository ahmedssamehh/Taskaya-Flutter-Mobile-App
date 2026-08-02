import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.outlined = false,
    this.destructive = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool outlined;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = destructive ? c.error : c.textPrimary;

    return SizedBox(
      width: outlined ? double.infinity : null,
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
            child: Container(
              constraints: BoxConstraints(minHeight: outlined ? 52 : 44),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: outlined
                  ? BoxDecoration(
                      border: Border.all(
                        color: destructive ? c.error : c.border,
                        width: AppSpacing.borderHairline,
                      ),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.controlRadius,
                      ),
                    )
                  : null,
              child: Text(
                label,
                style: AppTextStyles.button.copyWith(color: fg),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
