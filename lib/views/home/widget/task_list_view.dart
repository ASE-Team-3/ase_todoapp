import 'package:flutter/material.dart';
import 'package:app/models/task.dart';
import 'package:provider/provider.dart';
import 'package:app/services/task_firestore_service.dart';  // Import TaskFirestoreService
import 'package:app/views/home/widget/task_widget.dart';

class TaskListView extends StatelessWidget {
  const TaskListView({super.key});

  @override
  Widget build(BuildContext context) {
    final taskFirestoreService = Provider.of<TaskFirestoreService>(context); // Access TaskFirestoreService

    return StreamBuilder<List<Task>>(
      stream: taskFirestoreService.getTasksForUser(), // Get tasks from Firestore as a stream
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator()); // Show loading indicator while fetching data
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}')); // Show error message if there’s an issue
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No tasks available.")); // Show message if no tasks are found
        } else {
          final tasks = snapshot.data!; // Get tasks from the snapshot

          // Log the tasks to the console
          print("Tasks to display: $tasks");

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return TaskWidget(
                task: task,
                onToggleComplete: () {
                  // Call toggleTaskCompletion from TaskFirestoreService directly
                  taskFirestoreService.toggleTaskCompletion(task);
                },
              );
            },
          );
        }
      },
    );
  }
}
