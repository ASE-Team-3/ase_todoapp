import 'package:permission_handler/permission_handler.dart';

Future<void> requestNotificationPermission() async {
  if (await Permission.notification.isGranted) {
    return; // Permission already granted
  }

  final status = await Permission.notification.request();
  if (status.isDenied) {
    throw Exception('Notification permission denied.');
  } else if (status.isPermanentlyDenied) {
    throw Exception(
        'Notification permission permanently denied. Go to app settings to enable it.');
  }
}
