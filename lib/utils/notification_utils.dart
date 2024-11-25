/// Utility functions for managing notifications with throttling.
library notification_utils;

/// A class to manage throttled notifications, ensuring no spam within a defined duration.
class NotificationThrottler {
  DateTime? _lastNotificationTime;

  /// Sends a notification if sufficient time has passed since the last one.
  ///
  /// Parameters:
  /// - [sendNotification]: A callback function to send the actual notification.
  /// - [title]: The title of the notification.
  /// - [body]: The body of the notification.
  /// - [throttleDuration]: The duration to wait before allowing the next notification.
  void sendThrottledNotification({
    required void Function(String title, String body) sendNotification,
    required String title,
    required String body,
    Duration throttleDuration = const Duration(seconds: 5),
  }) {
    final now = DateTime.now();

    if (_lastNotificationTime == null ||
        now.difference(_lastNotificationTime!) > throttleDuration) {
      sendNotification(title, body);
      _lastNotificationTime = now;
    }
  }
}
