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
            itemBuilder: (context, index) {
              final entry = pointsHistory[index];
              return ListTile(
                leading: Icon(
                  entry.action == 'Awarded'
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  color: entry.action == 'Awarded' ? Colors.green : Colors.red,
                ),
                title: Text(
                  "${entry.action} ${entry.points} pts",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(entry.reason),
                trailing: Text(
                  "${entry.timestamp.hour}:${entry.timestamp.minute.toString().padLeft(2, '0')}",
                  style: const TextStyle(color: Colors.grey),
                ),
              );
            },
          )
        : const Center(
            child: Text(
              "No points history available.",
              style: TextStyle(color: Colors.grey),
            ),
          );
  }
}
