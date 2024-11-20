import 'dart:async';
import 'dart:developer';
import 'package:app/utils/deadline_utils.dart';
import 'package:flutter/material.dart';
import 'package:app/models/task.dart';
import 'package:app/models/subtask.dart';
import 'package:app/models/subtask_item.dart';
import 'package:app/models/attachment.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:uuid/uuid.dart';

class TaskProvider extends ChangeNotifier {
  final List<Task> _tasks = [];
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  TaskProvider() {
    _initializeNotifications();
  }

  List<Task> get tasks => _tasks;

  int get completedTasks => _tasks.where((task) => task.isCompleted).length;

  // Initialize notifications
  void _initializeNotifications() {
    log('Initializing notifications...'); // Debug log
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(
            'icon'); // Ensure icon.png exists in res/drawable folder

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        log('Notification clicked with payload: ${response.payload}'); // Debug log for clicks
      },
    );
  }

  // Helper method to send notifications
  Future<void> _sendNotification(String title, String body) async {
    log('Attempting to send notification: $title - $body'); // Debug log

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('channel_id', 'channel_name',
            channelDescription: 'Task Notifications',
            importance: Importance.max,
            priority: Priority.high,
            icon: 'icon', // Use the icon from the drawable folder
            showWhen: true);

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    try {
      await flutterLocalNotificationsPlugin.show(
        0, // Notification ID
        title,
        body,
        platformChannelSpecifics,
      );
      log('Notification sent successfully.'); // Debug log
    } catch (e) {
      log('Error sending notification: $e'); // Log error
    }
  }

  // Add a new task
  void addTask(Task task) {
    if (task.flexibleDeadline != null && task.deadline == null) {
      task = task.copyWith(
          deadline: calculateDeadlineFromFlexible(task.flexibleDeadline!));
    }

    // If repeating, generate occurrences as new tasks with individual deadlines
    if (task.isRepeating) {
      _generateRepeatingTasks(task);
    } else {
      _tasks.add(task);
    }

    notifyListeners();
  }

  void updateTask(
    Task task, {
    required String title,
    required String description,
    DateTime? selectedDeadline,
    String? flexibleDeadline,
    bool? isRepeating,
    String? repeatInterval,
    int? customRepeatDays,
    List<Attachment>? attachments,
  }) {
    // Calculate deadline if flexibleDeadline is provided and selectedDeadline is null
    final DateTime? calculatedDeadline = selectedDeadline ??
        (flexibleDeadline != null
            ? calculateDeadlineFromFlexible(flexibleDeadline)
            : null);

    final updatedTask = task.copyWith(
      title: title,
      description: description,
      deadline: calculatedDeadline,
      flexibleDeadline: flexibleDeadline,
      isRepeating: isRepeating ?? task.isRepeating,
      repeatInterval: repeatInterval ?? task.repeatInterval,
      customRepeatDays: customRepeatDays ?? task.customRepeatDays,
      attachments: attachments ?? task.attachments,
    );

    // Update task in the list
    int index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = updatedTask;

      // If repeating, regenerate occurrences
      if (updatedTask.isRepeating) {
        _generateRepeatingTasks(updatedTask);
      }

      notifyListeners();
    } else {
      log('Task with ID ${task.id} not found for update.');
    }
  }

  // Generate repeating tasks as new tasks with deadlines
  void _generateRepeatingTasks(Task task) {
    if (!task.isRepeating || task.repeatInterval == null) return;

    final DateTime now = DateTime.now();
    final DateTime twoYearsLater = now.add(const Duration(days: 365 * 2));

    DateTime? nextOccurrence = task.deadline ?? task.nextOccurrence;
    while (nextOccurrence != null && nextOccurrence.isBefore(twoYearsLater)) {
      // Create a new task for each occurrence with its unique deadline
      final newTask = task.copyWith(
        id: const Uuid().v4(),
        isCompleted: false, // Reset completion status
        deadline: nextOccurrence,
        nextOccurrence: null, // Only the original task needs `nextOccurrence`
      );

      _tasks.add(newTask);

      // Calculate the next occurrence
      nextOccurrence = _calculateNextOccurrence(
        interval: task.repeatInterval,
        customDays: task.customRepeatDays,
        lastOccurrence: nextOccurrence,
      );
    }

    log('Generated repeating tasks for: ${task.title}');
  }

  // Extend repeating tasks beyond the current 2-year limit
  void extendRepeatingTasks(Task task, int additionalYears) {
    final DateTime newLimit =
        DateTime.now().add(Duration(days: additionalYears * 365));
    _generateRepeatingTasks(task.copyWith(
        deadline: task.deadline?.add(Duration(days: 365 * additionalYears))));
    notifyListeners();
  }

  // Handle overdue tasks by skipping or resetting deadlines
  void handleOverdueTask(Task task, bool skipToNext) {
    if (task.isRepeating && skipToNext) {
      final DateTime? nextDeadline = _calculateNextOccurrence(
        interval: task.repeatInterval,
        customDays: task.customRepeatDays,
        lastOccurrence: task.deadline ?? DateTime.now(),
      );

      if (nextDeadline != null) {
        updateTask(
          task,
          title: task.title,
          description: task.description,
          selectedDeadline: nextDeadline,
          isRepeating: task.isRepeating,
          repeatInterval: task.repeatInterval,
        );

        log('Skipped overdue task: ${task.title}. New deadline: $nextDeadline');
      }
    }
  }

  // Edit a specific occurrence's deadline
  void editTaskDeadline(String taskId, DateTime newDeadline) {
    final int index = _tasks.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      final Task task = _tasks[index].copyWith(deadline: newDeadline);
      _tasks[index] = task;
      notifyListeners();
      log('Updated deadline for task: ${task.title} to $newDeadline');
    } else {
      log('Task with ID $taskId not found for deadline update.');
    }
  }

  // Helper to calculate the next occurrence
  DateTime _calculateNextOccurrence({
    required String? interval,
    required int? customDays,
    required DateTime lastOccurrence,
  }) {
    switch (interval) {
      case "daily":
        return lastOccurrence.add(const Duration(days: 1));
      case "weekly":
        return lastOccurrence.add(const Duration(days: 7));
      case "monthly":
        return DateTime(
          lastOccurrence.year,
          lastOccurrence.month + 1,
          lastOccurrence.day,
          lastOccurrence.hour,
          lastOccurrence.minute,
        );
      case "yearly":
        return DateTime(
          lastOccurrence.year + 1,
          lastOccurrence.month,
          lastOccurrence.day,
          lastOccurrence.hour,
          lastOccurrence.minute,
        );
      case "custom":
        if (customDays != null) {
          return lastOccurrence.add(Duration(days: customDays));
        }
        break;
    }
    throw Exception("Invalid repeat interval or custom days");
  }

  // Existing methods remain unchanged
  void toggleTaskCompletion(Task task) {
    task.isCompleted = !task.isCompleted; // Toggle completion status
    if (task.isCompleted) {
      // Show notification when a task is completed
      _sendNotification('Hurrah!', 'You completed the task: "${task.title}"!');
    } else {
      log('Task marked as incomplete: "${task.title}"'); // Debug log
    }
    notifyListeners();
  }

  Task? getTaskById(String taskId) {
    try {
      return _tasks.firstWhere((task) => task.id == taskId);
    } catch (e) {
      log('Task with ID $taskId not found');
      return null;
    }
  }

  void removeTask(Task task) {
    if (_tasks.any((t) => t.id == task.id)) {
      _tasks.removeWhere((t) => t.id == task.id);
      notifyListeners();
    } else {
      log('Task not found for deletion');
    }
  }

  void deleteRepeatingTasks(Task task, {required String option}) {
    switch (option) {
      case "all":
        _deleteAllRepeatingTasks(task);
        break;
      case "this_and_following":
        _deleteThisAndFollowingTasks(task);
        break;
      case "only_this":
        _deleteOnlyThisTask(task);
        break;
      default:
        log('Unknown delete option: $option');
    }
    notifyListeners();
  }

// Delete all occurrences of the repeating task
  void _deleteAllRepeatingTasks(Task task) {
    final originalTaskId = task.id;
    _tasks.removeWhere(
        (t) => t.id == originalTaskId || _isGeneratedFromTask(t, task));
    log('Deleted all occurrences of repeating task: ${task.title}');
  }

// Delete this task and all subsequent occurrences
  void _deleteThisAndFollowingTasks(Task task) {
    final taskIndex = _tasks.indexWhere((t) => t.id == task.id);
    if (taskIndex != -1) {
      final DateTime? startDeleteFrom = _tasks[taskIndex].deadline;
      _tasks.removeWhere((t) =>
          t.id == task.id ||
          (_isGeneratedFromTask(t, task) &&
              t.deadline != null &&
              t.deadline!.isAfter(startDeleteFrom!)));
      log('Deleted task: ${task.title} and all subsequent occurrences.');
    } else {
      log('Task not found for deletion: ${task.title}');
    }
  }

// Delete only this specific task occurrence
  void _deleteOnlyThisTask(Task task) {
    _tasks.removeWhere((t) => t.id == task.id);
    log('Deleted only this occurrence of task: ${task.title}');
  }

// Helper to check if a task is generated from the original task
  bool _isGeneratedFromTask(Task generatedTask, Task originalTask) {
    return generatedTask.title == originalTask.title &&
        generatedTask.description == originalTask.description &&
        generatedTask.isRepeating == true &&
        generatedTask.repeatInterval == originalTask.repeatInterval;
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
