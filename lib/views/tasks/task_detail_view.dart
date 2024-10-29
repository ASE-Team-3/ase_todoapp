// views/tasks/task_detail_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/models/task.dart';
import 'package:app/providers/task_provider.dart';
import 'widget/add_subtask_widget.dart';
import 'widget/add_subtask_item_widget.dart';

class TaskDetailView extends StatelessWidget {
  final String taskId;

  const TaskDetailView({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    TaskProvider taskProvider = Provider.of<TaskProvider>(context);
    Task task = taskProvider.tasks.firstWhere((t) => t.id == taskId);

    return Scaffold(
      appBar: AppBar(
        title: Text(task.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.description,
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 20),
            Text('Subtasks', style: Theme.of(context).textTheme.headlineSmall),
            Expanded(
              child: ListView.builder(
                itemCount: task.subTasks.length,
                itemBuilder: (context, index) {
                  final subTask = task.subTasks[index];
                  return Card(
                    child: ExpansionTile(
                      title: Text(subTask.title),
                      subtitle: Text(subTask.description),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: subTask.isCompleted,
                            onChanged: (value) {
                              taskProvider.toggleTaskCompletion(task);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              taskProvider.removeSubTask(task.id, subTask.id);
                            },
                          ),
                        ],
                      ),
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          itemCount: subTask.items.length,
                          itemBuilder: (context, itemIndex) {
                            final item = subTask.items[itemIndex];
                            return ListTile(
                              title: Text(item.title),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Checkbox(
                                    value: item.isCompleted,
                                    onChanged: (value) {
                                      taskProvider.toggleSubTaskItemCompletion(
                                          task.id, subTask.id, item.id);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () {
                                      taskProvider.removeSubTaskItem(
                                          task.id, subTask.id, item.id);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        AddSubTaskItemWidget(
                            taskId: task.id, subTaskId: subTask.id),
                      ],
                    ),
                  );
                },
              ),
            ),
            AddSubTaskWidget(taskId: task.id),
          ],
        ),
      ),
    );
  }
}
