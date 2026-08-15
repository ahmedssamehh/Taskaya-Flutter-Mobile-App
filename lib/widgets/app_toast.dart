import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';

enum ToastKind { success, info, error }

/// Consistent, icon-led snackbars for task actions ("Task created",
/// "Task deleted" + Undo, error messages). Replaces the ad-hoc
/// `ScaffoldMessenger` calls that were scattered across screens.
class AppToast {
  AppToast._();

  static void show(
    BuildContext context, {
    required String message,
    ToastKind kind = ToastKind.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    final c = context.colors;
    final messenger = ScaffoldMessenger.of(context);

    final icon = switch (kind) {
      ToastKind.success => Icons.check_circle_outline,
      ToastKind.info => Icons.info_outline,
      ToastKind.error => Icons.error_outline,
    };
    final iconColor = kind == ToastKind.error ? c.error : c.onAccent;

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        content: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.body.copyWith(
                  color: c.onAccent,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        action: (actionLabel != null && onAction != null)
            ? SnackBarAction(
                label: actionLabel,
                textColor: c.onAccent,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  static void success(BuildContext context, String message) =>
      show(context, message: message, kind: ToastKind.success);

  static void error(BuildContext context, String message) =>
      show(context, message: message, kind: ToastKind.error);
}
