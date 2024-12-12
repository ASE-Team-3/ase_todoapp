import 'package:flutter/material.dart';
import 'package:app/services/task_firestore_service.dart';
import 'package:app/utils/app_colors.dart';

class PointsSummaryText extends StatelessWidget {
  const PointsSummaryText({super.key});

  @override
  Widget build(BuildContext context) {
    final taskService = TaskFirestoreService();

    return StreamBuilder<int>(
      stream: taskService.getTotalPoints(), // Fetch total points dynamically
      builder: (context, snapshot) {
        // Debugging: Log snapshot state
        print("Snapshot State: ${snapshot.connectionState}");
        print("Snapshot Error: ${snapshot.error}");
        print("Snapshot Data: ${snapshot.data}");

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text(
            "Error loading points: ${snapshot.error}", // Display error details
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
          );
        }

        final totalPoints = snapshot.data ?? 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Reward Points",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              "$totalPoints pts",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
            ),
          ],
        );
      },
    );
  }
}
