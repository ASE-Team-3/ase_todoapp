import 'dart:io';
import 'dart:developer';
import 'package:app/models/attachment.dart';
import 'package:app/utils/app_colors.dart';
import 'package:app/utils/app_str.dart';
import 'package:app/views/home/home_view.dart';
import 'package:app/views/tasks/components/date_time_selection.dart';
import 'package:app/views/tasks/components/rep_textfield.dart';
import 'package:app/views/tasks/widget/task_view_app_bar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:provider/provider.dart';
import 'package:app/models/task.dart';
import 'package:app/providers/task_provider.dart';
import 'package:uuid/uuid.dart';

class TaskCreateView extends StatefulWidget {
  final Task? task;

  const TaskCreateView({super.key, this.task});

  @override
  State<TaskCreateView> createState() => _TaskCreateViewState();
}

class _TaskCreateViewState extends State<TaskCreateView> {
  final TextEditingController titleTaskController = TextEditingController();
  final TextEditingController descriptionTaskController =
      TextEditingController();
  final TextEditingController pointsController = TextEditingController();
  DateTime? selectedDeadline;
  List<Attachment> attachments = [];
  int lastValidPoints = 0;

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
          label: widget.task == null
              ? AppStr.addTaskString
              : AppStr.updateTaskString,
          icon: null,
          color: AppColors.primaryColor,
          onPressed: _saveOrUpdateTask,
        ),
      ],
    );
  }

  void _saveOrUpdateTask() {
    final enteredPoints = int.tryParse(pointsController.text) ?? 0;

    if (titleTaskController.text.isNotEmpty &&
        descriptionTaskController.text.isNotEmpty &&
        selectedDeadline != null) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);

      if (widget.task == null) {
        final newTask = Task(
          id: const Uuid().v4(),
          title: titleTaskController.text,
          description: descriptionTaskController.text,
          deadline: selectedDeadline!,
          attachments: attachments,
          points: enteredPoints,
        );
        taskProvider.addTask(newTask);
      } else {
        final updatedTask = widget.task!.copyWith(
          title: titleTaskController.text,
          description: descriptionTaskController.text,
          deadline: selectedDeadline!,
          attachments: attachments,
          points: enteredPoints,
        );
        taskProvider.updateTask(updatedTask);
      }

      titleTaskController.clear();
      descriptionTaskController.clear();
      pointsController.clear();
      setState(() {
        selectedDeadline = null;
        attachments.clear();
      });
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStr.fillAllFieldsMessage)),
      );
    }
  }

  void _deleteTask() {
    if (widget.task != null) {
      try {
        Provider.of<TaskProvider>(context, listen: false)
            .removeTask(widget.task!);
        Navigator.of(context)
            .pop(MaterialPageRoute(builder: (context) => const HomeView()));
      } catch (e) {
        log('Error deleting task: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStr.failedToDeleteTask)),
        );
      }
    }
  }

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
          mainAxisAlignment:
              icon != null ? MainAxisAlignment.start : MainAxisAlignment.center,
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

  Widget _buildMainTaskViewActivity(TextTheme textTheme, BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 20),
            child: Text(AppStr.titleOfTitleTextField,
                style: textTheme.headlineMedium),
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
          DateTimeSelectionWidget(
            title: selectedDeadline != null
                ? "${selectedDeadline!.toLocal()}".split(' ')[0]
                : AppStr.dateString,
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
                ? "${selectedDeadline!.hour}:${selectedDeadline!.minute}"
                : AppStr.timeString,
            onTap: () {
              DatePicker.showTimePicker(context, onChanged: (_) {},
                  onConfirm: (time) {
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
      ),
    );
  }

  Widget _buildTopSideTexts(TextTheme textTheme) {
    // Determine if it's an add or update action
    final titleText =
        widget.task == null ? AppStr.addNewTask : AppStr.updateCurrentTask;

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

  Widget _buildAttachmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStr.attachmentsLabel,
            style: TextStyle(fontWeight: FontWeight.bold)),
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
