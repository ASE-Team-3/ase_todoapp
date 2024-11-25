import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/providers/task_provider.dart';
import 'package:app/utils/app_colors.dart'; // Import AppColors

class PointsSummaryText extends StatelessWidget {
  const PointsSummaryText({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "Reward Points",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor, // Use AppColors.primaryColor
              ),
        ),
        const SizedBox(height: 4),
        Text(
          "${taskProvider.totalPoints} pts",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor, // Use AppColors.primaryColor
              ),
        ),
      ],
    );
  }
}
