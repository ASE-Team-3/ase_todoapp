import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';

List<FlSpot> _getSpotsFromGroupedData(Map<String, double> groupedData) {
  int index = 0;
  return groupedData.entries.map((entry) {
    final spot = FlSpot(index.toDouble(), entry.value);
    index++;
    return spot;
  }).toList();
}

void main() {
  group('PointsTrendChart - _getSpotsFromGroupedData', () {
    test('should map grouped data into FlSpot list correctly', () {
      // Arrange
      final groupedData = {
        "2024-11-01": 10.0,
        "2024-11-02": 20.0,
        "2024-11-03": 30.0,
      };

      // Act
      final result = _getSpotsFromGroupedData(groupedData);

      // Assert
      expect(result.length, groupedData.length);
      for (int i = 0; i < groupedData.length; i++) {
        expect(result[i].x, i.toDouble()); // Verify x-axis index
        expect(result[i].y,
            groupedData.values.elementAt(i)); // Verify y-axis value
      }
    });

    test('should handle empty grouped data', () {
      // Arrange
      final groupedData = <String, double>{};

      // Act
      final result = _getSpotsFromGroupedData(groupedData);

      // Assert
      expect(result, isEmpty);
    });

    test('should handle grouped data with single entry', () {
      // Arrange
      final groupedData = {"2024-11-01": 50.0};

      // Act
      final result = _getSpotsFromGroupedData(groupedData);

      // Assert
      expect(result.length, 1);
      expect(result.first.x, 0.0); // First index
      expect(result.first.y, 50.0); // Y-axis value
    });
  });
}
