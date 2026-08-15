enum ReminderOffset {
  none,
  atDueTime,
  minutes10,
  minutes30,
  hour1,
  hours3,
  day1;

  String get label => switch (this) {
    ReminderOffset.none => 'No reminder',
    ReminderOffset.atDueTime => 'At due time',
    ReminderOffset.minutes10 => '10 min before',
    ReminderOffset.minutes30 => '30 min before',
    ReminderOffset.hour1 => '1 hour before',
    ReminderOffset.hours3 => '3 hours before',
    ReminderOffset.day1 => '1 day before',
  };

  /// How long before the due date/time the reminder should fire, or `null`
  /// if this task shouldn't get a reminder at all.
  Duration? get duration => switch (this) {
    ReminderOffset.none => null,
    ReminderOffset.atDueTime => Duration.zero,
    ReminderOffset.minutes10 => const Duration(minutes: 10),
    ReminderOffset.minutes30 => const Duration(minutes: 30),
    ReminderOffset.hour1 => const Duration(hours: 1),
    ReminderOffset.hours3 => const Duration(hours: 3),
    ReminderOffset.day1 => const Duration(days: 1),
  };

  static ReminderOffset fromName(String? name) {
    return ReminderOffset.values.firstWhere(
      (r) => r.name == name,
      orElse: () => ReminderOffset.atDueTime,
    );
  }
}
