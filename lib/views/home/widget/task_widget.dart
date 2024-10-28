import 'dart:developer';

import 'package:app/utils/app_colors.dart';
import 'package:flutter/material.dart';

class TaskWidget extends StatelessWidget {
  const TaskWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to Task view to see Task Details
        log('Task details');
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 4, // Provides a material design shadow
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12), // Rounded corners for a softer look
        ),
        child: ListTile(
          // Check Icon
          leading: GestureDetector(
            onTap: () {
              // Check or uncheck the task
            },
            child: CircleAvatar(
              backgroundColor: AppColors.primaryColor,
              child: const Icon(
                Icons.check,
                color: Colors.white,
              ),
            ),
          ),

          // Task Title
          title: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              "Done",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
            ),
          ),

          // Task Description
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Descriptions",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                      fontWeight: FontWeight.w400,
                    ),
              ),
              const SizedBox(height: 8), // Spacing between description and date
              // Date of Task
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Date",
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  Text(
                    "SubDate",
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
