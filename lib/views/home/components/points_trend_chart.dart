import 'package:app/models/points_history_entry.dart';
import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/providers/task_provider.dart';
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
      List<PointsHistoryEntry> pointsHistory, String interval) {
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
        groupedData[key] = (groupedData[key] ?? 0) +
            (entry.action == 'Awarded' ? entry.points : -entry.points);
      }
    }

    return groupedData;
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final pointsHistory = taskProvider.pointsHistory;

    // Group points and convert to bar groups
    final groupedData =
        _groupPointsByInterval(pointsHistory, _selectedInterval);

    // Find min and max for y-axis scaling
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
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
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
                        color: AppColors.primaryColor,
                      ),
                ),
                DropdownButton<String>(
                  value: _selectedInterval,
                  underline: Container(), // Remove default underline
                  onChanged: (value) async {
                    if (value == "Custom") {
                      final result = await showDateRangePicker(
                        context: context,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: AppColors
                                    .primaryColor, // Header background color
                                onPrimary: Colors.white, // Header text color
                                onSurface: Colors.black, // Body text color
                              ),
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors
                                      .primaryColor, // Button text color
                                ),
                              ),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                // Use a SingleChildScrollView for responsiveness
                                return SingleChildScrollView(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          400, // Limit modal width for large screens
                                      maxHeight:
                                          MediaQuery.of(context).size.height *
                                              0.9, // 90% height
                                    ),
                                    child: child,
                                  ),
                                );
                              },
                            ),
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
                              style: const TextStyle(fontSize: 14),
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
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            pointsHistory.isNotEmpty
                ? SizedBox(
                    height: 250,
                    child: BarChart(
                      BarChartData(
                        maxY: maxPositive + 10.0, // Add padding to the top
                        minY: maxNegative - 10.0, // Allow space for deductions
                        barGroups:
                            groupedData.entries.mapIndexed((index, entry) {
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: entry.value, // Height of the bar
                                width: 8, // Slimmer bar width
                                color: entry.value >= 0
                                    ? AppColors.primaryColor // Positive bar
                                    : Colors.red, // Negative bar
                                borderRadius:
                                    BorderRadius.circular(4), // Rounded bars
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
                                  style: const TextStyle(fontSize: 12),
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
                                  final key = groupedData.keys
                                      .elementAt(index); // Date key
                                  return Text(
                                    key,
                                    style: const TextStyle(fontSize: 10),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                              interval: 1,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: const Border(
                            left: BorderSide(color: Colors.grey),
                            bottom: BorderSide(color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  )
                : const Center(
                    child: Text(
                      "No points data available.",
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}