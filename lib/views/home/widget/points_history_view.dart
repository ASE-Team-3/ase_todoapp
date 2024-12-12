import 'package:app/models/points_history.dart';
import 'package:app/services/task_firestore_service.dart';
import 'package:flutter/material.dart';

class PointsHistoryView extends StatelessWidget {
  const PointsHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final taskService = TaskFirestoreService(); // Firestore service instance

    return StreamBuilder<List<PointsHistory>>(
      stream: taskService.getPointsHistory(), // Stream of points history
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error loading points history: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  color: Colors.grey.shade400,
                  size: 80,
                ),
                const SizedBox(height: 16),
                Text(
                  "No points history available.",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        final pointsHistory = snapshot.data!;

        return ListView.builder(
          itemCount: pointsHistory.length,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemBuilder: (context, index) {
            final entry = pointsHistory[index];

            // Use the 'action' field to determine if points are awarded or deducted
            final bool isAwarded = entry.action == 'Awarded';

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isAwarded
                      ? const Color(0xFF34C759) // Green for awarded points
                      : const Color(0xFFFF3B30), // Red for deducted points
                  child: Icon(
                    isAwarded ? Icons.arrow_upward : Icons.arrow_downward,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  "${entry.action} ${entry.points} pts",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Text(
                  entry.reason,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
                trailing: Text(
                  _formatTimestamp(entry.timestamp),
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Formats the timestamp to display as HH:mm
  String _formatTimestamp(DateTime timestamp) {
    return "${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}";
  }
}
