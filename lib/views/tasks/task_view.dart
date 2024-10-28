import 'dart:developer';
import 'package:app/utils/app_colors.dart';
import 'package:app/utils/app_str.dart';
import 'package:app/views/tasks/components/date_time_selection.dart';
import 'package:app/views/tasks/components/rep_textfield.dart';
import 'package:app/views/tasks/widget/task_view_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:provider/provider.dart';
import 'package:app/models/task.dart'; // Import your Task model
import 'package:app/providers/task_provider.dart'; // Import your TaskProvider

class TaskView extends StatefulWidget {
  const TaskView({super.key});

  @override
  State<TaskView> createState() => _TaskViewState();
}

class _TaskViewState extends State<TaskView> {
  final TextEditingController titleTaskController = TextEditingController();
  final TextEditingController descriptionTaskController =
      TextEditingController();
  DateTime? selectedDeadline;

  @override
  Widget build(BuildContext context) {
    var textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: const TaskViewAppBar(),
        body: Padding(
          padding: const EdgeInsets.all(16.0), // Consistent padding
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch, // Full-width alignment
            children: [
              _buildTopSideTexts(textTheme),
              const SizedBox(height: 16), // Spacing between sections
              Expanded(child: _buildMainTaskViewActivity(textTheme, context)),
              const SizedBox(height: 16), // Spacing before buttons
              _buildBottomSideButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // Bottom buttons for adding and deleting tasks
  Widget _buildBottomSideButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildButton(
          label: AppStr.deleteTask,
          icon: Icons.close,
          color: Colors.white,
          onPressed: () {
            log("TASK DELETED"); // Log the delete action
          },
        ),
        _buildButton(
          label: AppStr.addTaskString,
          icon: null,
          color: AppColors.primaryColor,
          onPressed: () {
            _saveTask(); // Call the save function
          },
        ),
      ],
    );
  }

  // Function to save task with validations
  void _saveTask() {
    if (titleTaskController.text.isNotEmpty &&
        descriptionTaskController.text.isNotEmpty &&
        selectedDeadline != null) {
      final newTask = Task(
        title: titleTaskController.text,
        description: descriptionTaskController.text,
        deadline: selectedDeadline!,
      );

      // Save task using provider
      Provider.of<TaskProvider>(context, listen: false).addTask(newTask);

      // Clear fields after saving
      titleTaskController.clear();
      descriptionTaskController.clear();
      setState(() => selectedDeadline = null);

      Navigator.pop(context); // Navigate back after saving
    } else {
      // Handle empty fields
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
    }
  }

  // Reusable button widget
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
            if (icon != null)
              const SizedBox(width: 8), // Spacing between icon and text
            Text(
              label,
              style: TextStyle(
                  color: icon != null ? AppColors.primaryColor : Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // Main task creation form
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
            hintText: AppStr.placeholderTitle, // Placeholder text
          ),
          const SizedBox(height: 16), // Consistent spacing
          RepTextField(
            controller: descriptionTaskController,
            isForDescription: true,
            hintText: AppStr.placeholderDescription,
          ),
          const SizedBox(height: 16), // Spacing before date/time selectors
          DateTimeSelectionWidget(
            onTap: () {
              DatePicker.showTimePicker(context, onChanged: (_) {},
                  onConfirm: (date) {
                setState(() {
                  selectedDeadline = date; // Store the selected time
                });
              });
            },
            title: AppStr.timeString,
          ),
          const SizedBox(height: 16), // Spacing before date selector
          DateTimeSelectionWidget(
            onTap: () {
              DatePicker.showDatePicker(context, onConfirm: (date) {
                setState(() {
                  selectedDeadline = date; // Store the selected date
                });
              });
            },
            title: AppStr.dateString,
          ),
        ],
      ),
    );
  }

  // Top header with title text
  Widget _buildTopSideTexts(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: Divider(thickness: 2, color: Colors.grey.shade300)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              AppStr.addNewTask + AppStr.taskStrnig,
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
}
