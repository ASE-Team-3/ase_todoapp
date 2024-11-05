// providers/task_provider.dart
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:app/models/task.dart';
import 'package:app/models/subtask.dart';
import 'package:app/models/subtask_item.dart';
import 'package:app/models/attachment.dart';

class TaskProvider extends ChangeNotifier {
  final List<Task> _tasks = [];

  List<Task> get tasks => _tasks;

  // Add a new task
  void addTask(Task task) {
    _tasks.add(task);
    notifyListeners();
  }

  void updateTask(Task updatedTask) {
    int index = _tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      notifyListeners();
    } else {
      throw Exception('Task with ID ${updatedTask.id} not found');
    }
  }

  // Method to retrieve a task by ID
  Task? getTaskById(String taskId) {
    try {
      return _tasks.firstWhere((task) => task.id == taskId);
    } catch (e) {
      log('Task with ID $taskId not found');
      return null; // Return null if task is not found
    }
  }

  // Toggle task completion status
  void toggleTaskCompletion(Task task) {
    task.isCompleted = !task.isCompleted;
    notifyListeners();
  }

  // Remove a task
  void removeTask(Task task) {
    if (_tasks.any((t) => t.id == task.id)) {
      _tasks.removeWhere((t) => t.id == task.id);
      notifyListeners();
    } else {
      log('Task not found for deletion');
    }
  }

  // Add a sub-task to a task
  void addSubTask(String taskId, SubTask subTask) {
    Task task = _tasks.firstWhere(
      (t) => t.id == taskId,
      orElse: () => throw Exception('Task with ID $taskId not found'),
    );

    task.subTasks.add(subTask);
    notifyListeners();
  }

  // Remove a sub-task from a task
  void removeSubTask(String taskId, String subTaskId) {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    task.subTasks.removeWhere((st) => st.id == subTaskId);
    toggleTaskCompletion(task);
    notifyListeners();
  }

  void toggleSubTaskCompletion(String taskId, String subTaskId) {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final subTask = task.subTasks.firstWhere((st) => st.id == subTaskId);

    // Toggle the completion status of the subtask
    subTask.isCompleted = !subTask.isCompleted;

    // Check if all subtasks are completed and update the task's completion status
    task.isCompleted = task.subTasks.every((subTask) => subTask.isCompleted);

    notifyListeners();
  }

  void addSubTaskItem(String taskId, String subTaskId, SubTaskItem item) {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final subTask = task.subTasks.firstWhere((st) => st.id == subTaskId);
    subTask.items.add(item);
    subTask.toggleCompletion();
    toggleTaskCompletion(task);
    notifyListeners();
  }

  void toggleSubTaskItemCompletion(
      String taskId, String subTaskId, String itemId) {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final subTask = task.subTasks.firstWhere((st) => st.id == subTaskId);
    final item = subTask.items.firstWhere((i) => i.id == itemId);
    item.isCompleted = !item.isCompleted;
    subTask.toggleCompletion();
    toggleTaskCompletion(task);
    notifyListeners();
  }

  void removeSubTaskItem(String taskId, String subTaskId, String itemId) {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final subTask = task.subTasks.firstWhere((st) => st.id == subTaskId);
    subTask.items.removeWhere((i) => i.id == itemId);
    subTask.toggleCompletion();
    toggleTaskCompletion(task);
    notifyListeners();
  }

  void addAttachment(String taskId, Attachment attachment) {
    Task task = _tasks.firstWhere((t) => t.id == taskId);
    task.attachments.add(attachment);
    notifyListeners();
  }

  void removeAttachment(String taskId, String attachmentId) {
    Task task = _tasks.firstWhere((t) => t.id == taskId);
    task.attachments.removeWhere((a) => a.id == attachmentId);
    notifyListeners();
  }
}
