// views/home/widget/priority_view.dart
import 'package:flutter/material.dart';
import 'package:app/models/task.dart';
import 'package:app/views/tasks/task_detail_view.dart';

class PriorityView extends StatelessWidget {
  final List<Task> tasks;

  PriorityView({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final highPriority = tasks.where((task) => task.priority == 1).toList();
    final mediumPriority = tasks.where((task) => task.priority == 2).toList();
    final lowPriority = tasks.where((task) => task.priority == 3).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      children: [
        _buildPrioritySection(
          context,
          title: 'High Priority',
          tasks: highPriority,
          color: Colors.red.shade100,
          iconColor: Colors.red,
        ),
        _buildPrioritySection(
          context,
          title: 'Medium Priority',
          tasks: mediumPriority,
          color: Colors.orange.shade100,
          iconColor: Colors.orange,
        ),
        _buildPrioritySection(
          context,
          title: 'Low Priority',
          tasks: lowPriority,
          color: Colors.green.shade100,
          iconColor: Colors.green,
        ),
      ],
    );
  }

  Widget _buildPrioritySection(
    BuildContext context, {
    required String title,
    required List<Task> tasks,
    required Color color,
    required Color iconColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: iconColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        if (tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'No tasks in this priority',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          )
        else
          ...tasks
              .map((task) => _buildTaskCard(context, task, color, iconColor)),
      ],
    );
  }

  Widget _buildTaskCard(
      BuildContext context, Task task, Color color, Color iconColor) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TaskDetailView(taskId: task.id),
          ),
        );
      },
      child: Card(
        color: color,
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: task.isCompleted ? Colors.green : iconColor,
            child: Icon(
              task.isCompleted ? Icons.check : Icons.priority_high,
              color: Colors.white,
            ),
          ),
          title: Text(
            task.title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    task.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                        ),
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                "Due: ${_formatDate(task.deadline)}",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
          trailing: task.isCompleted
              ? Icon(Icons.check_circle, color: Colors.green)
              : null,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}
