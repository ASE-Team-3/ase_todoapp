// views/tasks/widget/add_subtask_item_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/models/subtask_item.dart';
import 'package:app/providers/task_provider.dart';

class AddSubTaskItemWidget extends StatefulWidget {
  final String taskId;
  final String subTaskId;

  const AddSubTaskItemWidget(
      {super.key, required this.taskId, required this.subTaskId});

  @override
  _AddSubTaskItemWidgetState createState() => _AddSubTaskItemWidgetState();
}

class _AddSubTaskItemWidgetState extends State<AddSubTaskItemWidget> {
  final _itemController = TextEditingController();

  void _addSubTaskItem() {
    if (_itemController.text.isEmpty) return;

    final newItem = SubTaskItem(title: _itemController.text);

    Provider.of<TaskProvider>(context, listen: false)
        .addSubTaskItem(widget.taskId, widget.subTaskId, newItem);

    _itemController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _itemController,
          decoration: const InputDecoration(labelText: 'Subtask Item Title'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _addSubTaskItem,
          child: const Text('Add Item'),
        ),
      ],
    );
  }
}
