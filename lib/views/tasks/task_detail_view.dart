// views/tasks/task_detail_view.dart
import 'package:app/services/research_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:open_file/open_file.dart';
import 'package:app/models/task.dart';
import 'package:app/models/attachment.dart';
import 'package:app/providers/task_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:app/views/tasks/task_create_view.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app/views/tasks/subtasks/subtask_view.dart';
import 'package:app/utils/app_colors.dart';
import 'package:url_launcher/url_launcher_string.dart';

class TaskDetailView extends StatelessWidget {
  final String taskId;

  const TaskDetailView({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    TaskProvider taskProvider = Provider.of<TaskProvider>(context);

    final task = taskProvider.tasks().firstWhere(
      (t) => t.id == taskId,
      orElse: () {
        return Task(
          id: taskId,
          title: 'Task Not Found',
          description: 'This task does not exist.',
          deadline: DateTime.now(),
          attachments: [],
        );
      },
    );

    final formattedDeadline =
        DateFormat.yMMMd().add_jm().format(task.deadline!.toLocal());
    final formattedCreationDate =
        DateFormat.yMMMd().add_jm().format(task.creationDate.toLocal());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          task.title,
          style: const TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskCreateView(
                    task: task,
                    researchService:
                        Provider.of<ResearchService>(context, listen: false),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              showDeleteOptionsDialog(context, task);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildTaskDetailsCard(context, task, formattedDeadline,
                formattedCreationDate, taskProvider),
            const SizedBox(height: 20),
            _buildAttachmentsSection(context, task, taskProvider),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.list),
              label: const Text("View Subtasks"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubtaskView(taskId: task.id),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskDetailsCard(
      BuildContext context,
      Task task,
      String formattedDeadline,
      String formattedCreationDate,
      TaskProvider taskProvider) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description:',
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              task.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            const Divider(),
            Text(
              'Deadline:',
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              formattedDeadline,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            const Divider(),
            Text(
              'Created On:',
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              formattedCreationDate,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            const Divider(),
            Text(
              'Reward Points:',
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              '${task.points} pts',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            const Divider(),
            Text(
              'Category:',
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              task.category,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            const Divider(),
            Text(
              'Keywords:',
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (task.keywords.isNotEmpty)
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: task.keywords
                    .map((keyword) => Chip(
                          label: Text(keyword),
                          backgroundColor:
                              AppColors.primaryColor.withOpacity(0.1),
                          labelStyle:
                              const TextStyle(color: AppColors.primaryColor),
                        ))
                    .toList(),
              )
            else
              Text(
                "No keywords available",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            const SizedBox(height: 10),
            const Divider(),
            Text(
              'Suggested Research Paper:',
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (task.suggestedPaper != null && task.suggestedPaperUrl != null)
              InkWell(
                onTap: () async {
                  launchUrl(Uri.parse(task.suggestedPaperUrl!));
                },
                child: Text(
                  task.suggestedPaper!,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: AppColors.primaryColor,
                        decoration: TextDecoration.underline,
                      ),
                ),
              )
            else
              Text(
                "No suggested research paper available",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            const SizedBox(height: 10),
            const Divider(),
            Row(
              children: [
                Text(
                  'Completed:',
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Checkbox(
                  value: task.isCompleted,
                  onChanged: (value) {
                    taskProvider.toggleTaskCompletion(task);
                  },
                  activeColor: AppColors.primaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentsSection(
      BuildContext context, Task task, TaskProvider taskProvider) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attachments',
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Add Attachment"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _addAttachment(context, taskProvider),
            ),
            const SizedBox(height: 10),
            if (task.attachments.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: task.attachments.length,
                itemBuilder: (context, index) {
                  final attachment = task.attachments[index];
                  return ListTile(
                    leading: Icon(
                      _getAttachmentIcon(attachment.type),
                      color: AppColors.primaryColor,
                    ),
                    title: Text(
                      attachment.name,
                      style: const TextStyle(color: Colors.black87),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        taskProvider.removeAttachment(task.id, attachment.id);
                      },
                    ),
                    onTap: () => _openAttachment(attachment),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addAttachment(
      BuildContext context, TaskProvider taskProvider) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final newAttachment = Attachment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: file.name,
        path: file.path ?? '',
        type: AttachmentType.file,
      );

      taskProvider.addAttachment(taskId, newAttachment);
    }
  }

  Future<void> showDeleteOptionsDialog(BuildContext context, Task task) async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    if (task.isRepeating) {
      // Show the three-option dialog for repeating tasks
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Delete Repeating Task"),
            content: const Text(
              "How would you like to delete this repeating task?",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  taskProvider.deleteRepeatingTasks(task, option: "all");
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text("Delete All"),
              ),
              TextButton(
                onPressed: () {
                  taskProvider.deleteRepeatingTasks(task,
                      option: "this_and_following");
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text("This and Following"),
              ),
              TextButton(
                onPressed: () {
                  taskProvider.deleteRepeatingTasks(task, option: "only_this");
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text("Only This"),
              ),
            ],
          );
        },
      );
    } else {
      // Show a Yes/No confirmation dialog for non-repeating tasks
      await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Delete Task"),
            content: const Text("Are you sure you want to delete this task?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false), // No
                child: const Text("No"),
              ),
              TextButton(
                onPressed: () {
                  taskProvider.removeTask(task);
                  Navigator.popUntil(context, (route) => route.isFirst);
                }, // Yes
                child: const Text("Yes"),
              ),
            ],
          );
        },
      );
    }
  }

  IconData _getAttachmentIcon(AttachmentType type) {
    switch (type) {
      case AttachmentType.file:
        return Icons.attach_file;
      case AttachmentType.link:
        return Icons.link;
      case AttachmentType.image:
        return Icons.image;
      case AttachmentType.video:
        return Icons.videocam;
      default:
        return Icons.attachment;
    }
  }

  void _openAttachment(Attachment attachment) async {
    if (attachment.type == AttachmentType.link) {
      final url = attachment.path;
      if (await canLaunchUrlString(url)) {
        await launchUrlString(url);
      } else {
        throw 'Could not launch $url';
      }
    } else if (attachment.type == AttachmentType.file) {
      final filePath = attachment.path;
      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        // Handle error if file could not be opened
      }
    }
  }
}
