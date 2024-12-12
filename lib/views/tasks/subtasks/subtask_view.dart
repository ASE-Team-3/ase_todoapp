import 'package:app/utils/app_colors.dart';
import 'package:app/views/tasks/subtasks/subtask_detail_view.dart';
import 'package:app/views/tasks/widget/add_subtask_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/models/subtask.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app/models/task.dart';
import 'package:app/services/task_firestore_service.dart';

class SubtaskView extends StatelessWidget {
  final String taskId;

  const SubtaskView({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    final taskService =
        Provider.of<TaskFirestoreService>(context, listen: false);

    return StreamBuilder<Task>(
      stream: taskService
          .getTaskWithSubtasks(taskId), // Watch task with subtasks in real-time
      builder: (context, taskSnapshot) {
        if (taskSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (taskSnapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: _buildAppBar('Subtasks'),
            body: const Center(child: Text('Error loading task')),
          );
        } else if (taskSnapshot.hasData && taskSnapshot.data != null) {
          final task = taskSnapshot.data!;

          // Listen to the subtasks collection
          return StreamBuilder<List<SubTask>>(
            stream:
                taskService.getSubTasks(taskId), // Subtasks collection stream
            builder: (context, subtaskSnapshot) {
              final List<SubTask> subTasks = subtaskSnapshot.data ??
                  task.subTasks; // Fallback to task.subTasks if stream fails

              return Scaffold(
                backgroundColor: Colors.white,
                appBar: _buildAppBar('${task.title} - Subtasks'),
                body: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (subTasks.isNotEmpty)
                        Expanded(
                          child: ListView.builder(
                            itemCount: subTasks.length,
                            itemBuilder: (context, index) {
                              final subTask = subTasks[index];
                              return _buildSubTaskCard(context, task, subTask);
                            },
                          ),
                        )
                      else
                        const Center(
                          child: Text(
                            "No Subtasks available. Add one below!",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                      const SizedBox(height: 20),
                      _buildAddSubtaskButton(context),
                    ],
                  ),
                ),
              );
            },
          );
        } else {
          return const Center(child: Text('Task not found'));
        }
      },
    );
  }

  /// Builds the app bar with a given title
  AppBar _buildAppBar(String title) {
    return AppBar(
      backgroundColor: Colors.white,
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.black),
      ),
      iconTheme: const IconThemeData(color: Colors.black),
      elevation: 0,
    );
  }

  /// Builds the Add Subtask button
  Widget _buildAddSubtaskButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: AddSubTaskWidget(taskId: taskId),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: const Text('Add Subtask', style: TextStyle(fontSize: 16)),
    );
  }

  /// Builds each subtask card
  Widget _buildSubTaskCard(BuildContext context, Task task, SubTask subTask) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        title: Text(
          subTask.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSubTaskStatus(subTask),
            if (subTask.author != null)
              Text('Author: ${subTask.author!}',
                  style: const TextStyle(color: Colors.black54)),
            if (subTask.publishDate != null)
              Text('Publish Date: ${subTask.publishDate!}',
                  style: const TextStyle(color: Colors.black54)),
            if (subTask.url != null)
              GestureDetector(
                onTap: () async {
                  final uri = Uri.parse(subTask.url!);
                  try {
                    await launchUrl(uri); // Try launching the URL directly
                  } catch (e) {
                    // If an error occurs, show a fallback message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open URL')),
                    );
                  }
                },
                child: Text(
                  subTask.url!,
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: subTask.isCompleted,
              onChanged: (value) async {
                try {
                  await context
                      .read<TaskFirestoreService>()
                      .toggleSubTaskCompletion(task.id, subTask);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Subtask "${subTask.title}" updated successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              },
              activeColor: AppColors.primaryColor,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _confirmDeleteSubTask(context, task, subTask.id);
              },
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubTaskDetailView(
                taskId: task.id,
                subTaskId: subTask.id,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds the subtask status text
  Widget _buildSubTaskStatus(SubTask subTask) {
    switch (subTask.status) {
      case SubtaskStatus.pending:
        return const Text('Status: Pending',
            style: TextStyle(color: Colors.black54));
      case SubtaskStatus.inProgress:
        return const Text('Status: In Progress',
            style: TextStyle(color: Colors.black54));
      case SubtaskStatus.completed:
        return const Text('Status: Completed',
            style: TextStyle(color: Colors.green));
      default:
        return const SizedBox.shrink();
    }
  }

  /// Confirms and deletes a subtask
  void _confirmDeleteSubTask(
      BuildContext context, Task task, String subTaskId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Subtask'),
          content: const Text('Are you sure you want to delete this subtask?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                context
                    .read<TaskFirestoreService>()
                    .removeSubTask(task.id, subTaskId);
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
