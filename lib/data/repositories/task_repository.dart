import '../models/task.dart';

class TaskRepositoryException implements Exception {
  TaskRepositoryException(this.message, {this.isPermissionDenied = false});

  final String message;

  /// The backend rejected the caller's access. During sign-out this fires
  /// once as the listener is torn down, so callers can tell it apart from a
  /// genuine failure worth showing the user.
  final bool isPermissionDenied;
}

/// Owner-scoped task storage. Implementations persist under a single
/// authenticated user (see [FirestoreTaskRepository]).
abstract class TaskRepository {
  /// A generated id for a not-yet-created task, so the caller can build
  /// an optimistic [Task] before the write completes.
  String newId();

  /// Live view of every task owned by this repository's user.
  Stream<List<Task>> watchAll();

  /// Creates or overwrites the task at `task.id`.
  Future<void> upsert(Task task);

  Future<void> delete(String id);
}
