import 'package:app/utils/constrants.dart';
import 'package:flutter/material.dart';
import 'package:app/models/task.dart';
import 'package:app/views/tasks/task_detail_view.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:animate_do/animate_do.dart';
import 'package:app/utils/app_str.dart';

class DueDateView extends StatelessWidget {
  final List<Task> tasks;

  DueDateView({required this.tasks});

  @override
  Widget build(BuildContext context) {
    tasks.sort((a, b) => a.deadline!.compareTo(b.deadline!));

    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));

    final todayTasks =
    tasks.where((task) => _isSameDay(task.deadline!, today)).toList();
    final tomorrowTasks =
    tasks.where((task) => _isSameDay(task.deadline!, tomorrow)).toList();
    final upcomingTasks =
    tasks.where((task) => task.deadline!.isAfter(tomorrow)).toList();

    final hasTasks = todayTasks.isNotEmpty ||
        tomorrowTasks.isNotEmpty ||
        upcomingTasks.isNotEmpty;

    return hasTasks
        ? ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _buildDateSection(
            context, 'Today', todayTasks, const Color(0xFFFFF5E7)), // Light peach for today
        _buildDateSection(
            context, 'Tomorrow', tomorrowTasks, const Color(0xFFE8F5E9)), // Light green for tomorrow
        _buildDateSection(
            context, 'Upcoming', upcomingTasks, const Color(0xFFE3F2FD)), // Light blue for upcoming
      ],
    )
        : _buildEmptyState(Theme.of(context).textTheme);
  }

  Widget _buildDateSection(BuildContext context, String title, List<Task> tasks,
      Color backgroundColor) {
    if (tasks.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...tasks.map((task) => _buildTaskCard(context, task, backgroundColor)),
      ],
    );
  }

  Widget _buildTaskCard(
      BuildContext context, Task task, Color backgroundColor) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TaskDetailView(taskId: task.id),
          ),
        );
      },
      child: Card(
        color: backgroundColor,
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Slightly rounded corners
        ),
        elevation: 3,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: task.isCompleted
                ? const Color(0xFF34C759) // iOS green
                : const Color(0xFF007AFF), // iOS blue
            child: Icon(
              task.isCompleted ? Icons.check : Icons.event,
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
              ? const Icon(Icons.check_circle, color: Color(0xFF34C759)) // iOS green
              : null,
        ),
      ),
    );
  }

  Widget _buildEmptyState(TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeIn(
            child: SizedBox(
              width: 200,
              height: 200,
              child: Lottie.asset(lottieURL,
                  animate: true), // Use the correct asset path
            ),
          ),
          FadeInUp(
            from: 30,
            child: Text(
              AppStr.doneAllTask,
              style: textTheme.headlineSmall?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatDate(DateTime date) {
    final formatter = DateFormat('yyyy/MM/dd');
    return formatter.format(date);
  }
}
