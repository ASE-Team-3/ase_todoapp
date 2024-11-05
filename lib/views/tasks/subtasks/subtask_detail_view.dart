import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/models/subtask_item.dart';
import 'package:app/providers/task_provider.dart';
import 'package:app/utils/app_colors.dart';

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

  void _addItem(TaskProvider taskProvider) {
    if (_formKey.currentState!.validate()) {
      final newItem = SubTaskItem(title: _itemTitleController.text);

      taskProvider.addSubTaskItem(widget.taskId, widget.subTaskId, newItem);
      _itemTitleController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    TaskProvider taskProvider = Provider.of<TaskProvider>(context);
    final task = taskProvider.getTaskById(widget.taskId);
    final subTask =
        task?.subTasks.firstWhere((st) => st.id == widget.subTaskId);

    if (task == null || subTask == null) {
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
        body: const Center(child: Text('Subtask not found')),
      );
    }

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
                          Checkbox(
                            value: item.isCompleted,
                            onChanged: (value) {
                              taskProvider.toggleSubTaskItemCompletion(
                                  widget.taskId, widget.subTaskId, item.id);
                            },
                            activeColor: AppColors.primaryColor,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              taskProvider.removeSubTaskItem(
                                  widget.taskId, widget.subTaskId, item.id);
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
            Form(
              key: _formKey,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _itemTitleController,
                      decoration: InputDecoration(
                        labelText: 'New Item',
                        labelStyle:
                            const TextStyle(color: AppColors.primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: AppColors.primaryColor),
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
                  IconButton(
                    icon: const Icon(Icons.add, color: AppColors.primaryColor),
                    onPressed: () => _addItem(taskProvider),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
