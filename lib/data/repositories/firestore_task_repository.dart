import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/task.dart';
import 'task_repository.dart';

/// Stores tasks at `users/{uid}/tasks/{taskId}` so Firestore security rules
/// can scope reads/writes to their owner.
class FirestoreTaskRepository implements TaskRepository {
  FirestoreTaskRepository({required this.uid, FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final String uid;
  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(uid).collection('tasks');

  @override
  String newId() => _uuid.v4();

  @override
  Stream<List<Task>> watchAll() {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Task.fromFirestore(doc.id, doc.data()))
          .toList();
    }).handleError((Object error) {
      throw _toException(error);
    });
  }

  @override
  Future<void> upsert(Task task) async {
    try {
      await _collection.doc(task.id).set(task.toFirestoreMap());
    } catch (error) {
      throw _toException(error);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _collection.doc(id).delete();
    } catch (error) {
      throw _toException(error);
    }
  }

  TaskRepositoryException _toException(Object error) {
    return TaskRepositoryException(
      _mapError(error),
      isPermissionDenied:
          error is FirebaseException && error.code == 'permission-denied',
    );
  }

  String _mapError(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return "You don't have permission to do that.";
        case 'unavailable':
        case 'network-request-failed':
          return 'No internet connection. Check your network and try again.';
        default:
          return 'Something went wrong syncing your tasks. Please try again.';
      }
    }
    return 'Something went wrong syncing your tasks. Please try again.';
  }
}
