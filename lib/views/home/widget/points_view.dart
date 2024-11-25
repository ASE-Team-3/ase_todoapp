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
        const Divider(thickness: 2, indent: 20, endIndent: 20),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                Text(
                  AppStr.analyzePointsTrend,
                  style: textTheme.bodyLarge
                      ?.copyWith(color: AppColors.primaryColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Expanded(child: PointsTrendChart()), // Modularized Chart
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
