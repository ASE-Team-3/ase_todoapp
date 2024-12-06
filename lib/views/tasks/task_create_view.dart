import 'dart:io';
import 'dart:developer';
import 'package:app/models/attachment.dart';
import 'package:app/services/research_service.dart';
import 'package:app/utils/app_colors.dart';
import 'package:app/utils/app_str.dart';
import 'package:app/utils/reminder_utils.dart';
import 'package:app/views/home/home_view.dart';
import 'package:app/views/tasks/components/alert_frequency_dropdown.dart';
import 'package:app/views/tasks/components/category_dropdown.dart';
import 'package:app/views/tasks/components/custom_interval_input.dart';
import 'package:app/views/tasks/components/custom_reminder_input.dart';
import 'package:app/views/tasks/components/date_time_selection.dart';
import 'package:app/views/tasks/components/flexible_deadline_dropdown.dart';
import 'package:app/views/tasks/components/rep_textfield.dart';
import 'package:app/views/tasks/components/repeat_interval_dropdown.dart';
import 'package:app/views/tasks/components/repeating_toggle.dart';
import 'package:app/views/tasks/components/research_section.dart';
import 'package:app/views/tasks/widget/task_view_app_bar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:provider/provider.dart';
import 'package:app/models/task.dart';
import 'package:app/services/task_firestore_service.dart'; // Import Firestore service
import 'package:uuid/uuid.dart';

class TaskCreateView extends StatefulWidget {
  final Task? task;
  final ResearchService researchService;

  const TaskCreateView({
    super.key,
    this.task,
    required this.researchService,
  });

  @override
  State<TaskCreateView> createState() => _TaskCreateViewState();
}

class _TaskCreateViewState extends State<TaskCreateView> {
  final TextEditingController titleTaskController = TextEditingController();
  final TextEditingController descriptionTaskController = TextEditingController();
  final TextEditingController pointsController = TextEditingController();
  DateTime? selectedDeadline;
  String? flexibleDeadline;
  List<Attachment> attachments = [];
  int lastValidPoints = 0;
  bool isRepeating = false;
  String? repeatInterval;
  int? customRepeatDays;
  DateTime? nextOccurrence;
  String? alertFrequency = "5_minutes";
  int? customReminderQuantity;
  String? customReminderUnit;
  Map<String, dynamic>? customReminder = {"unit": "hours", "quantity": 1};

  String? selectedCategory = "General";
  List<String> researchKeywords = [];
  String? suggestedPaper;
  String? suggestedPaperUrl;

  // Generates keywords from task title and description
  void generateResearchKeywords() {
    final title = titleTaskController.text.trim();
    final description = descriptionTaskController.text.trim();

    if (title.isNotEmpty || description.isNotEmpty) {
      setState(() {
        researchKeywords = generateKeywords(title, description);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in the task title or description first.")),
      );
    }
  }

  // Adds a new keyword to researchKeywords
  void addKeyword(String keyword) {
    setState(() {
      if (!researchKeywords.contains(keyword)) {
        researchKeywords.add(keyword);
      }
    });
  }

  // Removes a keyword from researchKeywords
  void removeKeyword(String keyword) {
    setState(() {
      researchKeywords.remove(keyword);
    });
  }

  // Generates keywords by splitting the title and description into unique words
  List<String> generateKeywords(String title, String description) {
    final allText = "$title $description".toLowerCase();
    final words = allText.split(RegExp(r'\s+')).toSet();
    final keywords = words.where((word) => word.length > 3).toList();
    return keywords.take(5).toList();
  }

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      titleTaskController.text = widget.task!.title;
      descriptionTaskController.text = widget.task!.description;
      selectedDeadline = widget.task!.deadline;
      attachments = List.from(widget.task!.attachments);
      pointsController.text = widget.task!.points.toString();
      lastValidPoints = widget.task!.points;
      researchKeywords = widget.task!.keywords;
      suggestedPaper = widget.task!.suggestedPaper;
      suggestedPaperUrl = widget.task!.suggestedPaperUrl;

      if (widget.task!.customReminder != null) {
        customReminderQuantity = widget.task!.customReminder!['quantity'];
        customReminderUnit = widget.task!.customReminder!['unit'];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: const TaskViewAppBar(),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopSideTexts(textTheme),
              const SizedBox(height: 16),
              Expanded(child: _buildMainTaskViewActivity(textTheme, context)),
              const SizedBox(height: 16),
              _buildAttachmentsSection(),
              const SizedBox(height: 16),
              _buildBottomSideButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // Bottom buttons for saving/updating or deleting tasks
  Widget _buildBottomSideButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (widget.task != null)
          _buildButton(
            label: AppStr.deleteTask,
            icon: Icons.close,
            color: Colors.white,
            onPressed: _deleteTask,
          ),
        _buildButton(
          label: widget.task == null ? AppStr.addTaskString : AppStr.updateTaskString,
          icon: null,
          color: AppColors.primaryColor,
          onPressed: _saveOrUpdateTask,
        ),
      ],
    );
  }

  // Save or update the task to Firestore
  void _saveOrUpdateTask() async {
    final enteredPoints = int.tryParse(pointsController.text) ?? 0;

    if (titleTaskController.text.isNotEmpty &&
        descriptionTaskController.text.isNotEmpty &&
        (selectedDeadline != null || flexibleDeadline != null)) {
      final taskFirestoreService = TaskFirestoreService();  // Use Firestore service

      // Validate alert frequency
      if (alertFrequency == "custom" &&
          (customReminder == null ||
              customReminder!['quantity'] == null ||
              customReminder!['unit'] == null)) {
        log('Invalid custom reminder configuration');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStr.customReminderErrorMessage)),
        );
        return;
      }

      final customReminderConfig = (alertFrequency == "custom") ? customReminder : null;

      // Prepare common task fields
      final String category = selectedCategory ?? "General";
      final List<String> keywords = category == "Research" ? researchKeywords : [];
      final DateTime? deadline = selectedDeadline;
      final String? flexibleDeadlineOption = flexibleDeadline;

      // Check if it's a new task or an update
      if (widget.task == null) {
        // Creating a new task
        final newTask = Task(
          id: const Uuid().v4(),
          title: titleTaskController.text,
          description: descriptionTaskController.text,
          category: category,
          keywords: keywords,
          deadline: deadline,
          flexibleDeadline: flexibleDeadlineOption,
          alertFrequency: alertFrequency,
          customReminder: customReminderConfig,
          isRepeating: isRepeating,
          repeatInterval: repeatInterval,
          customRepeatDays: customRepeatDays,
          nextOccurrence: _calculateNextOccurrence(),
          attachments: attachments,
          points: enteredPoints,
        );

        try {
          // Add task to Firestore
          await taskFirestoreService.addTask(newTask);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Task added successfully!")),
          );
          Navigator.pop(context);
        } catch (e) {
          log("Error adding task: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to add the task.")),
          );
        }
      } else {
        // Updating an existing task
        final updatedTask = widget.task!.copyWith(
          title: titleTaskController.text,
          description: descriptionTaskController.text,
          category: category,
          keywords: keywords,
          deadline: deadline?.toUtc(),
          flexibleDeadline: flexibleDeadlineOption,
          alertFrequency: alertFrequency,
          customReminder: customReminderConfig,
          isRepeating: isRepeating,
          repeatInterval: repeatInterval,
          customRepeatDays: customRepeatDays,
          attachments: attachments,
          points: enteredPoints,
        );

        try {
          // Update task in Firestore
          await taskFirestoreService.updateTask(updatedTask);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Task updated successfully!")),
          );
          _resetFields();
          Navigator.pop(context);
        } catch (e) {
          log("Error updating task: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to update the task.")),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStr.fillAllFieldsMessage)),
      );
    }
  }

  // Show options to update repeating tasks
  Future<void> _showUpdateOptionsDialog(TaskFirestoreService taskFirestoreService) async {
    final enteredPoints = int.tryParse(pointsController.text) ?? 0;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Update Repeating Task"),
          content: const Text("How would you like to update this repeating task?"),
          actions: [
            TextButton(
              onPressed: () {
                taskFirestoreService.updateTask(widget.task!);
                _resetFields();
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("Update All"),
            ),
            TextButton(
              onPressed: () {
                taskFirestoreService.updateTask(widget.task!);
                _resetFields();
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("This and Following"),
            ),
            TextButton(
              onPressed: () {
                taskFirestoreService.updateTask(widget.task!);
                _resetFields();
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("Only This"),
            ),
          ],
        );
      },
    );
  }

  // Reset all fields after adding or updating a task
  void _resetFields() {
    titleTaskController.clear();
    descriptionTaskController.clear();
    pointsController.clear();
    setState(() {
      selectedDeadline = null;
      attachments.clear();
      flexibleDeadline = null;
      isRepeating = false;
      repeatInterval = null;
      customRepeatDays = null;
      nextOccurrence = null;
    });
  }

  // Calculate next occurrence based on repeat settings
  DateTime? _calculateNextOccurrence() {
    if (!isRepeating) return null;

    final now = DateTime.now();
    switch (repeatInterval) {
      case "daily":
        return now.add(const Duration(days: 1));
      case "weekly":
        return now.add(const Duration(days: 7));
      case "monthly":
        return DateTime(now.year, now.month + 1, now.day);
      case "yearly":
        return DateTime(now.year + 1, now.month, now.day);
      case "custom":
        if (customRepeatDays != null) {
          return now.add(Duration(days: customRepeatDays!));
        }
        break;
    }
    return null;
  }

  // Delete the task from Firestore
  void _deleteTask() async {
    if (widget.task != null) {
      try {
        final taskFirestoreService = TaskFirestoreService();
        await taskFirestoreService.deleteTask(widget.task!.id);
        Navigator.of(context).pop(MaterialPageRoute(builder: (context) => const HomeView()));
      } catch (e) {
        log('Error deleting task: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStr.failedToDeleteTask)),
        );
      }
    }
  }

  // Build a button with specified properties
  Widget _buildButton({
    required String label,
    IconData? icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 150,
      height: 55,
      child: MaterialButton(
        onPressed: onPressed,
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: icon != null ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            if (icon != null) Icon(icon, color: AppColors.primaryColor),
            if (icon != null) const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: icon != null ? AppColors.primaryColor : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Main UI components and layout for creating or updating tasks
  Widget _buildMainTaskViewActivity(TextTheme textTheme, BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 20),
            child: Text(AppStr.titleOfTitleTextField, style: textTheme.headlineMedium),
          ),
          RepTextField(
            controller: titleTaskController,
            hintText: AppStr.placeholderTitle,
          ),
          const SizedBox(height: 16),
          RepTextField(
            controller: descriptionTaskController,
            isForDescription: true,
            hintText: AppStr.placeholderDescription,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: pointsController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: AppStr.assignPointsLabel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (value) {
                    int parsedValue = int.tryParse(value) ?? lastValidPoints;
                    if (parsedValue > 100) {
                      pointsController.text = lastValidPoints.toString();
                      pointsController.selection = TextSelection.fromPosition(
                        TextPosition(offset: pointsController.text.length),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(AppStr.pointsExceedMessage),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } else {
                      lastValidPoints = parsedValue;
                    }
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  "${AppStr.currentPointsLabel}: ${pointsController.text.isEmpty ? 0 : pointsController.text} points",
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FlexibleDeadlineDropdown(
            flexibleDeadline: flexibleDeadline,
            onFlexibleDeadlineChanged: (value) {
              setState(() {
                flexibleDeadline = value;
                if (value != "Specific Deadline") {
                  selectedDeadline = null;
                }
              });
            },
            onSpecificDeadlineSelected: (date) {
              setState(() {
                selectedDeadline = date;
              });
            },
          ),
          if (flexibleDeadline == "Specific Deadline") ...[
            const SizedBox(height: 16),
            DateTimeSelectionWidget(
              title: selectedDeadline != null
                  ? "${selectedDeadline!.toLocal()}".split(' ')[0]
                  : AppStr.selectDate,
              onTap: () {
                DatePicker.showDatePicker(context, onConfirm: (date) {
                  setState(() {
                    selectedDeadline = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      selectedDeadline?.hour ?? 0,
                      selectedDeadline?.minute ?? 0,
                    );
                  });
                });
              },
            ),
            const SizedBox(height: 16),
            DateTimeSelectionWidget(
              title: selectedDeadline != null
                  ? "${selectedDeadline!.hour}:${selectedDeadline!.minute.toString().padLeft(2, '0')}"
                  : AppStr.selectDate,
              onTap: () {
                DatePicker.showTimePicker(context, onConfirm: (time) {
                  setState(() {
                    if (selectedDeadline != null) {
                      selectedDeadline = DateTime(
                        selectedDeadline!.year,
                        selectedDeadline!.month,
                        selectedDeadline!.day,
                        time.hour,
                        time.minute,
                      );
                    } else {
                      selectedDeadline = time;
                    }
                  });
                });
              },
            ),
          ],
          const SizedBox(height: 16),
          _buildRepeatingToggle(textTheme),
          if (isRepeating) ...[
            const SizedBox(height: 16),
            _buildRepeatIntervalDropdown(textTheme),
            const SizedBox(height: 16),
            _buildCustomIntervalInput(textTheme),
          ],
          const SizedBox(height: 16),
          AlertFrequencyDropdown(
            alertFrequency: alertFrequency,
            onFrequencyChanged: (value) {
              setState(() {
                alertFrequency = value;
                if (value != "custom") {
                  customReminder = null;
                } else {
                  customReminder = {"quantity": 1, "unit": "hours"};
                }
              });
            },
          ),
          if (alertFrequency == "custom") ...[
            const SizedBox(height: 16),
            CustomReminderInput(
              customReminder: customReminder,
              onCustomReminderChanged: (value) {
                setState(() {
                  customReminder = validateCustomReminder(value);
                });
              },
            ),
          ],
          const SizedBox(height: 16),
          CategoryDropdown(
            selectedCategory: selectedCategory,
            onCategoryChanged: (value) {
              setState(() {
                selectedCategory = value;
                if (selectedCategory != "Research") {
                  researchKeywords.clear();
                }
              });
            },
          ),
          const SizedBox(height: 16),
          if (selectedCategory == "Research") ...[
            ResearchSection(
              keywords: researchKeywords,
              onAddKeyword: (keyword) {
                setState(() {
                  if (!researchKeywords.contains(keyword)) {
                    researchKeywords.add(keyword);
                  }
                });
              },
              onRemoveKeyword: (keyword) {
                setState(() {
                  researchKeywords.remove(keyword);
                });
              },
              onGenerateKeywords: () {
                setState(() {
                  researchKeywords = generateKeywords(
                    titleTaskController.text.trim(),
                    descriptionTaskController.text.trim(),
                  );
                });
              },
              onRefreshSuggestions: () async {
                try {
                  final suggestions = await widget.researchService
                      .fetchRelatedResearch(researchKeywords);
                  setState(() {
                    if (suggestions.isNotEmpty) {
                      suggestedPaper = suggestions[0]['title'];
                      suggestedPaperUrl = suggestions[0]['url'];
                    }
                  });
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Failed to refresh research suggestions")),
                  );
                }
              },
              suggestedPaper: suggestedPaper,
              suggestedPaperUrl: suggestedPaperUrl,
            ),
          ],
        ],
      ),
    );
  }

  // Header text section with title for the task form
  Widget _buildTopSideTexts(TextTheme textTheme) {
    final titleText = widget.task == null ? AppStr.addNewTask : AppStr.updateCurrentTask;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: Divider(thickness: 2, color: Colors.grey.shade300)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              titleText,
              style: textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(child: Divider(thickness: 2, color: Colors.grey.shade300)),
        ],
      ),
    );
  }

  // Build the attachment section where users can add files or links
  Widget _buildAttachmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStr.attachmentsLabel, style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.attach_file),
              label: Text(AppStr.attachFile),
            ),
            ElevatedButton.icon(
              onPressed: _promptForLink,
              icon: const Icon(Icons.link),
              label: Text(AppStr.addLink),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Column(
          children: attachments
              .map((attachment) => _buildAttachmentTile(attachment))
              .toList(),
        ),
      ],
    );
  }

  // Build the repeat interval dropdown for recurring tasks
  Widget _buildRepeatIntervalDropdown(TextTheme textTheme) {
    if (!isRepeating) return const SizedBox.shrink();

    return RepeatIntervalDropdown(
      repeatInterval: repeatInterval,
      onChanged: (value) {
        setState(() {
          repeatInterval = value;
          if (value != "custom") customRepeatDays = null;
        });
      },
    );
  }

  // Build the repeating toggle for toggling the repeating task feature
  Widget _buildRepeatingToggle(TextTheme textTheme) {
    return RepeatingToggle(
      isRepeating: isRepeating,
      onChanged: (value) {
        setState(() {
          isRepeating = value;
          if (!value) {
            repeatInterval = null;
            customRepeatDays = null;
            nextOccurrence = null;
          }
        });
      },
    );
  }

  // Build the custom interval input for setting custom repeat intervals
  Widget _buildCustomIntervalInput(TextTheme textTheme) {
    if (!isRepeating || repeatInterval != "custom") return const SizedBox.shrink();

    return CustomIntervalInput(
      customRepeatDays: customRepeatDays,
      onChanged: (value) {
        setState(() {
          customRepeatDays = value;
        });
      },
    );
  }

  // Build each individual attachment tile with a delete option
  Widget _buildAttachmentTile(Attachment attachment) {
    return ListTile(
      leading: Icon(_getAttachmentIcon(attachment.type)),
      title: Text(attachment.name),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () => _removeAttachment(attachment.id),
      ),
    );
  }

  // Get the correct icon based on the attachment type
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
    }
  }

  // Pick a file using file picker
  void _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      final file = File(result.files.single.path!);
      final newAttachment = Attachment(
        id: const Uuid().v4(),
        name: result.files.single.name,
        path: file.path,
        type: AttachmentType.file,
      );
      setState(() => attachments.add(newAttachment));
    }
  }

  // Prompt for adding a URL link as an attachment
  void _promptForLink() {
    showDialog(
      context: context,
      builder: (context) {
        final linkController = TextEditingController();
        return AlertDialog(
          title: Text(AppStr.addLinkTitle),
          content: TextField(
            controller: linkController,
            decoration: InputDecoration(hintText: AppStr.enterUrl),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStr.cancel),
            ),
            TextButton(
              onPressed: () {
                if (linkController.text.isNotEmpty) {
                  final newAttachment = Attachment(
                    id: const Uuid().v4(),
                    name: linkController.text,
                    path: linkController.text,
                    type: AttachmentType.link,
                  );
                  setState(() => attachments.add(newAttachment));
                  Navigator.pop(context);
                }
              },
              child: Text(AppStr.add),
            ),
          ],
        );
      },
    );
  }

  // Remove an attachment from the list
  void _removeAttachment(String attachmentId) {
    setState(() {
      attachments.removeWhere((a) => a.id == attachmentId);
    });
  }

  @override
  void dispose() {
    titleTaskController.dispose();
    descriptionTaskController.dispose();
    pointsController.dispose();
    super.dispose();
  }
}
