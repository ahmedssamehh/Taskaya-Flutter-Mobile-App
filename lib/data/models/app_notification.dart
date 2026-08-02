import 'task.dart';

enum NotificationKind { overdue, dueToday, dueTomorrow }

/// An in-app reminder derived from a task's due date (Phase 1 is fully
/// local — real push notifications arrive with Firebase in Phase 2).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.task,
    required this.isRead,
  });

  /// Stable per task + kind, so read-state survives rebuilds.
  final String id;
  final NotificationKind kind;
  final Task task;
  final bool isRead;

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        kind: kind,
        task: task,
        isRead: isRead ?? this.isRead,
      );
}
