// views/tasks/task_detail_view.dart
import 'package:app/models/subtask.dart';
import 'package:app/services/openai_service.dart';
import 'package:app/services/research_service.dart';
import 'package:app/utils/app_str.dart';
import 'package:app/views/tasks/widget/ai_feedback_widget.dart';
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
          title: AppStr.taskNotFoundTitle,
          description: AppStr.taskNotFoundDescription,
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
            _buildAiFeedbackSection(context, task),
            const SizedBox(height: 20),
            _buildAttachmentsSection(context, task, taskProvider),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.list),
              label: const Text(AppStr.viewSubtasksButton),
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
              AppStr.taskDescriptionLabel,
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
              AppStr.deadlineLabel,
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
              AppStr.creationDateLabel,
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
              AppStr.rewardPointsLabel,
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
              AppStr.categoryLabel,
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              task.category,
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            // Keywords (Only for Research category)
            if (task.category == "Research") ...[
              const SizedBox(height: 10),
              const Divider(),
              Text(
                AppStr.keywordsLabel,
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
                  AppStr.noKeywordsMessage,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],

            // Suggested Paper (Only for Research category)
            if (task.category == "Research") ...[
              const SizedBox(height: 10),
              const Divider(),
              Text(
                AppStr.suggestedPaperLabel,
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (task.suggestedPaper != null &&
                  task.suggestedPaperUrl != null &&
                  task.suggestedPaper != "No title available" &&
                  task.suggestedPaperUrl != "No DOI available") ...[
                InkWell(
                  onTap: () async {
                    final url = Uri.parse(task.suggestedPaperUrl!);
                    await launchUrl(url);
                  },
                  child: Text(
                    task.suggestedPaper!,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: AppColors.primaryColor,
                          decoration: TextDecoration.underline,
                        ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_task),
                  label: const Text("Add Suggested Paper as Subtask"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    final subTask = SubTask(
                      title: task.suggestedPaper!,
                      description: "Suggested research paper",
                      type: SubTaskType.paper,
                      author: task.suggestedPaperAuthor,
                      publishDate: task.suggestedPaperPublishDate,
                      url: task.suggestedPaperUrl,
                    );

                    final taskProvider =
                        Provider.of<TaskProvider>(context, listen: false);
                    taskProvider.addSubTask(task.id, subTask);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Suggested paper added as a subtask!")),
                    );
                  },
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text("Refresh Suggested Paper"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    final taskProvider =
                        Provider.of<TaskProvider>(context, listen: false);
                    try {
                      await taskProvider.refreshSuggestedPaper(task.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Suggested paper refreshed!")),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text("Error refreshing suggested paper: $e")),
                      );
                    }
                  },
                ),
              ] else
                Text(
                  task.suggestedPaper ?? AppStr.noSuggestedPaperMessage,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],

            const SizedBox(height: 10),
            const Divider(),

            // Completed Checkbox
            Row(
              children: [
                Text(
                  AppStr.completedLabel,
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

  Widget _buildAiFeedbackSection(BuildContext context, Task task) {
    return FutureBuilder<Map<String, String>>(
      future: fetchAIFeedback(context, task),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Column(
            children: [
              Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () {
                  (context as Element).markNeedsBuild();
                },
                icon: const Icon(Icons.refresh),
                label: const Text("Try Again"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        } else if (snapshot.hasData) {
          final feedback = snapshot.data!;
          return AIFeedbackWidget(
            feedbackMessage:
                feedback['message'] ?? "No motivational message available",
            recommendation:
                feedback['recommendation'] ?? "No recommendation available",
            onRefresh: () async {
              // Re-fetch AI feedback
              await fetchAIFeedback(context, task);
            },
          );
        }

        // Fallback widget in case no state is matched
        return const Center(
          child: Text("No AI feedback available."),
        );
      },
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
              AppStr.attachmentsLabel,
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text(AppStr.addAttachmentLabel),
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
            title: const Text(AppStr.deleteRepeatingTaskTitle),
            content: const Text(
              AppStr.deleteRepeatingTaskContent,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  taskProvider.deleteRepeatingTasks(task, option: "all");
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text(AppStr.deleteAllButton),
              ),
              TextButton(
                onPressed: () {
                  taskProvider.deleteRepeatingTasks(task,
                      option: "this_and_following");
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text(AppStr.deleteThisAndFollowingButton),
              ),
              TextButton(
                onPressed: () {
                  taskProvider.deleteRepeatingTasks(task, option: "only_this");
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text(AppStr.deleteOnlyThisButton),
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
            title: const Text(AppStr.deleteTask),
            content: const Text(AppStr.deleteTaskConfirmationMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false), // No
                child: const Text(AppStr.noButton),
              ),
              TextButton(
                onPressed: () {
                  taskProvider.removeTask(task);
                  Navigator.popUntil(context, (route) => route.isFirst);
                }, // Yes
                child: const Text(AppStr.yesButton),
              ),
            ],
          );
        },
      );
    }
  }

  Future<Map<String, String>> fetchAIFeedback(
      BuildContext context, Task task) async {
    final openAIService = Provider.of<OpenAIService>(context, listen: false);

    try {
      return await openAIService.analyzeTask(task);
    } catch (e, stackTrace) {
      debugPrint("Error fetching AI feedback: $e");
      debugPrint("Stack trace: $stackTrace");
      return {
        "message": "Unable to fetch AI feedback",
        "recommendation": "",
      };
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
