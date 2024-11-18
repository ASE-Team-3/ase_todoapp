import 'package:flutter_test/flutter_test.dart';
import 'package:app/utils/deadline_utils.dart'; // Update the import path based on your project structure

void main() {
  group('calculateDeadlineFromFlexible', () {
    test('should return today\'s end time for "Today"', () {
      final now = DateTime.now();
      final result = calculateDeadlineFromFlexible("Today");
      final expected = DateTime(now.year, now.month, now.day, 23, 59);

      expect(result, equals(expected));
    });

    test('should return the end of the week for "This Week"', () {
      final now = DateTime.now();
      final int daysToEndOfWeek = 7 - now.weekday;
      final result = calculateDeadlineFromFlexible("This Week");
      final expected =
          DateTime(now.year, now.month, now.day + daysToEndOfWeek, 23, 59);

      expect(result, equals(expected));
    });

    test('should return the last minute of the current month for "This Month"',
        () {
      final now = DateTime.now();
      final firstDayOfNextMonth = DateTime(now.year, now.month + 1, 1);
      final result = calculateDeadlineFromFlexible("This Month");
      final expected = firstDayOfNextMonth.subtract(const Duration(minutes: 1));

      expect(result, equals(expected));
    });

    test('should return the last minute of the current year for "This Year"',
        () {
      final now = DateTime.now();
      final startOfNextYear = DateTime(now.year + 1, 1, 1);
      final result = calculateDeadlineFromFlexible("This Year");
      final expected = startOfNextYear.subtract(const Duration(minutes: 1));

      expect(result, equals(expected));
    });

    test('should return null for unknown flexible deadline', () {
      final result = calculateDeadlineFromFlexible("Unknown Option");

      expect(result, isNull);
    });

    test('should return null if predefinedDeadlines has no matching key', () {
      final result = calculateDeadlineFromFlexible("Nonexistent");

      expect(result, isNull);
    });
  });
}
