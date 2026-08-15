import 'package:flutter/material.dart';

enum TaskCategory {
  personal,
  study,
  work,
  other;

  String get label => switch (this) {
    TaskCategory.personal => 'Personal',
    TaskCategory.study => 'Study',
    TaskCategory.work => 'Work',
    TaskCategory.other => 'Other',
  };

  IconData get icon => switch (this) {
    TaskCategory.personal => Icons.person_outline,
    TaskCategory.study => Icons.school_outlined,
    TaskCategory.work => Icons.work_outline,
    TaskCategory.other => Icons.label_outline,
  };

  static TaskCategory fromName(String? name) {
    return TaskCategory.values.firstWhere(
      (c) => c.name == name,
      orElse: () => TaskCategory.other,
    );
  }
}
