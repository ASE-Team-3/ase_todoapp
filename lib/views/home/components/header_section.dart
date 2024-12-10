import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/providers/task_provider.dart';
import 'package:app/utils/app_colors.dart';
import 'package:app/utils/app_str.dart';
import 'package:app/views/home/components/points_summary_text.dart';

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Reduced padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SizedBox(
                width: 36, // Slightly smaller size
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3, // Thinner progress indicator for a cleaner look
                  value: Provider.of<TaskProvider>(context).tasks().isNotEmpty
                      ? Provider.of<TaskProvider>(context).completedTasks /
                      Provider.of<TaskProvider>(context).tasks().length
                      : 0,
                  backgroundColor: Colors.grey[300],
                  valueColor:
                  const AlwaysStoppedAnimation(AppColors.primaryColor),
                ),
              ),
              const SizedBox(width: 16), // Reduced spacing between elements
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStr.mainTitle,
                    style: textTheme.headlineMedium?.copyWith(
                      fontSize: 18, // Slightly smaller font for compactness
                      fontWeight: FontWeight.w600, // Slightly bolder
                    ),
                  ),
                  const SizedBox(height: 2), // Reduced vertical spacing
                  Consumer<TaskProvider>(
                    builder: (context, taskProvider, _) {
                      return Text(
                        "${taskProvider.completedTasks} of ${taskProvider.tasks().length} Tasks Completed",
                        style: textTheme.displaySmall?.copyWith(
                          fontSize: 14, // Reduced font size
                          color: Colors.grey[600],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const PointsSummaryText(),
        ],
      ),
    );
  }
}
