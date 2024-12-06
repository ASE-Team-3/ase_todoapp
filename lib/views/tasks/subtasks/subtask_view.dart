import 'package:app/utils/app_colors.dart';
import 'package:app/views/tasks/widget/add_subtask_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/providers/task_provider.dart';
import 'package:app/views/tasks/subtasks/subtask_detail_view.dart';
import 'package:app/models/subtask.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app/models/task.dart';
import 'package:app/services/task_firestore_service.dart';

class SubtaskView extends StatelessWidget {
  final String taskId;

  const SubtaskView({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Task>(
      future: Provider.of<TaskFirestoreService>(context, listen: false).getTaskById(taskId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              title: const Text(
                'Subtasks',
                style: TextStyle(color: Colors.black),
              ),
              iconTheme: const IconThemeData(color: Colors.black),
            ),
            body: const Center(child: Text('Error loading task')),
          );
        } else if (snapshot.hasData) {
          final task = snapshot.data!;
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              title: Text(
                '${task.title} - Subtasks',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black),
              ),
              iconTheme: const IconThemeData(color: Colors.black),
              elevation: 0,
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (task.subTasks.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        itemCount: task.subTasks.length,
                        itemBuilder: (context, index) {
                          final subTask = task.subTasks[index];
                          return _buildSubTaskCard(context, task, subTask);
                        },
                      ),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
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
                      padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Add Subtask', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          );
        } else {
          return const Center(child: Text('Task not found'));
        }
      },
    );
  }

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
            // Check for specific subtask status and display accordingly
            if (subTask.status == SubtaskStatus.pending) ...[
              Text(
                'Status: Pending',
                style: const TextStyle(color: Colors.black54),
              ),
            ] else if (subTask.status == SubtaskStatus.inProgress) ...[
              Text(
                'Status: In Progress',
                style: const TextStyle(color: Colors.black54),
              ),
            ] else if (subTask.status == SubtaskStatus.completed) ...[
              Text(
                'Status: Completed',
                style: const TextStyle(color: Colors.black54),
              ),
            ],
            // Handle other subtask details
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
              value: subTask.status == SubtaskStatus.completed,
              onChanged: (value) {
                context.read<TaskFirestoreService>().updateSubTaskStatus(
                    task.id, subTask.id, SubtaskStatus.completed);
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

  void _confirmDeleteSubTask(BuildContext context, Task task, String subTaskId) {
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
                context.read<TaskFirestoreService>().removeSubTask(task.id, subTaskId);
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
