import 'package:app/models/subtask.dart';
import 'package:app/providers/task_provider.dart';
import 'package:app/services/openai_service.dart';
import 'package:app/services/research_service.dart';
import 'package:app/services/task_firestore_service.dart'; // Add Firestore service import
import 'package:app/utils/app_str.dart';
import 'package:app/views/tasks/widget/ai_feedback_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:open_file/open_file.dart';
import 'package:app/models/task.dart';
import 'package:app/models/attachment.dart';
import 'package:file_picker/file_picker.dart';
import 'package:app/views/tasks/task_create_view.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app/views/tasks/subtasks/subtask_view.dart';
import 'package:app/utils/app_colors.dart';
import 'package:url_launcher/url_launcher_string.dart';

class TaskDetailView extends StatelessWidget {
  final String taskId;

  /// Fetch human-readable details for createdBy, assignedTo, and projectId
  /// Fetch user and project details using Firestore.
  /// Logs and returns the 'name' fields for createdBy, assignedTo, and projectId.
  Future<Map<String, String>> _fetchUserDetails(
      String createdBy, String? assignedTo, String? projectId) async {
    final firestore = FirebaseFirestore.instance; // Firestore instance
    final Map<String, String> details = {
      'createdBy': 'Unknown', // Default for createdBy
      'assignedTo': 'Not Assigned', // Default for assignedTo
      'projectName': 'Non-project related', // Default for project
    };

    try {
      // Fetch 'createdBy' user name from 'users' collection
      print("Fetching createdBy user with ID: $createdBy");
      if (createdBy.isNotEmpty) {
        final createdByDoc =
            await firestore.collection('users').doc(createdBy).get();
        if (createdByDoc.exists) {
          final createdByName = createdByDoc.data()?['name'];
          if (createdByName != null && createdByName is String) {
            details['createdBy'] = createdByName;
            print("Created By: $createdByName");
          } else {
            print(
                "Warning: 'name' field is missing or not a String in user document: $createdBy");
          }
        } else {
          print("Warning: No user document found for createdBy ID: $createdBy");
        }
      } else {
        print("Warning: createdBy ID is empty.");
      }

      // Fetch 'assignedTo' user name (optional)
      if (assignedTo != null && assignedTo.isNotEmpty) {
        print("Fetching assignedTo user with ID: $assignedTo");
        final assignedToDoc =
            await firestore.collection('users').doc(assignedTo).get();
        if (assignedToDoc.exists && assignedToDoc.data()?['name'] != null) {
          details['assignedTo'] = assignedToDoc['name'];
          print("Assigned To: ${assignedToDoc['name']}");
        } else {
          print(
              "Warning: assignedTo user with ID $assignedTo does not exist or has no 'name'.");
        }
      }

      // Fetch 'projectName' from 'projects' collection
      if (projectId != null && projectId.isNotEmpty) {
        print("Fetching project with ID: $projectId");
        final projectDoc =
            await firestore.collection('projects').doc(projectId).get();
        if (projectDoc.exists && projectDoc.data()?['name'] != null) {
          details['projectName'] = projectDoc['name'];
          print("Project Name: ${projectDoc['name']}");
        } else {
          print(
              "Warning: project with ID $projectId does not exist or has no 'name'.");
        }
      }
    } catch (e) {
      print("Error fetching user/project details: $e");
    }

    print("Final Fetched Details: $details"); // Log the final fetched details
    return details;
  }

  const TaskDetailView({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    TaskFirestoreService taskFirestoreService =
        Provider.of<TaskFirestoreService>(context);

    return FutureBuilder<Task>(
      future: taskFirestoreService.getTaskById(taskId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data == null) {
          return Center(
              child: Text('Task not found')); // Update for 'taskNotFound'
        }

        final task = snapshot.data!;

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
                        researchService: Provider.of<ResearchService>(context,
                            listen: false),
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
                    formattedCreationDate, taskFirestoreService),
                const SizedBox(height: 20),
                _buildAiFeedbackSection(context, task),
                const SizedBox(height: 20),
                _buildAttachmentsSection(context, task, taskFirestoreService),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.list),
                  label: const Text('View Subtasks'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
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
      },
    );
  }

  Widget _buildTaskDetailsCard(
      BuildContext context,
      Task task,
      String formattedDeadline,
      String formattedCreationDate,
      TaskFirestoreService taskFirestoreService) {
    return FutureBuilder<Map<String, String>>(
      future:
          _fetchUserDetails(task.createdBy, task.assignedTo, task.projectId),
      builder: (context, snapshot) {
        final userDetails = snapshot.data ?? {};
        final createdByName = userDetails['createdBy'] ?? "Unknown";
        final assignedToName = userDetails['assignedTo'] ?? "Not Assigned";
        final projectName = userDetails['projectName'] ?? "Non-project related";

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
                _buildDetailRow("Description", task.description),
                _buildDetailRow("Deadline", formattedDeadline),
                _buildDetailRow("Creation Date", formattedCreationDate),
                _buildDetailRow("Created By", createdByName),
                _buildDetailRow("Assigned To", assignedToName),
                _buildDetailRow("Project", projectName),
                _buildDetailRow("Reward Points", '${task.points} pts'),
                _buildDetailRow("Category", '${task.category}'),
                _buildTaskResearchSection(
                    context, task, projectName, taskFirestoreService),
                if (projectName == "Non-project related") ...[
                  const SizedBox(height: 10),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      "Note: This task is not associated with any project.",
                      style: TextStyle(
                          color: Colors.red.shade700,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                  const SizedBox(height: 10),
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  /// Helper widget for displaying rows
  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title: ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskResearchSection(BuildContext context, Task task,
      String projectName, TaskFirestoreService taskFirestoreService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Keywords section for Research category
        if (task.category == "Research") ...[
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
              'No Keywords available',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          const SizedBox(height: 10),
        ],

        // Suggested Paper section for Research category
        if (task.category == "Research") ...[
          Text(
            'Suggested Paper:',
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
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween, // Space out buttons evenly
              children: [
                // Button: Add Suggested Paper as Subtask
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_task,
                        size: 18), // Smaller icon size
                    label: const Text(
                      "Add as Subtask",
                      style: TextStyle(fontSize: 12), // Smaller text size
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8), // Smaller padding
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      final subTask = SubTask(
                        title: task.suggestedPaper!,
                        description: "Suggested research paper",
                        status: SubtaskStatus.pending, // Default status
                        author: task.suggestedPaperAuthor,
                        publishDate: task.suggestedPaperPublishDate != null
                            ? DateTime.parse(task.suggestedPaperPublishDate!)
                            : null,
                        url: task.suggestedPaperUrl,
                      );

                      taskFirestoreService.addSubTask(task.id, subTask);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text("Suggested paper added as a subtask!")),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10), // Space between buttons
                // Button: Refresh Suggested Paper
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh,
                        size: 18), // Smaller icon size
                    label: const Text(
                      "Refresh Paper",
                      style: TextStyle(fontSize: 12), // Smaller text size
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8), // Smaller padding
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      try {
                        await taskFirestoreService
                            .refreshSuggestedPaper(task.id);
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
                ),
              ],
            ),
            const SizedBox(height: 10),
          ] else
            Text(
              task.suggestedPaper ?? 'No Suggested Paper available',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
        ],
      ],
    );
  }

  // Helper Method for displaying AI feedback
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
              await fetchAIFeedback(context, task); // Re-fetch AI feedback
            },
          );
        }

        return const Center(
          child: Text("No AI feedback available."),
        );
      },
    );
  }

  // Helper Method for displaying attachments section
  Widget _buildAttachmentsSection(BuildContext context, Task task,
      TaskFirestoreService taskFirestoreService) {
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
              onPressed: () => _addAttachment(context, taskFirestoreService),
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
                        taskFirestoreService.removeAttachment(
                            task.id, attachment.id); // Use Firestore
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

  // Handle adding attachment to Firestore
  Future<void> _addAttachment(
      BuildContext context, TaskFirestoreService taskFirestoreService) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final newAttachment = Attachment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: file.name,
        path: file.path ?? '',
        type: AttachmentType.file,
      );

      taskFirestoreService.addAttachment(
          taskId, newAttachment); // Add to Firestore
    }
  }

  // Show delete options dialog for repeating tasks
  Future<void> showDeleteOptionsDialog(BuildContext context, Task task) async {
    final taskFirestoreService =
        Provider.of<TaskFirestoreService>(context, listen: false);

    if (task.isRepeating) {
      // Show delete options dialog for repeating tasks
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(AppStr.deleteRepeatingTaskTitle),
            content: const Text(AppStr.deleteRepeatingTaskContent),
            actions: [
              TextButton(
                onPressed: () {
                  taskFirestoreService.deleteRepeatingTasks(task,
                      option: "all");
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text(AppStr.deleteAllButton),
              ),
              TextButton(
                onPressed: () {
                  taskFirestoreService.deleteRepeatingTasks(task,
                      option: "this_and_following");
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text(AppStr.deleteThisAndFollowingButton),
              ),
              TextButton(
                onPressed: () {
                  taskFirestoreService.deleteRepeatingTasks(task,
                      option: "only_this");
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text(AppStr.deleteOnlyThisButton),
              ),
            ],
          );
        },
      );
    } else {
      // Show delete confirmation dialog for non-repeating tasks
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
                  taskFirestoreService.removeTask(
                      task.id); // Correct, passing task ID as a String
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text(AppStr.yesButton),
              ),
            ],
          );
        },
      );
    }
  }

  // Helper function to fetch AI feedback
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

  // Helper function to get the appropriate icon for attachments
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

  // Open the attachment based on type
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
