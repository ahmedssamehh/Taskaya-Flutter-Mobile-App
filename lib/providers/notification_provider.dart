import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/app_notification.dart';
import '../data/models/task.dart';

/// Derives in-app reminders from pending tasks' due dates: overdue,
/// due today, and due tomorrow. Read-state is persisted locally so
/// notifications stay read across restarts.
class NotificationProvider extends ChangeNotifier {
  static const _readIdsKey = 'taskaya_notification_read_ids';

  List<Task> _tasks = const [];
  List<AppNotification> _items = const [];
  Set<String> _readIds = {};

  List<AppNotification> get items => _items;
  int get unreadCount => _items.where((n) => !n.isRead).length;
  bool get hasUnread => unreadCount > 0;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _readIds = (prefs.getStringList(_readIdsKey) ?? const []).toSet();
    } catch (_) {
      // No stored state is fine — everything just starts unread.
    }
    _rebuild();
  }

  /// Called whenever the task list changes (wired via a ProxyProvider).
  void updateTasks(List<Task> pendingTasks) {
    _tasks = pendingTasks;
    _rebuild();
  }

  void markRead(String id) {
    if (_readIds.add(id)) {
      _rebuild();
      _persist();
    }
  }

  void markAllRead() {
    _readIds.addAll(_items.map((n) => n.id));
    _rebuild();
    _persist();
  }

  void _rebuild() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final derived = <AppNotification>[];

    for (final task in _tasks) {
      final due = task.dueDate;
      if (task.isCompleted || due == null) continue;
      final dueDay = DateTime(due.year, due.month, due.day);
      final diff = dueDay.difference(today).inDays;

      NotificationKind? kind;
      if (diff < 0) {
        kind = NotificationKind.overdue;
      } else if (diff == 0) {
        kind = NotificationKind.dueToday;
      } else if (diff == 1) {
        kind = NotificationKind.dueTomorrow;
      }
      if (kind == null) continue;

      final id = '${task.id}:${kind.name}';
      derived.add(AppNotification(
        id: id,
        kind: kind,
        task: task,
        isRead: _readIds.contains(id),
      ));
    }

    // Most urgent first: overdue, then today, then tomorrow; earlier
    // due dates first within each group.
    derived.sort((a, b) {
      final byKind = a.kind.index.compareTo(b.kind.index);
      if (byKind != 0) return byKind;
      return a.task.dueDate!.compareTo(b.task.dueDate!);
    });

    _items = derived;
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Keep only ids that still exist so the stored list never grows
      // beyond the live notification set.
      final liveIds = _items.map((n) => n.id).toSet();
      await prefs.setStringList(
        _readIdsKey,
        _readIds.where(liveIds.contains).toList(),
      );
    } catch (_) {
      // Persistence is best-effort in the Phase 1 mock setup.
    }
  }
}
