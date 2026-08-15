import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final disabled = onPressed == null || isLoading;

    return SizedBox(
      width: double.infinity,
      child: Semantics(
        button: true,
        enabled: !disabled,
        label: 'Continue with Google',
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          child: InkWell(
            onTap: disabled ? null : onPressed,
            borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
            child: Container(
              constraints: const BoxConstraints(minHeight: 52),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(
                  color: c.border,
                  width: AppSpacing.borderHairline,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(c.textPrimary),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.g_mobiledata_rounded,
                          size: 26,
                          color: c.textPrimary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Continue with Google',
                          style: AppTextStyles.button.copyWith(
                            color: c.textPrimary,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
