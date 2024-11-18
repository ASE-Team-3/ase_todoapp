// utils/deadline_utils.dart
import 'package:flutter/material.dart';

/// Converts a flexible deadline string into a specific `DateTime`.
DateTime? calculateDeadlineFromFlexible(String flexibleDeadline) {
  final DateTime now = DateTime.now();

  switch (flexibleDeadline) {
    case "Today":
      return DateTime(now.year, now.month, now.day, 23, 59); // End of today
    case "This Week":
      final int daysToEndOfWeek = 7 - now.weekday;
      return DateTime(now.year, now.month, now.day + daysToEndOfWeek, 23,
          59); // End of the week
    case "No Deadline":
      return null; // Explicitly no deadline
    default:
      debugPrint("Unknown flexible deadline: $flexibleDeadline");
      return null; // Unknown flexible deadline
  }
}
