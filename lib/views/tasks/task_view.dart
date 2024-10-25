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
      onTap: () => FocusManager.instance.primaryFocus!.unfocus(),
      child: Scaffold(
        appBar: const TaskViewAppBar(),

        //Body
        body: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Column(
            children: [
              /// Top Side Texts
              _buildTopSideTexts(textTheme),

              /// Main Task View Activity
              _buildMainTaskViewActivity(textTheme, context),

              /// Bottom Side Buttons
              _buildBottomSideButtons()
            ],
          ),
        ),
      ),
    );
  }

  /// Bottom Side Buttons
  Widget _buildBottomSideButtons() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          /// Delete Current Task Button
          MaterialButton(
            onPressed: () {
              log("TASK DELETED");
            },
            minWidth: 150,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            height: 55,
            child: Row(
              children: [
                const Icon(
                  Icons.close,
                  color: AppColors.primaryColor,
                ),
                5.w,
                const Text(
                  AppStr.deleteTask,
                  style: TextStyle(
                    color: AppColors.primaryColor,
                  ),
                )
              ],
            ),
          ),

          /// Add or Update
          MaterialButton(
            onPressed: () {
              log("TASK ADDED");
            },
            minWidth: 150,
            color: AppColors.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            height: 55,
            child: const Row(
              children: [
                Text(
                  AppStr.addTaskString,
                  style: TextStyle(
                    color: Colors.white,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  /// Main Task View Activity
  Widget _buildMainTaskViewActivity(TextTheme textTheme, BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 400,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Text(
                AppStr.titleOfTitleTextField,
                style: textTheme.headlineMedium,
              ),
            ),

            // Task Title
            RepTextField(
              controller: titleTaskController,
            ),

            10.h,

            // Task description
            RepTextField(
              controller: descriptionTaskController,
              isForDescription: true,
            ),

            /// Time Selector
            DateTimeSelectionWidget(
              onTap: () {
                DatePicker.showTimePicker(
                  context,
                  // TODO: LATER IMPLEMENTATION
                  onChanged: (_) {},
                  onConfirm: (_) {},
                );
              },
              title: AppStr.timeString,
            ),

            // Date Selector
            DateTimeSelectionWidget(
              onTap: () {
                DatePicker.showDatePicker(
                  context,
                  // TODO: LATER IMPLEMENTATION
                  onConfirm: (_) {},
                );
              },
              title: AppStr.dateString,
            )
          ],
        ),
      ),
    );
  }

  /// Top Side Texts
  Widget _buildTopSideTexts(TextTheme textTheme) {
    return SizedBox(
      width: double.infinity,
      height: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: 70,
            child: Divider(
              thickness: 2,
            ),
          ),
          // TODO: ADD OR UPDATE TASK BASED ON CONDITIONS
          RichText(
              text: TextSpan(
            text: AppStr.addNewTask,
            style: textTheme.titleLarge,
            children: const [
              TextSpan(
                text: AppStr.taskStrnig,
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          )),

          const SizedBox(
            width: 70,
            child: Divider(
              thickness: 2,
            ),
          ),
        ],
      ),
    );
  }
}
