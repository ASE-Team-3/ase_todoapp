/// Utility functions for `DateTime` operations.
library datetime_utils;

import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/timezone.dart'; // Only import what we need

/// Converts a `DateTime` object from UTC to the user's local timezone.
///
/// If the input is null, this function returns null.
///
/// Parameters:
/// - [utcTime]: The `DateTime` object in UTC.
///
/// Returns:
/// - A `DateTime` object converted to local timezone or null if input is null.
DateTime? convertUtcToLocal(DateTime? utcTime) {
  if (utcTime == null) return null;
  return utcTime.toLocal();
}

/// Converts a `DateTime` to `TZDateTime` for the local timezone.
TZDateTime convertToTZDateTime(DateTime time) {
  final location = tz.local; // Use local timezone
  return TZDateTime.from(time, location);
}
