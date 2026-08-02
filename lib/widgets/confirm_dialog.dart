import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import 'primary_button.dart';
import 'secondary_button.dart';

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  String cancelLabel = 'Cancel',
  bool destructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => ConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: destructive,
    ),
  );
  return result ?? false;
}

class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.destructive,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return AlertDialog(
      title: Text(
        title,
        style: AppTextStyles.titleMedium.copyWith(
          color: c.textPrimary,
          fontSize: 18,
        ),
      ),
      content: Text(
        message,
        style: AppTextStyles.body.copyWith(color: c.textSecondary),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      actions: [
        Expanded(
          child: SecondaryButton(
            label: cancelLabel,
            outlined: true,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ),
        const SizedBox(width: AppSpacing.sm2),
        Expanded(
          child: destructive
              ? Material(
                  color: c.error,
                  borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(true),
                    borderRadius: BorderRadius.circular(
                      AppSpacing.controlRadius,
                    ),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 52),
                      alignment: Alignment.center,
                      child: Text(
                        confirmLabel,
                        style: AppTextStyles.button.copyWith(color: c.onAccent),
                      ),
                    ),
                  ),
                )
              : PrimaryButton(
                  label: confirmLabel,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
        ),
      ],
    );
  }
}
