import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff < -1 && diff >= -6) return '${-diff} days ago';
    return DateFormat('MMM d').format(date);
  }

  static String time(DateTime date) => DateFormat('HH:mm').format(date);

  static String dueLabel(DateTime? due) {
    if (due == null) return 'No due date';
    final hasTime = due.hour != 0 || due.minute != 0;
    if (!hasTime) return relativeDate(due);
    return '${relativeDate(due)}, ${time(due)}';
  }
}
