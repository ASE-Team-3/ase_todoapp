import 'dart:developer';
import 'package:app/extensions/space_exs.dart';
import 'package:app/utils/app_colors.dart';
import 'package:app/utils/app_str.dart';
import 'package:app/views/tasks/components/date_time_selection.dart';
import 'package:app/views/tasks/components/rep_textfield.dart';
import 'package:app/views/tasks/widget/task_view_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';

class TaskView extends StatefulWidget {
  const TaskView({super.key});

  @override
  State<TaskView> createState() => _TaskViewState();
}

class _TaskViewState extends State<TaskView> {
  final TextEditingController titleTaskController = TextEditingController();
  final TextEditingController descriptionTaskController =
      TextEditingController();

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

  Widget _buildBottomSideButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildButton(
          label: AppStr.deleteTask,
          icon: Icons.close,
          color: Colors.white,
          onPressed: () {
            log("TASK DELETED");
          },
        ),
        _buildButton(
          label: AppStr.addTaskString,
          icon: null,
          color: AppColors.primaryColor,
          onPressed: () {
            log("TASK ADDED");
          },
        ),
      ],
    );
  }

  Widget _buildButton(
      {required String label,
      IconData? icon,
      required Color color,
      required VoidCallback onPressed}) {
    return Container(
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

  Widget _buildMainTaskViewActivity(TextTheme textTheme, BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 20),
            child: Text(
              AppStr.titleOfTitleTextField,
              style: textTheme.headlineMedium,
            ),
          ),
          // Add hint text for the title field
          RepTextField(
            controller: titleTaskController,
            hintText: AppStr.placeholderTitle, // Placeholder text
          ),
          const SizedBox(height: 16), // Consistent spacing
          RepTextField(
            controller: descriptionTaskController,
            isForDescription: true,
            hintText: AppStr
                .placeholderDescription, // Optional placeholder for description
          ),
          const SizedBox(height: 16), // Spacing before date/time selectors
          DateTimeSelectionWidget(
            onTap: () {
              DatePicker.showTimePicker(context,
                  onChanged: (_) {}, onConfirm: (_) {});
            },
            title: AppStr.timeString,
          ),
          const SizedBox(height: 16), // Spacing before date selector
          DateTimeSelectionWidget(
            onTap: () {
              DatePicker.showDatePicker(context, onConfirm: (_) {});
            },
            title: AppStr.dateString,
          ),
        ],
      ),
    );
  }

  Widget _buildTopSideTexts(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: 16.0), // Vertical padding for spacing
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Divider
          Expanded(
            child: Divider(
              thickness: 2,
              color: Colors.grey.shade300,
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16.0), // Add horizontal padding
            child: Text(
              AppStr.addNewTask + AppStr.taskStrnig,
              style: textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold, // Make the title bold
                color: Colors.black, // Use a contrasting color
              ),
              textAlign: TextAlign.center, // Center text
            ),
          ),
          // Right Divider
          Expanded(
            child: Divider(
              thickness: 2,
              color: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }
}
