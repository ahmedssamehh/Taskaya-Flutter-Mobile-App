import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../data/models/task.dart';

/// Schedules real OS notifications for a task's due date/time. This is
/// separate from [NotificationProvider]'s in-app reminder inbox, which
/// keeps working the same regardless of whether OS permission is granted.
///
/// `flutter_local_notifications` has no web implementation, so on web every
/// method here is a no-op and the app falls back to the in-app bell alone.
class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// True when scheduled OS notifications are available on this platform.
  bool get isSupported => !kIsWeb;

  /// Set by the app shell; called with the tapped task's id.
  void Function(String taskId)? onNotificationTap;

  static const _channelId = 'task_reminders';

  Future<void> init() async {
    if (_initialized || !isSupported) return;
    _initialized = true;

    tz_data.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final taskId = response.payload;
        if (taskId != null) onNotificationTap?.call(taskId);
      },
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      'Task Reminders',
      description: 'Reminders for tasks with a due date/time',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> requestPermissions() async {
    if (!isSupported) return;
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestExactAlarmsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  int _notificationId(String taskId) => taskId.hashCode & 0x7fffffff;

  /// A stable, distinct id range for focus-session notifications, so they
  /// never collide with a task reminder's id.
  int _focusNotificationId(String sessionId) =>
      (sessionId.hashCode & 0x3fffffff) | 0x40000000;

  /// Cancels any existing reminder for [task] then (re)schedules one at
  /// `dueDate - task.reminderOffset`, if the task is pending, has a due
  /// date, opted into a reminder, and that time is still in the future.
  Future<void> scheduleForTask(Task task) async {
    await cancelForTask(task.id);
    final due = task.dueDate;
    if (task.isCompleted || due == null) return;
    final offset = task.reminderOffset.duration;
    if (offset == null) return;

    final notifyAt = due.subtract(offset);
    if (!notifyAt.isAfter(DateTime.now())) return;

    final scheduledDate = tz.TZDateTime.from(notifyAt, tz.local);
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      'Task Reminders',
      channelDescription: 'Reminders for tasks with a due date/time',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final body = offset == Duration.zero
        ? (task.description.isEmpty ? 'This task is due now' : task.description)
        : 'Due in ${task.reminderOffset.label.replaceAll(' before', '')}';

    await _plugin.zonedSchedule(
      _notificationId(task.id),
      task.title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: task.id,
    );
  }

  Future<void> cancelForTask(String taskId) =>
      _plugin.cancel(_notificationId(taskId));

  /// Drops every scheduled/visible notification. Called on sign-out so one
  /// account's reminders can never fire for the next account to sign in on
  /// this device.
  Future<void> cancelAll() => _plugin.cancelAll();

  /// Re-arms reminders for exactly the given task set, clearing anything
  /// previously scheduled first. Used when a user's task list first loads.
  Future<void> resyncAll(List<Task> tasks) async {
    await cancelAll();
    for (final task in tasks) {
      await scheduleForTask(task);
    }
  }

  /// Fires immediately — used for focus-session completion, which isn't
  /// scheduled in advance.
  Future<void> showNow({
    required String sessionId,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'focus_sessions',
      'Focus Sessions',
      channelDescription: 'Notifications when a focus session finishes',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _plugin.show(_focusNotificationId(sessionId), title, body, details);
  }
}
