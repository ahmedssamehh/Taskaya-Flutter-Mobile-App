import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models/reminder_offset.dart';
import '../data/models/task.dart';
import '../data/models/task_category.dart';
import '../data/models/task_priority.dart';
import '../data/repositories/task_repository.dart';
import '../services/local_notification_service.dart';

enum TaskStatusFilter { all, pending, completed }

class TaskProvider extends ChangeNotifier {
  TaskProvider(
    this._repository, {
    required this.uid,
    this.notificationService,
  }) {
    _isLoading = true;
    _subscription = _repository.watchAll().listen(
      (tasks) {
        _tasks = tasks;
        _isLoading = false;
        _error = null;
        // The first snapshot for this user re-arms the OS reminders from
        // scratch, so any reminders left over from a previously signed-in
        // account on this device are cleared before ours are scheduled.
        if (!_didInitialNotificationSync && uid != null) {
          _didInitialNotificationSync = true;
          unawaited(notificationService?.resyncAll(tasks));
        }
        notifyListeners();
      },
      onError: (Object error) {
        _isLoading = false;
        _error = error is TaskRepositoryException
            ? error.message
            : 'Something went wrong loading your tasks.';
        notifyListeners();
      },
    );
  }

  /// Owner of this provider's tasks, or `null` when signed out. Compared
  /// by [main.dart]'s ProxyProvider to know when to rebuild for a new user.
  final String? uid;
  final TaskRepository _repository;
  final LocalNotificationService? notificationService;
  late final StreamSubscription<List<Task>> _subscription;

  List<Task> _tasks = const [];
  bool _isLoading = true;
  String? _error;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _didInitialNotificationSync = false;

  String _query = '';
  TaskStatusFilter _statusFilter = TaskStatusFilter.all;
  TaskCategory? _categoryFilter;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSaving => _isSaving;
  bool get isDeleting => _isDeleting;

  String get query => _query;
  TaskStatusFilter get statusFilter => _statusFilter;
  TaskCategory? get categoryFilter => _categoryFilter;
  bool get isFiltering =>
      _query.trim().isNotEmpty ||
      _categoryFilter != null ||
      _statusFilter != TaskStatusFilter.all;

  bool get isEmpty => _tasks.isEmpty;
  int get pendingCount => _tasks.where((t) => !t.isCompleted).length;
  int get completedCount => _tasks.where((t) => t.isCompleted).length;

  /// Total tasks in [category], ignoring the current filters — used for the
  /// counts shown on the category filter chips.
  int countForCategory(TaskCategory category) =>
      _tasks.where((t) => t.category == category).length;

  /// Every pending task, ignoring Home's search/status/category filters.
  /// Focus Mode picks from this so a narrowed Home view doesn't hide tasks.
  List<Task> get allPending {
    final items = _tasks.where((t) => !t.isCompleted).toList();
    items.sort((a, b) {
      final byPriority = a.priority.sortOrder.compareTo(b.priority.sortOrder);
      if (byPriority != 0) return byPriority;
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });
    return items;
  }

  Task? taskById(String id) =>
      _tasks.where((t) => t.id == id).cast<Task?>().firstOrNull;

  void setQuery(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  void clearQuery() => setQuery('');

  void setStatusFilter(TaskStatusFilter filter) {
    if (_statusFilter == filter) return;
    _statusFilter = filter;
    notifyListeners();
  }

  void setCategoryFilter(TaskCategory? category) {
    if (_categoryFilter == category) return;
    _categoryFilter = category;
    notifyListeners();
  }

  void clearFilters() {
    _query = '';
    _statusFilter = TaskStatusFilter.all;
    _categoryFilter = null;
    notifyListeners();
  }

  List<Task> get _matching {
    var items = _tasks;
    final category = _categoryFilter;
    if (category != null) {
      items = items.where((t) => t.category == category).toList();
    }
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      items = items
          .where(
            (t) =>
                t.title.toLowerCase().contains(q) ||
                t.description.toLowerCase().contains(q),
          )
          .toList();
    }
    return items;
  }

  List<Task> get pending {
    if (_statusFilter == TaskStatusFilter.completed) return const [];
    final items = _matching.where((t) => !t.isCompleted).toList();
    items.sort((a, b) {
      final byPriority = a.priority.sortOrder.compareTo(b.priority.sortOrder);
      if (byPriority != 0) return byPriority;
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });
    return items;
  }

  List<Task> get completed {
    if (_statusFilter == TaskStatusFilter.pending) return const [];
    final items = _matching.where((t) => t.isCompleted).toList();
    items.sort((a, b) {
      final aTime = a.completedAt ?? a.createdAt;
      final bTime = b.completedAt ?? b.createdAt;
      return bTime.compareTo(aTime);
    });
    return items;
  }

  /// True when there ARE tasks overall, but the current search/filter
  /// combination matches none of them — distinct from a genuinely empty
  /// task list (which shows the full-screen "add your first task" state).
  bool get hasNoResultsForFilter =>
      _tasks.isNotEmpty && isFiltering && pending.isEmpty && completed.isEmpty;

  Future<String?> addTask({
    required String title,
    String description = '',
    TaskPriority priority = TaskPriority.medium,
    TaskCategory category = TaskCategory.personal,
    DateTime? dueDate,
    ReminderOffset reminderOffset = ReminderOffset.atDueTime,
  }) async {
    _isSaving = true;
    notifyListeners();
    final task = Task(
      id: _repository.newId(),
      title: title,
      description: description,
      priority: priority,
      category: category,
      dueDate: dueDate,
      reminderOffset: reminderOffset,
      createdAt: DateTime.now(),
    );
    try {
      await _repository.upsert(task);
      unawaited(notificationService?.scheduleForTask(task));
      return null;
    } on TaskRepositoryException catch (e) {
      return e.message;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<String?> updateTask(Task task) async {
    _isSaving = true;
    notifyListeners();
    try {
      await _repository.upsert(task);
      unawaited(notificationService?.scheduleForTask(task));
      return null;
    } on TaskRepositoryException catch (e) {
      return e.message;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<String?> deleteTask(String id) async {
    _isDeleting = true;
    notifyListeners();
    try {
      await _repository.delete(id);
      unawaited(notificationService?.cancelForTask(id));
      return null;
    } on TaskRepositoryException catch (e) {
      return e.message;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  /// Re-creates a previously deleted task (Undo snackbar).
  Future<String?> restoreTask(Task task) async {
    try {
      await _repository.upsert(task);
      unawaited(notificationService?.scheduleForTask(task));
      return null;
    } on TaskRepositoryException catch (e) {
      return e.message;
    }
  }

  Future<String?> toggleComplete(String id) async {
    final task = _tasks.where((t) => t.id == id).cast<Task?>().firstOrNull;
    if (task == null) return null;
    final updated = task.isCompleted
        ? task.copyWith(isCompleted: false, clearCompletedAt: true)
        : task.copyWith(isCompleted: true, completedAt: DateTime.now());
    try {
      await _repository.upsert(updated);
      unawaited(notificationService?.scheduleForTask(updated));
      return null;
    } on TaskRepositoryException catch (e) {
      return e.message;
    }
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
