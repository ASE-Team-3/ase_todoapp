import 'dart:developer';

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzData;
import 'package:timezone/timezone.dart' as tz;

Future<void> initializeTimeZones() async {
  tzData.initializeTimeZones();

  // Get the local timezone from the device
  final String localTimeZone = await FlutterTimezone.getLocalTimezone();
  log('Local timezone: $localTimeZone');

  tz.setLocalLocation(tz.getLocation(localTimeZone));
}
