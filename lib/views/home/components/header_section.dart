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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  value: Provider.of<TaskProvider>(context).tasks().isNotEmpty
                      ? Provider.of<TaskProvider>(context).completedTasks /
                          Provider.of<TaskProvider>(context).tasks().length
                      : 0,
                  backgroundColor: Colors.grey[300],
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.primaryColor),
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStr.mainTitle, style: textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Consumer<TaskProvider>(
                    builder: (context, taskProvider, _) {
                      return Text(
                        "${taskProvider.completedTasks} of ${taskProvider.tasks().length} Tasks Completed",
                        style: textTheme.displaySmall?.copyWith(
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
