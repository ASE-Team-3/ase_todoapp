import 'package:app/models/task.dart';
import 'package:app/services/notification_service.dart';

/// Schedules a notification for a task.
void scheduleTaskNotification({
  required NotificationService notificationService,
  required Task task,
  required String title,
}) {
  if (!task.isCompleted && task.deadline != null) {
    notificationService.scheduleNotification(
      title: title,
      body: 'Don\'t forget: "${task.title}" is due soon!',
      deadline: task.deadline!,
      alertFrequency: task.alertFrequency,
      customReminder: task.customReminder,
    );
  }
}
