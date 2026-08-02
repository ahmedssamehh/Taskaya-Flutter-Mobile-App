import 'package:uuid/uuid.dart';

import '../models/task.dart';
import '../models/task_priority.dart';

/// In-memory task store for Phase 1. Phase 2 swaps this for a
/// Firestore-backed repository; [Task.toMap]/[Task.fromMap] already
/// exist for that migration.
class TaskRepository {
  TaskRepository() {
    _seed();
  }

  final _uuid = const Uuid();
  final List<Task> _tasks = [];

  void _seed() {
    final now = DateTime.now();
    _tasks.addAll([
      Task(
        id: _uuid.v4(),
        title: 'Finish Phase 1 report',
        priority: TaskPriority.high,
        dueDate: DateTime(now.year, now.month, now.day, 18, 0),
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Task(
        id: _uuid.v4(),
        title: 'Design login screen',
        priority: TaskPriority.medium,
        dueDate: now.add(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Task(
        id: _uuid.v4(),
        title: 'Buy groceries',
        priority: TaskPriority.low,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Task(
        id: _uuid.v4(),
        title: 'Set up Flutter project',
        isCompleted: true,
        createdAt: now.subtract(const Duration(days: 3)),
        completedAt: now.subtract(const Duration(days: 1)),
      ),
    ]);
  }

  List<Task> getAll() => List.unmodifiable(_tasks);

  Task create({
    required String title,
    String description = '',
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
  }) {
    final task = Task(
      id: _uuid.v4(),
      title: title,
      description: description,
      priority: priority,
      dueDate: dueDate,
      createdAt: DateTime.now(),
    );
    _tasks.add(task);
    return task;
  }

  void update(Task task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) _tasks[index] = task;
  }

  void delete(String id) {
    _tasks.removeWhere((t) => t.id == id);
  }

  void insertAt(int index, Task task) {
    final clamped = index.clamp(0, _tasks.length);
    _tasks.insert(clamped, task);
  }
}
