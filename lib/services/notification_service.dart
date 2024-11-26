import 'dart:developer';
import 'package:app/utils/request_notification_permission.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app/utils/datetime_utils.dart' as datetime_utils;

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin;

  NotificationService(this._notificationsPlugin);

  Future<void> initialize() async {
    log('Initializing notifications...');
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('icon'); // Ensure icon.png exists

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        log('Notification clicked with payload: ${response.payload}');
      },
    );

    await _createNotificationChannel();
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'task_channel_1',
      'Task Notifications',
      description: 'This channel is used for task reminders.',
      importance: Importance.high,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> sendNotification(String title, String body) async {
    log('Sending notification: $title - $body');

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'task_channel_1',
      'Task Notifications',
      channelDescription: 'Task Notifications',
      importance: Importance.max,
      priority: Priority.high,
      icon: 'icon',
      showWhen: true,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.show(
        0, // Notification ID
        title,
        body,
        platformDetails,
      );
      log('Notification sent successfully.');
    } catch (e) {
      log('Error sending notification: $e');
    }
  }

  /// Schedules a notification for a specific task.
  ///
  /// Parameters:
  /// - [title]: The title of the notification.
  /// - [body]: The body of the notification.
  /// - [deadline]: The task deadline in UTC.
  /// - [alertFrequency]: The frequency for the alert (e.g., "5_minutes", "1_hour").
  /// - [customReminder]: A map with custom reminder settings (e.g., `{quantity: 2, unit: "hours"}`).
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime deadline,
    String? alertFrequency,
    Map<String, dynamic>? customReminder,
  }) async {
    final notificationId = deadline.hashCode;
    final notificationTime =
        _calculateNotificationTime(deadline, alertFrequency, customReminder);

    if (notificationTime == null) {
      log('Invalid alertFrequency or customReminder configuration');
      return;
    }

    log('Scheduling notification for $notificationTime');

    try {
      await requestNotificationPermission();

      final androidMode = await Permission.scheduleExactAlarm.isGranted
          ? AndroidScheduleMode.exact
          : AndroidScheduleMode.inexact;

      await _notificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        datetime_utils.convertToTZDateTime(notificationTime),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_channel_1',
            'Task Notifications',
            channelDescription: 'Task Reminder Notifications',
            importance: Importance.max,
            priority: Priority.high,
            icon: 'icon',
          ),
        ),
        androidScheduleMode: androidMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      log('Notification scheduled for $notificationTime');
    } catch (e) {
      log('Error scheduling notification: $e');
    }
  }

  DateTime? _calculateNotificationTime(
    DateTime deadline,
    String? alertFrequency,
    Map<String, dynamic>? customReminder,
  ) {
    Duration? offset;

    switch (alertFrequency) {
      case "5_minutes":
        offset = const Duration(minutes: 5);
        break;
      case "1_hour":
        offset = const Duration(hours: 1);
        break;
      case "2_hours":
        offset = const Duration(hours: 2);
        break;
      case "3_hours":
        offset = const Duration(hours: 3);
        break;
      case "1_day":
        offset = const Duration(days: 1);
        break;
      case "custom":
        if (customReminder != null) {
          final quantity = customReminder['quantity'] as int? ?? 0;
          final unit = customReminder['unit'] as String? ?? 'hours';
          if (unit == 'hours') {
            offset = Duration(hours: quantity);
          } else if (unit == 'days') {
            offset = Duration(days: quantity);
          } else if (unit == 'weeks') {
            offset = Duration(days: quantity * 7);
          }
        }
        break;
      default:
        return null;
    }

    return deadline.subtract(offset!);
  }

  Future<void> cancelNotification(int taskId) async {
    await _notificationsPlugin.cancel(taskId);
    log('Notification cancelled for taskId $taskId');
  }
}
