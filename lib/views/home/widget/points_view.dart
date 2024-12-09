import 'package:app/utils/app_str.dart';
import 'package:app/views/home/components/header_section.dart';
import 'package:app/views/home/components/near_deadline_tasks_section.dart';
import 'package:app/views/home/components/points_trend_chart.dart';
import 'package:flutter/material.dart';
import 'package:app/utils/app_colors.dart';

class PointsView extends StatelessWidget {
  const PointsView({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HeaderSection(), // Modularized Header
        const Divider(
          thickness: 1.5,
          color: Colors.grey, // Soft gray divider color
          indent: 20,
          endIndent: 20,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Align content to the left
              children: [
                Text(
                  AppStr.analyzePointsTrend,
                  style: textTheme.headlineSmall?.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFF7F9FC), // Light gray background
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Expanded(child: PointsTrendChart()), // Modularized Chart
                ),


                const SizedBox(height: 16),
                const NearDeadlineTasksSection(), // Modularized Tasks
              ],
            ),
          ),
        ),
      ],
    );
  }
}
