// utils/deadline_utils.dart
import 'package:flutter/material.dart';

/// Predefined deadlines map
final Map<String, DateTime? Function()> predefinedDeadlines = {
  "Today": () {
    // End of the current day
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 59);
  },
  "This Week": () {
    // End of the current week (Sunday, 23:59)
    final DateTime now = DateTime.now();
    final int daysToEndOfWeek = 7 - now.weekday;
    return DateTime(now.year, now.month, now.day + daysToEndOfWeek, 23, 59);
  },
  "This Month": () {
    // Last minute of the current month
    final DateTime now = DateTime.now();
    final DateTime firstDayOfNextMonth = DateTime(now.year, now.month + 1, 1);
    return firstDayOfNextMonth.subtract(const Duration(minutes: 1));
  },
  "This Year": () {
    // Last minute of the current year
    final DateTime now = DateTime.now();
    return DateTime(now.year + 1, 1, 1).subtract(const Duration(minutes: 1));
  },
  // "Specific Deadline" requires user input, so it's not precomputed
};

/// Converts a flexible deadline string into a specific `DateTime` based on the map.
DateTime? calculateDeadlineFromFlexible(String flexibleDeadline) {
  final deadlineCalculator = predefinedDeadlines[flexibleDeadline];
  if (deadlineCalculator != null) {
    return deadlineCalculator();
  } else {
    debugPrint("Unknown flexible deadline: $flexibleDeadline");
    return null; // Handle unknown options gracefully
  }
}
