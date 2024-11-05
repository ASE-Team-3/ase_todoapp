import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:url_launcher/url_launcher.dart';
import 'package:open_file/open_file.dart';
import 'package:app/models/task.dart';
import 'package:app/models/attachment.dart';
import 'package:app/providers/task_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:app/views/tasks/task_create_view.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'widget/add_subtask_widget.dart';
import 'widget/add_subtask_item_widget.dart';

class TaskDetailView extends StatelessWidget {
  final String taskId;

  const TaskDetailView({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    TaskProvider taskProvider = Provider.of<TaskProvider>(context);

    // Attempt to find the task; handle not found gracefully
    final task = taskProvider.tasks.firstWhere(
      (t) => t.id == taskId,
      orElse: () {
        // Redirect to home if the task is not found
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Task not found. Redirecting to home.')),
          );
          Future.delayed(Duration(seconds: 2), () {
            Navigator.popUntil(context, (route) => route.isFirst);
          });
        });
        // Return a temporary task with a message (or you could handle it differently)
        return Task(
          id: taskId,
          title: 'Task Not Found',
          description: 'This task does not exist.',
          deadline: DateTime.now(),
          attachments: [],
        );
      },
    );

    // Format the dates in local timezone
    final formattedDeadline =
        DateFormat.yMMMd().add_jm().format(task.deadline.toLocal());
    final formattedCreationDate =
        DateFormat.yMMMd().add_jm().format(task.creationDate.toLocal());

    return Scaffold(
      appBar: AppBar(
        title: Text(task.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to the TaskView screen for editing
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskView(task: task),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Task Details Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Task Description
                    Text('Description:',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 5),
                    Text(task.description,
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 10),

                    Divider(),

                    // Display formatted Task Deadline
                    Text('Deadline:',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 5),
                    Text(formattedDeadline,
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 10),

                    Divider(),

                    // Display formatted Task Creation Date
                    Text('Created On:',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 5),
                    Text(formattedCreationDate,
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 10),

                    Divider(),

                    // Task Completion Status
                    Row(
                      children: [
                        Text('Completed:',
                            style: Theme.of(context).textTheme.headlineMedium),
                        Checkbox(
                          value: task.isCompleted,
                          onChanged: (value) {
                            taskProvider.toggleTaskCompletion(task);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Attachments Section
            _buildAttachmentsSection(context, task, taskProvider),

            const SizedBox(height: 20),

            // Subtasks Section
            _buildSubtasksSection(context, task, taskProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentsSection(
      BuildContext context, Task task, TaskProvider taskProvider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Attachments',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Add Attachment"),
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
                    leading: Icon(_getAttachmentIcon(attachment.type)),
                    title: Text(attachment.name),
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

  Widget _buildSubtasksSection(
      BuildContext context, Task task, TaskProvider taskProvider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subtasks', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 10),
            if (task.subTasks.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: task.subTasks.length,
                itemBuilder: (context, index) {
                  final subTask = task.subTasks[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ExpansionTile(
                      title: Text(subTask.title),
                      subtitle: Text(subTask.description),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: subTask.isCompleted,
                            onChanged: (value) {
                              taskProvider.toggleTaskCompletion(task);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              taskProvider.removeSubTask(task.id, subTask.id);
                            },
                          ),
                        ],
                      ),
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: subTask.items.length,
                          itemBuilder: (context, itemIndex) {
                            final item = subTask.items[itemIndex];
                            return ListTile(
                              title: Text(item.title),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Checkbox(
                                    value: item.isCompleted,
                                    onChanged: (value) {
                                      taskProvider.toggleSubTaskItemCompletion(
                                          task.id, subTask.id, item.id);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () {
                                      taskProvider.removeSubTaskItem(
                                          task.id, subTask.id, item.id);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        AddSubTaskItemWidget(
                            taskId: task.id, subTaskId: subTask.id),
                      ],
                    ),
                  );
                },
              ),
            AddSubTaskWidget(taskId: task.id),
          ],
        ),
      ),
    );
  }

  // Function to add an attachment
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

  // Helper to get an icon based on attachment type
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

  // Open the attachment based on its type
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
        // TODO: Handle error if file could not be opened
      }
    }
  }
}
