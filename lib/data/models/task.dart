import 'package:cloud_firestore/cloud_firestore.dart';

import 'reminder_offset.dart';
import 'task_category.dart';
import 'task_priority.dart';

class Task {
  const Task({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.priority = TaskPriority.medium,
    this.category = TaskCategory.personal,
    this.dueDate,
    this.reminderOffset = ReminderOffset.atDueTime,
    required this.createdAt,
    this.completedAt,
  });

  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final TaskPriority priority;
  final TaskCategory category;
  final DateTime? dueDate;
  final ReminderOffset reminderOffset;
  final DateTime createdAt;
  final DateTime? completedAt;

  Task copyWith({
    String? title,
    String? description,
    bool? isCompleted,
    TaskPriority? priority,
    TaskCategory? category,
    DateTime? dueDate,
    bool clearDueDate = false,
    ReminderOffset? reminderOffset,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      reminderOffset: reminderOffset ?? this.reminderOffset,
      createdAt: createdAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  /// Serializes for Cloud Firestore. Dates become [Timestamp]s; the doc
  /// lives at `users/{uid}/tasks/{id}`, so no owner id is stored in the map.
  Map<String, dynamic> toFirestoreMap() {
    return {
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'priority': priority.name,
      'category': category.name,
      'dueDate': dueDate == null ? null : Timestamp.fromDate(dueDate!),
      'reminderOffset': reminderOffset.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt == null
          ? null
          : Timestamp.fromDate(completedAt!),
    };
  }

  factory Task.fromFirestore(String id, Map<String, dynamic> data) {
    DateTime? readDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return Task(
      id: id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      isCompleted: data['isCompleted'] as bool? ?? false,
      priority: TaskPriority.fromName(data['priority'] as String? ?? 'medium'),
      category: TaskCategory.fromName(data['category'] as String?),
      dueDate: readDate(data['dueDate']),
      reminderOffset: ReminderOffset.fromName(data['reminderOffset'] as String?),
      createdAt: readDate(data['createdAt']) ?? DateTime.now(),
      completedAt: readDate(data['completedAt']),
    );
  }
}
