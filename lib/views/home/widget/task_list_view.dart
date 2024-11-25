import 'package:flutter/material.dart';
import 'package:app/models/task.dart';
import 'package:provider/provider.dart';
import 'package:app/providers/task_provider.dart';
import 'package:app/views/home/widget/task_widget.dart';

class TaskListView extends StatelessWidget {
  final List<Task> tasks;

  const TaskListView({required this.tasks, super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);

    return tasks.isNotEmpty
        ? ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return TaskWidget(
                task: task,
                onToggleComplete: () =>
                    taskProvider.toggleTaskCompletion(task), // Provide callback
              );
            },
          )
        : const Center(
            child: Text("No tasks available."),
          );
  }
}
