import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/routing/page_transitions.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/date_formatter.dart';
import '../data/models/app_notification.dart';
import '../providers/notification_provider.dart';
import '../screens/add_edit/add_edit_task_screen.dart';
import 'secondary_button.dart';

/// Bell icon for the Home header with an unread badge; opens the
/// notification center bottom sheet.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => const _NotificationsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final unread = context.watch<NotificationProvider>().unreadCount;

    return Semantics(
      label: unread == 0
          ? 'Notifications'
          : 'Notifications, $unread unread',
      button: true,
      child: IconButton(
        onPressed: () => _openSheet(context),
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              unread > 0
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_none,
              color: c.textPrimary,
              size: 20,
            ),
            if (unread > 0)
              Positioned(
                top: -4,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  constraints: const BoxConstraints(minWidth: 15),
                  decoration: BoxDecoration(
                    color: c.accent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: c.background, width: 1.5),
                  ),
                  child: Text(
                    '$unread',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.meta.copyWith(
                      color: c.onAccent,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final notifications = context.watch<NotificationProvider>();
    final items = notifications.items;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm2),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPaddingH,
                AppSpacing.md,
                AppSpacing.sm,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Notifications',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: c.textPrimary,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  if (notifications.hasUnread)
                    SecondaryButton(
                      label: 'Mark all read',
                      onPressed: notifications.markAllRead,
                    ),
                ],
              ),
            ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 48,
                      color: c.textTertiary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      "You're all caught up",
                      style: AppTextStyles.taskTitle.copyWith(
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Reminders appear here when tasks are due.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.meta.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPaddingH,
                    AppSpacing.md,
                    AppSpacing.screenPaddingH,
                    AppSpacing.lg,
                  ),
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) =>
                      _NotificationTile(notification: items[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  IconData get _icon => switch (notification.kind) {
        NotificationKind.overdue => Icons.assignment_late_outlined,
        NotificationKind.dueToday => Icons.today_outlined,
        NotificationKind.dueTomorrow => Icons.event_outlined,
      };

  String get _label => switch (notification.kind) {
        NotificationKind.overdue =>
          'Overdue — was due ${DateFormatter.dueLabel(notification.task.dueDate)}',
        NotificationKind.dueToday =>
          'Due ${DateFormatter.dueLabel(notification.task.dueDate)}',
        NotificationKind.dueTomorrow => 'Due Tomorrow',
      };

  void _open(BuildContext context) {
    context.read<NotificationProvider>().markRead(notification.id);
    Navigator.of(context).pop();
    Navigator.of(context).push(
      slideUpRoute(AddEditTaskScreen(task: notification.task)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final unread = !notification.isRead;

    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(
              color: c.border,
              width: AppSpacing.borderHairline,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: c.border),
                  borderRadius: BorderRadius.circular(
                    AppSpacing.controlRadius,
                  ),
                ),
                child: Icon(_icon, size: 18, color: c.textPrimary),
              ),
              const SizedBox(width: AppSpacing.sm2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.taskTitle.copyWith(
                        color: unread ? c.textPrimary : c.textSecondary,
                        fontWeight:
                            unread ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _label,
                      style: AppTextStyles.meta.copyWith(
                        color: c.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (unread)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: c.accent,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
