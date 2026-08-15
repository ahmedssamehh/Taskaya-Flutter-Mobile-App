import 'package:flutter/material.dart';

import '../core/motion/app_motion.dart';
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

  /// Pending task whose due time has already passed.
  bool get _isOverdue {
    final due = task.dueDate;
    if (task.isCompleted || due == null) return false;
    return due.isBefore(DateTime.now());
  }

  /// Pending task due within the next hour — worth a nudge, but not alarming.
  bool get _isDueSoon {
    final due = task.dueDate;
    if (task.isCompleted || due == null || _isOverdue) return false;
    return due.difference(DateTime.now()) <= const Duration(hours: 1);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final meta = _metaLabel;
    final overdue = _isOverdue;
    final dueSoon = _isDueSoon;
    final accentEdge = overdue
        ? c.error
        : dueSoon
        ? c.borderStrong
        : c.border;

    return Semantics(
      label: task.title,
      hint: task.isCompleted
          ? 'Completed task'
          : overdue
          ? 'Overdue task'
          : 'Pending task',
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          child: AnimatedContainer(
            duration: AppMotion.d(context, AppMotion.base),
            curve: AppMotion.enter,
            decoration: BoxDecoration(
              border: Border.all(
                color: accentEdge,
                width: (overdue || dueSoon)
                    ? 1.4
                    : AppSpacing.borderHairline,
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
                              overdue
                                  ? Icons.error_outline
                                  : dueSoon
                                  ? Icons.schedule
                                  : Icons.calendar_today_outlined,
                              size: 11,
                              color: overdue
                                  ? c.error
                                  : task.isCompleted
                                  ? c.textTertiary
                                  : c.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                overdue ? 'Overdue · $meta' : meta,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.meta.copyWith(
                                  color: overdue
                                      ? c.error
                                      : task.isCompleted
                                      ? c.textTertiary
                                      : c.textSecondary,
                                  fontWeight: overdue
                                      ? FontWeight.w600
                                      : null,
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
                Semantics(
                  label: '${task.category.label} category',
                  child: Container(
                    width: 26,
                    height: 26,
                    margin: const EdgeInsets.only(left: AppSpacing.sm),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: c.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      task.category.icon,
                      size: 13,
                      color: task.isCompleted
                          ? c.textTertiary
                          : c.textSecondary,
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
