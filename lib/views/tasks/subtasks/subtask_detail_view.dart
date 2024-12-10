import 'package:app/providers/task_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/models/subtask_item.dart';
import 'package:app/services/task_firestore_service.dart'; // Import Firestore service
import 'package:app/utils/app_colors.dart';
import 'package:app/models/task.dart'; // Import the Task model

class SubTaskDetailView extends StatefulWidget {
  final String taskId;
  final String subTaskId;

  const SubTaskDetailView({
    super.key,
    required this.taskId,
    required this.subTaskId,
  });

  @override
  _SubTaskDetailViewState createState() => _SubTaskDetailViewState();
}

class _SubTaskDetailViewState extends State<SubTaskDetailView> {
  final _formKey = GlobalKey<FormState>();
  final _itemTitleController = TextEditingController();

  // Function to add a new item to a subtask
  void _addItem(TaskProvider taskProvider) {
    if (_formKey.currentState!.validate()) {
      final newItem = SubTaskItem(title: _itemTitleController.text);

      // Add the new item using the Firestore service
      taskProvider.addSubTaskItem(widget.taskId, widget.subTaskId, newItem);
      _itemTitleController
          .clear(); // Clear the input field after adding the item
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fetching task from Firestore using FutureBuilder
    return FutureBuilder<Task>(
      future: Provider.of<TaskFirestoreService>(context, listen: false)
          .getTaskById(
              widget.taskId), // Using the Firestore service to get the task
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              title: const Text(
                'Subtask Details',
                style: TextStyle(color: Colors.black),
              ),
              iconTheme: const IconThemeData(color: Colors.black),
            ),
            body: const Center(child: Text('Error loading task')),
          );
        } else if (snapshot.hasData) {
          final task = snapshot.data!;
          final subTask =
              task.subTasks.firstWhere((st) => st.id == widget.subTaskId);

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              title: Text(
                subTask.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black),
              ),
              iconTheme: const IconThemeData(color: Colors.black),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subtask description
                  Text(
                    subTask.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Items',
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 10),
                  // Display items for the subtask
                  Expanded(
                    child: ListView.builder(
                      itemCount: subTask.items.length,
                      itemBuilder: (context, index) {
                        final item = subTask.items[index];
                        return Card(
                          color: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            title: Text(
                              item.title,
                              style: const TextStyle(color: Colors.black87),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Checkbox to toggle completion of subtask item
                                Checkbox(
                                  value: item.isCompleted,
                                  onChanged: (value) {
                                    // Using Firestore service to toggle completion
                                    Provider.of<TaskFirestoreService>(context,
                                            listen: false)
                                        .toggleSubTaskItemCompletion(
                                      widget.taskId,
                                      widget.subTaskId,
                                      item.id,
                                    );
                                  },
                                  activeColor: AppColors.primaryColor,
                                ),
                                // Delete button for subtask item
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () {
                                    // Using Firestore service to remove subtask item
                                    Provider.of<TaskFirestoreService>(context,
                                            listen: false)
                                        .removeSubTaskItem(
                                      widget.taskId,
                                      widget.subTaskId,
                                      item.id,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Add new item input form
                  Form(
                    key: _formKey,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _itemTitleController,
                            decoration: InputDecoration(
                              labelText: 'New Item',
                              labelStyle: const TextStyle(
                                  color: AppColors.primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: AppColors.primaryColor),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter an item title';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Button to add new item
                        IconButton(
                          icon: const Icon(Icons.add,
                              color: AppColors.primaryColor),
                          onPressed: () => _addItem(Provider.of<TaskProvider>(
                              context,
                              listen: false)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          return const Center(child: Text('Task not found'));
        }
      },
    );
  }
}
