import 'package:app/models/points_history.dart';
import 'package:app/services/task_firestore_service.dart';
import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:app/utils/app_colors.dart';
import 'package:intl/intl.dart';

class PointsTrendChart extends StatefulWidget {
  const PointsTrendChart({super.key});

  @override
  State<PointsTrendChart> createState() => _PointsTrendChartState();
}

class _PointsTrendChartState extends State<PointsTrendChart> {
  String _selectedInterval = "Week"; // Default filter
  DateTimeRange? _customRange;

  List<String> get intervals => ["Week", "Month", "Year", "Custom"];

  /// Groups points by day or month and calculates totals based on action
  Map<String, double> _groupPointsByInterval(
      List<PointsHistory> pointsHistory, String interval) {
    DateTime now = DateTime.now();
    DateTime startDate;

    switch (interval) {
      case "Week":
        startDate = now.subtract(const Duration(days: 7));
        break;
      case "Month":
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case "Year":
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      case "Custom":
        startDate =
            _customRange?.start ?? now.subtract(const Duration(days: 7));
        break;
      default:
        startDate = now.subtract(const Duration(days: 7));
    }

    final dateFormat = interval == "Year" ? 'MM/yyyy' : 'MM/dd';

    // Group by day/month and calculate total points
    Map<String, double> groupedData = {};
    for (var entry in pointsHistory) {
      if (entry.timestamp.isAfter(startDate)) {
        final key = DateFormat(dateFormat).format(entry.timestamp);
        groupedData[key] = (groupedData[key] ?? 0) + entry.points;
      }
    }

    return groupedData;
  }

  @override
  Widget build(BuildContext context) {
    final taskService = TaskFirestoreService();

    return StreamBuilder<List<PointsHistory>>(
      stream: taskService.getPointsHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error loading points data: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              "No points data available.",
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
          );
        }

        final pointsHistory = snapshot.data!;
        final groupedData =
            _groupPointsByInterval(pointsHistory, _selectedInterval);

        final maxPositive = groupedData.values.fold<double>(
          0.0,
          (prev, curr) => curr > prev ? curr : prev,
        );
        final maxNegative = groupedData.values.fold<double>(
          0.0,
          (prev, curr) => curr < prev ? curr : prev,
        );

        return Card(
          elevation: 4,
          margin: const EdgeInsets.all(12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: const Color(0xFFF7F9FC),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Filter Dropdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Points Trend Analysis",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF007AFF),
                          ),
                    ),
                    DropdownButton<String>(
                      value: _selectedInterval,
                      underline: Container(),
                      onChanged: (value) async {
                        if (value == "Custom") {
                          final result = await showDateRangePicker(
                            context: context,
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: Color(0xFF007AFF),
                                    onPrimary: Colors.white,
                                    onSurface: Colors.black,
                                  ),
                                  textButtonTheme: TextButtonThemeData(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Color(0xFF007AFF),
                                    ),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                            initialDateRange: _customRange ??
                                DateTimeRange(
                                  start: DateTime.now()
                                      .subtract(const Duration(days: 7)),
                                  end: DateTime.now(),
                                ),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );

                          if (result != null) {
                            setState(() {
                              _customRange = result;
                              _selectedInterval = "Custom";
                            });
                          }
                        } else {
                          setState(() {
                            _selectedInterval = value!;
                            _customRange = null;
                          });
                        }
                      },
                      items: intervals
                          .map((interval) => DropdownMenuItem(
                                value: interval,
                                child: Text(
                                  interval,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ))
                          .toList(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      dropdownColor: Colors.white,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFF007AFF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  child: BarChart(
                    BarChartData(
                      maxY: maxPositive + 10.0,
                      minY: maxNegative - 10.0,
                      barGroups: groupedData.entries.mapIndexed((index, entry) {
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value,
                              width: 6,
                              color: entry.value >= 0
                                  ? const Color(0xFF34C759)
                                  : const Color(0xFFFF3B30),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }).toList(),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 10,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.shade300,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              );
                            },
                            interval: 20,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < groupedData.keys.length) {
                                return Text(
                                  groupedData.keys.elementAt(index),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.black87,
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                            interval: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
