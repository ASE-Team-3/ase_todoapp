// views/tasks/widget/add_subtask_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/models/subtask.dart';
import 'package:app/providers/task_provider.dart';

class AddSubTaskWidget extends StatefulWidget {
  final String taskId;

  const AddSubTaskWidget({super.key, required this.taskId});

  @override
  _AddSubTaskWidgetState createState() => _AddSubTaskWidgetState();
}

class _AddSubTaskWidgetState extends State<AddSubTaskWidget> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  void _addSubTask() {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      return;
    }

    final newSubTask = SubTask(
      title: _titleController.text,
      description: _descriptionController.text,
    );

    Provider.of<TaskProvider>(context, listen: false)
        .addSubTask(widget.taskId, newSubTask);

    _titleController.clear();
    _descriptionController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(labelText: 'Subtask Title'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          decoration: const InputDecoration(labelText: 'Subtask Description'),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _addSubTask,
          child: const Text('Add Subtask'),
        ),
      ],
    );
  }
}
