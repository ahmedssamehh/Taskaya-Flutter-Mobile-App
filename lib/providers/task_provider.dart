import 'package:flutter/foundation.dart';

import '../data/models/task.dart';
import '../data/models/task_priority.dart';
import '../data/repositories/task_repository.dart';

class TaskProvider extends ChangeNotifier {
  TaskProvider(this._repository) {
    _refresh();
  }

  final TaskRepository _repository;
  List<Task> _tasks = [];

  void _refresh() {
    _tasks = _repository.getAll();
  }

  bool get isEmpty => _tasks.isEmpty;
  int get pendingCount => _tasks.where((t) => !t.isCompleted).length;
  int get completedCount => _tasks.where((t) => t.isCompleted).length;

  List<Task> get pending {
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

  List<Task> get completed {
    final items = _tasks.where((t) => t.isCompleted).toList();
    items.sort((a, b) {
      final aTime = a.completedAt ?? a.createdAt;
      final bTime = b.completedAt ?? b.createdAt;
      return bTime.compareTo(aTime);
    });
    return items;
  }

  Task addTask({
    required String title,
    String description = '',
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
  }) {
    final task = _repository.create(
      title: title,
      description: description,
      priority: priority,
      dueDate: dueDate,
    );
    _refresh();
    notifyListeners();
    return task;
  }

  void updateTask(Task task) {
    _repository.update(task);
    _refresh();
    notifyListeners();
  }

  Task? deleteTask(String id) {
    final removed = _tasks.where((t) => t.id == id).cast<Task?>().firstOrNull;
    _repository.delete(id);
    _refresh();
    notifyListeners();
    return removed;
  }

  void toggleComplete(String id) {
    final task = _tasks.where((t) => t.id == id).cast<Task?>().firstOrNull;
    if (task == null) return;
    final updated = task.isCompleted
        ? task.copyWith(isCompleted: false, clearCompletedAt: true)
        : task.copyWith(isCompleted: true, completedAt: DateTime.now());
    _repository.update(updated);
    _refresh();
    notifyListeners();
  }

  void restoreTask(Task task, int index) {
    _repository.insertAt(index, task);
    _refresh();
    notifyListeners();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
