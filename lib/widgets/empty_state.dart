import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import 'app_mark.dart';
import 'secondary_button.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.onAddTask});

  final VoidCallback onAddTask;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: 0.35,
              child: AppMark(size: 56, color: c.textTertiary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Nothing here yet',
              style: AppTextStyles.titleMedium.copyWith(
                color: c.textPrimary,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tap + to add your first task',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            SecondaryButton(
              label: 'Add task',
              outlined: true,
              onPressed: onAddTask,
            ),
          ],
        ),
      ),
    );
  }
}
