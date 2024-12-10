import 'package:app/providers/task_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/models/subtask.dart';
import 'package:app/services/task_firestore_service.dart'; // Import Firestore service
import 'package:app/utils/app_colors.dart';

class AddSubTaskWidget extends StatefulWidget {
  final String taskId;

  const AddSubTaskWidget({super.key, required this.taskId});

  @override
  _AddSubTaskWidgetState createState() => _AddSubTaskWidgetState();
}

class _AddSubTaskWidgetState extends State<AddSubTaskWidget> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Add subtask function to use Firestore service for adding the subtask
  void _addSubTask() async {
    if (_formKey.currentState!.validate()) {
      final newSubTask = SubTask(
        title: _titleController.text,
        description: _descriptionController.text,
      );

      try {
        // Use Firestore service to add the subtask
        await Provider.of<TaskProvider>(context, listen: false)
            .addSubTask(widget.taskId, newSubTask);

        // Clear the form fields after adding
        _titleController.clear();
        _descriptionController.clear();

        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subtask added successfully')),
        );

        // Close the modal
        Navigator.pop(context);
      } catch (e) {
        // Handle error if adding subtask fails
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding subtask: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Subtask',
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Subtask Title',
                    labelStyle: TextStyle(color: AppColors.primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.primaryColor),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Subtask Description',
                    labelStyle: TextStyle(color: AppColors.primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.primaryColor),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _addSubTask, // Calling the method to add subtask
                    icon: const Icon(Icons.add),
                    label: const Text('Add Subtask'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
