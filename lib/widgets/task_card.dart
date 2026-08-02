import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/date_formatter.dart';
import '../data/models/task.dart';
import '../data/models/task_priority.dart';
import 'animated_checkbox.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onTap,
    required this.onLongPress,
  });

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  /// Every task always shows a date: its due date if one is set, otherwise
  /// the date it was completed or added — a task is never date-less.
  String get _dateLabel {
    if (task.isCompleted) {
      final when = task.completedAt ?? task.createdAt;
      return 'Completed ${DateFormatter.relativeDate(when)}';
    }
    if (task.dueDate != null) return DateFormatter.dueLabel(task.dueDate);
    return 'Added ${DateFormatter.relativeDate(task.createdAt)}';
  }

  String get _metaLabel {
    final date = _dateLabel;
    final priority = task.priority == TaskPriority.medium
        ? null
        : task.priority.label;
    if (!task.isCompleted && priority != null) return '$date · $priority';
    return date;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final meta = _metaLabel;

    return Semantics(
      label: task.title,
      hint: task.isCompleted ? 'Completed task' : 'Pending task',
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: c.border,
                width: AppSpacing.borderHairline,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm2,
              vertical: 4,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedCheckbox(
                  checked: task.isCompleted,
                  onChanged: onToggle,
                ),
                const SizedBox(width: AppSpacing.sm2 - 6),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.taskTitle.copyWith(
                            color: task.isCompleted
                                ? c.textTertiary
                                : c.textPrimary,
                            fontWeight: task.isCompleted
                                ? FontWeight.w400
                                : FontWeight.w500,
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 11,
                              color: task.isCompleted
                                  ? c.textTertiary
                                  : c.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                meta,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.meta.copyWith(
                                  color: task.isCompleted
                                      ? c.textTertiary
                                      : c.textSecondary,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
