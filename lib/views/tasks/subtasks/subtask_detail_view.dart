import 'package:app/providers/task_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/models/subtask_item.dart';
import 'package:app/services/task_firestore_service.dart';
import 'package:app/utils/app_colors.dart';
import 'package:app/models/subtask.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // Function to add a new item
  void _addItem(TaskProvider taskProvider) {
    if (_formKey.currentState!.validate()) {
      final newItem = SubTaskItem(title: _itemTitleController.text);
      taskProvider.addSubTaskItem(widget.taskId, widget.subTaskId, newItem);
      _itemTitleController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskService =
        Provider.of<TaskFirestoreService>(context, listen: false);

    return StreamBuilder<SubTask>(
      stream: taskService.getSubTaskById(widget.taskId, widget.subTaskId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return _buildScaffold(
              context, const Center(child: Text('Error loading subtask')));
        } else if (snapshot.hasData) {
          final subTask = snapshot.data!;

          return _buildScaffold(
            context,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSubTaskDetails(subTask),
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
                  child: subTask.items.isNotEmpty
                      ? ListView.builder(
                          itemCount: subTask.items.length,
                          itemBuilder: (context, index) {
                            final item = subTask.items[index];
                            return _buildItemCard(context, item);
                          },
                        )
                      : const Center(
                          child: Text("No items available. Add one below!"),
                        ),
                ),
                const SizedBox(height: 20),
                _buildAddItemForm(context),
              ],
            ),
          );
        } else {
          return _buildScaffold(
              context, const Center(child: Text('Subtask not found')));
        }
      },
    );
  }

  // Build the scaffold with a custom body
  Scaffold _buildScaffold(BuildContext context, Widget body) {
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: body,
      ),
    );
  }

  // SubTask Details Section
  Widget _buildSubTaskDetails(SubTask subTask) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          subTask.title,
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          subTask.description,
          style: const TextStyle(color: Colors.black87, fontSize: 16),
        ),
        const SizedBox(height: 10),

        // Additional Details for Paper Type
        if (subTask.type == SubTaskType.paper) ...[
          if (subTask.author != null)
            Text(
              'Author: ${subTask.author}',
              style: const TextStyle(color: Colors.black87),
            ),
          if (subTask.publishDate != null)
            Text(
              'Publish Date: ${subTask.publishDate?.toLocal().toString().split(' ')[0]}',
              style: const TextStyle(color: Colors.black87),
            ),
          if (subTask.url != null)
            GestureDetector(
              onTap: () async {
                final url = Uri.parse(subTask.url!);
                await launchUrl(url);
              },
              child: Text(
                'URL: ${subTask.url}',
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
        ],
      ],
    );
  }

  // Form to add a new item
  Widget _buildAddItemForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _itemTitleController,
              decoration: InputDecoration(
                labelText: 'New Item',
                labelStyle: const TextStyle(color: AppColors.primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primaryColor),
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
            onPressed: () =>
                _addItem(Provider.of<TaskProvider>(context, listen: false)),
          ),
        ],
      ),
    );
  }

  // Build each item card
  Widget _buildItemCard(BuildContext context, SubTaskItem item) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                Provider.of<TaskFirestoreService>(context, listen: false)
                    .toggleSubTaskItemCompletion(
                  widget.taskId,
                  widget.subTaskId,
                  item.id,
                );
              },
              activeColor: AppColors.primaryColor,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                Provider.of<TaskFirestoreService>(context, listen: false)
                    .removeSubTaskItem(
                        widget.taskId, widget.subTaskId, item.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
