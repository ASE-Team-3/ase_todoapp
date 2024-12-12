import 'package:flutter/material.dart';
import 'package:app/models/task.dart';
import 'package:app/views/tasks/task_detail_view.dart';

class PriorityView extends StatelessWidget {
  final List<Task> tasks;

  PriorityView({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final Set<String> categorizedTaskIds = {};

    // Filter tasks dynamically
    final highPriority = tasks.where((task) {
      final isHigh = _isHighPriority(task);
      if (isHigh) categorizedTaskIds.add(task.id);
      return isHigh;
    }).toList();

    final mediumPriority = tasks.where((task) {
      final isMedium =
          _isMediumPriority(task) && !categorizedTaskIds.contains(task.id);
      if (isMedium) categorizedTaskIds.add(task.id);
      return isMedium;
    }).toList();

    final lowPriority = tasks.where((task) {
      final isLow =
          _isLowPriority(task) && !categorizedTaskIds.contains(task.id);
      if (isLow) categorizedTaskIds.add(task.id);
      return isLow;
    }).toList();

    // Remaining tasks that do not match any priority
    final otherTasks =
        tasks.where((task) => !categorizedTaskIds.contains(task.id)).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      children: [
        _buildPrioritySection(
          context,
          title: 'High Priority',
          tasks: highPriority,
          color: Colors.red.shade100,
          iconColor: Colors.red,
          rules: _highPriorityRules(),
        ),
        _buildPrioritySection(
          context,
          title: 'Medium Priority',
          tasks: mediumPriority,
          color: Colors.orange.shade100,
          iconColor: Colors.orange,
          rules: _mediumPriorityRules(),
        ),
        _buildPrioritySection(
          context,
          title: 'Low Priority',
          tasks: lowPriority,
          color: Colors.green.shade100,
          iconColor: Colors.green,
          rules: _lowPriorityRules(),
        ),
        _buildPrioritySection(
          context,
          title: 'Other Tasks',
          tasks: otherTasks,
          color: Colors.blue.shade100,
          iconColor: Colors.blue,
        ),
      ],
    );
  }

  /// Rules for High Priority
  String _highPriorityRules() =>
      "• Points >= 75, deadline within 7 days\n• Points < 75, deadline within 3 days";

  /// Rules for Medium Priority
  String _mediumPriorityRules() =>
      "• Points >= 75, deadline within 14 days\n• Points < 75, deadline within 21 days";

  /// Rules for Low Priority
  String _lowPriorityRules() =>
      "• Points >= 75, deadline within 21 days\n• Points < 75, deadline within 30 days";

  /// Determines if a task is High Priority
  bool _isHighPriority(Task task) {
    final daysUntilDeadline = _calculateDaysUntilDeadline(task.deadline);
    if (task.points >= 75) {
      return daysUntilDeadline <= 7;
    } else {
      return daysUntilDeadline <= 3;
    }
  }

  /// Determines if a task is Medium Priority
  bool _isMediumPriority(Task task) {
    final daysUntilDeadline = _calculateDaysUntilDeadline(task.deadline);
    if (task.points >= 75) {
      return daysUntilDeadline <= 14;
    } else {
      return daysUntilDeadline <= 21;
    }
  }

  /// Determines if a task is Low Priority
  bool _isLowPriority(Task task) {
    final daysUntilDeadline = _calculateDaysUntilDeadline(task.deadline);
    if (task.points >= 75) {
      return daysUntilDeadline <= 21;
    } else {
      return daysUntilDeadline <= 30;
    }
  }

  /// Calculates the number of days remaining until the deadline
  int _calculateDaysUntilDeadline(DateTime? deadline) {
    if (deadline == null) return 0;
    final now = DateTime.now();
    return deadline.difference(now).inDays;
  }

  /// Builds a priority section with a tooltip for rules
  Widget _buildPrioritySection(
    BuildContext context, {
    required String title,
    required List<Task> tasks,
    required Color color,
    required Color iconColor,
    String? rules,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            if (rules != null)
              IconButton(
                icon: Icon(Icons.info_outline, color: iconColor),
                tooltip: rules,
                onPressed: () {
                  _showRulesDialog(context, title, rules);
                },
              ),
          ],
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

  /// Shows a dialog with rules for the priority
  void _showRulesDialog(BuildContext context, String title, String rules) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("$title Rules"),
          content: Text(rules),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  /// Builds a single task card
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
                "Due: ${_formatDate(task.deadline!)}",
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
