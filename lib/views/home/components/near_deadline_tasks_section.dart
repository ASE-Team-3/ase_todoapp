import 'package:app/providers/task_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/utils/app_colors.dart';
import 'package:app/utils/app_str.dart';
import 'package:app/views/home/home_view.dart';

class NearDeadlineTasksSection extends StatelessWidget {
  const NearDeadlineTasksSection({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final textTheme = Theme.of(context).textTheme;

    // Get tasks sorted by deadline
    final nearDeadlineTasks = taskProvider
        .tasks()
        .where((task) => task.deadline != null && !task.isCompleted)
        .toList()
      ..sort((a, b) => a.deadline!.compareTo(b.deadline!));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStr.nearDeadlineTasks,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        if (nearDeadlineTasks.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: nearDeadlineTasks.length > 3
                ? 3
                : nearDeadlineTasks.length, // Limit to 3 tasks
            itemBuilder: (context, index) {
              final task = nearDeadlineTasks[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  title: Text(
                    task.title,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    "Due: ${task.deadline?.toLocal().toString().split(' ')[0]}",
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  trailing: const Icon(
                    Icons.priority_high,
                    color: AppColors.primaryColor,
                  ),
                ),
              );
            },
          )
        else
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              AppStr.noNearDeadlineTasks,
              style: textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ),
        const SizedBox(height: 8),
        Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const HomeView(
                    initialView: 'Due Date',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text(AppStr.showMoreButton),
          ),
        ),
      ],
    );
  }
}
