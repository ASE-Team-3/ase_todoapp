import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/providers/task_provider.dart';

class PointsHistoryView extends StatelessWidget {
  const PointsHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final pointsHistory = Provider.of<TaskProvider>(context).pointsHistory;

    return pointsHistory.isNotEmpty
        ? ListView.builder(
      itemCount: pointsHistory.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final entry = pointsHistory[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
              entry.action == 'Awarded' ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
              child: Icon(
                entry.action == 'Awarded'
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
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
              "${entry.timestamp.hour}:${entry.timestamp.minute.toString().padLeft(2, '0')}",
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        );
      },
    )
        : Center(
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
}
