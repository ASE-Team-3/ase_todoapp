import 'dart:async';
import 'dart:developer';
import 'package:app/utils/deadline_utils.dart';
import 'package:app/models/points_history_entry.dart';
import 'package:flutter/material.dart';
import 'package:app/models/task.dart';
import 'package:app/models/subtask.dart';
import 'package:app/models/subtask_item.dart';
import 'package:app/models/attachment.dart';
import 'package:app/providers/points_manager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:uuid/uuid.dart';

class TaskProvider extends ChangeNotifier {
  final List<Task> _tasks = [];
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final PointsManager _pointsManager =
      PointsManager(); // PointsManager instance

  TaskProvider() {
    _initializeNotifications();
  }
  List<PointsHistoryEntry> get pointsHistory => _pointsManager.history;

  List<Task> get tasks => _tasks;

  int get totalPoints => _pointsManager.totalPoints;

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
        deadline: calculateDeadlineFromFlexible(task.flexibleDeadline!),
      );
    }

    if (task.isRepeating) {
      // Generate a group ID for all repeating tasks
      final repeatingGroupId = const Uuid().v4();
      final taskWithGroupId = task.copyWith(repeatingGroupId: repeatingGroupId);

      _generateRepeatingTasks(taskWithGroupId, repeatingGroupId);
    } else {
      _tasks.add(task);
    }

    notifyListeners();
  }

  // Update a task
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
    int? points,
  }) {
    final DateTime? calculatedDeadline = selectedDeadline ??
        (flexibleDeadline != null
            ? calculateDeadlineFromFlexible(flexibleDeadline)
            : null);

    final updatedTask = task.copyWith(
      title: title,
      description: description,
      deadline: calculatedDeadline,
      flexibleDeadline: flexibleDeadline,
      points: points ?? task.points,
      isRepeating: isRepeating ?? task.isRepeating,
      repeatInterval: repeatInterval ?? task.repeatInterval,
      customRepeatDays: customRepeatDays ?? task.customRepeatDays,
      attachments: attachments ?? task.attachments,
    );

    int index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = updatedTask;

      if (updatedTask.isRepeating) {
        _generateRepeatingTasks(updatedTask, updatedTask.repeatingGroupId);
      }

      notifyListeners();
    } else {
      log('Task with ID ${task.id} not found for update.');
    }
  }

// Updated _generateRepeatingTasks to accept a limit parameter
  void _generateRepeatingTasks(Task task, String? groupId, {DateTime? limit}) {
    if (!task.isRepeating || task.repeatInterval == null) return;

    final DateTime now = DateTime.now();
    final DateTime defaultLimit =
        now.add(const Duration(days: 730)); // Default: 2 years
    final DateTime generationLimit = limit ?? defaultLimit;

    DateTime? nextOccurrence = task.deadline ?? task.nextOccurrence;
    while (nextOccurrence != null && nextOccurrence.isBefore(generationLimit)) {
      // Create a new task for each occurrence with its unique deadline
      final newTask = task.copyWith(
        id: const Uuid().v4(),
        isCompleted: false, // Reset completion status
        deadline: nextOccurrence,
        repeatingGroupId: groupId, // Ensure groupId is consistent
        nextOccurrence: null, // Only the original task has `nextOccurrence`
      );

      _tasks.add(newTask);

      // Calculate the next occurrence
      nextOccurrence = _calculateNextOccurrence(
        interval: task.repeatInterval,
        customDays: task.customRepeatDays,
        lastOccurrence: nextOccurrence,
      );
    }

    log('Extended repeating tasks for: ${task.title}');
  }

  void updateRepeatingTasks(
    Task task, {
    required String option, // "all", "this_and_following", "only_this"
    required String title,
    required String description,
    DateTime? selectedDeadline, // New specific deadline
    String? flexibleDeadline, // New flexible deadline
    String? repeatInterval, // New repeat interval (e.g., "daily", "monthly")
    int? customRepeatDays,
    int? points, // Custom interval days
  }) {
    final groupId = task.repeatingGroupId;
    if (groupId == null) return;

    if (option == "all") {
      // Update all tasks with the same repeating groupId
      final firstTask = _tasks.firstWhere((t) => t.id == task.id);
      DateTime baseDeadline = selectedDeadline ??
          calculateDeadlineFromFlexible(flexibleDeadline!) ??
          firstTask.deadline!;

      for (int i = 0; i < _tasks.length; i++) {
        if (_tasks[i].repeatingGroupId == groupId) {
          final taskIndex = i;
          _tasks[taskIndex] = _tasks[taskIndex].copyWith(
            title: title,
            description: description,
            points: points,
            deadline: _calculateDynamicDeadline(
              startDate: baseDeadline,
              interval: repeatInterval ?? task.repeatInterval,
              customDays: customRepeatDays ?? task.customRepeatDays,
              iteration:
                  taskIndex, // Adjust iteration for dynamic recalculation
            ),
            repeatInterval: repeatInterval ?? _tasks[taskIndex].repeatInterval,
            customRepeatDays: customRepeatDays,
            flexibleDeadline: flexibleDeadline,
          );
        }
      }
    } else if (option == "this_and_following") {
      // Update this and all subsequent tasks
      bool update = false;
      DateTime baseDeadline = selectedDeadline ??
          calculateDeadlineFromFlexible(flexibleDeadline!) ??
          task.deadline!;

      for (int i = 0; i < _tasks.length; i++) {
        if (_tasks[i].id == task.id) {
          update = true;
        }

        if (update && _tasks[i].repeatingGroupId == groupId) {
          final taskIndex = i;
          final iterationOffset =
              taskIndex - _tasks.indexWhere((t) => t.id == task.id);
          _tasks[taskIndex] = _tasks[taskIndex].copyWith(
            title: title,
            description: description,
            points: points,
            deadline: _calculateDynamicDeadline(
              startDate: baseDeadline,
              interval: repeatInterval ?? task.repeatInterval,
              customDays: customRepeatDays ?? task.customRepeatDays,
              iteration: iterationOffset,
            ),
            repeatInterval: repeatInterval ?? _tasks[taskIndex].repeatInterval,
            customRepeatDays: customRepeatDays,
            flexibleDeadline: flexibleDeadline,
          );
        }
      }
    } else if (option == "only_this") {
      // Update only this specific task
      int index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = _tasks[index].copyWith(
          title: title,
          description: description,
          points: points,
          deadline: selectedDeadline ?? _tasks[index].deadline,
          flexibleDeadline: flexibleDeadline ?? _tasks[index].flexibleDeadline,
          repeatInterval: repeatInterval ?? _tasks[index].repeatInterval,
          customRepeatDays: customRepeatDays ?? _tasks[index].customRepeatDays,
        );
      }
    }

    notifyListeners();
  }

  // Helper to calculate updated deadlines dynamically for repeating tasks
  DateTime _calculateDynamicDeadline({
    required DateTime startDate,
    required String? interval,
    required int? customDays,
    required int iteration,
  }) {
    DateTime nextOccurrence = startDate;

    for (int i = 0; i < iteration; i++) {
      nextOccurrence = _calculateNextOccurrence(
        interval: interval,
        customDays: customDays,
        lastOccurrence: nextOccurrence,
      );
    }

    return nextOccurrence;
  }

  // Extend repeating tasks beyond the current 2-year limit
  void extendRepeatingTasks(Task task, int additionalYears) {
    // Calculate the new end date based on the additional years
    final DateTime currentLimit = task.deadline ?? DateTime.now();
    final DateTime newLimit =
        currentLimit.add(Duration(days: additionalYears * 365));

    // Regenerate tasks up to the new limit
    _generateRepeatingTasks(
      task.copyWith(deadline: task.deadline), // Use the original deadline
      task.repeatingGroupId, // Ensure repeatingGroupId is preserved
      limit: newLimit, // Pass the new limit for task generation
    );

    notifyListeners();
  }

  // Handle overdue tasks by skipping or resetting deadlines
  void handleOverdueTask(Task task, bool skipToNext) {
    if (task.isRepeating && skipToNext) {
      final DateTime nextDeadline = _calculateNextOccurrence(
        interval: task.repeatInterval,
        customDays: task.customRepeatDays,
        lastOccurrence: task.deadline ?? DateTime.now(),
      );

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

  void toggleTaskCompletion(Task task) {
    final isNowCompleted = !task.isCompleted;
    task.isCompleted = isNowCompleted; // Toggle completion status.

    if (isNowCompleted) {
      _pointsManager.awardPoints(
        task.points,
        'Task "${task.title}" completed',
      );
      _sendNotification('Hurrah!', 'You completed the task: "${task.title}"!');
    } else {
      _pointsManager.deductPoints(
        task.points,
        'Task "${task.title}" marked as incomplete',
      );
      log('Task marked as incomplete: "${task.title}"');
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

  // Remove a task
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
        if (task.repeatingGroupId != null) {
          deleteTasksByGroupId(task.repeatingGroupId!);
        } else {
          log('Task does not have a repeatingGroupId: ${task.title}');
        }
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

  // Delete this task and all subsequent occurrences
  void _deleteThisAndFollowingTasks(Task task) {
    if (task.repeatingGroupId == null) {
      log('Task does not have a repeatingGroupId: ${task.title}');
      return;
    }

    final groupId = task.repeatingGroupId;
    final taskDeadline = task.deadline;

    if (taskDeadline == null) {
      log('Task deadline is null: ${task.title}');
      return;
    }

    // Find all tasks with the same groupId and deadlines after or equal to the current task's deadline
    final tasksToDelete = _tasks.where((t) {
      return t.repeatingGroupId == groupId &&
              t.deadline != null &&
              t.deadline!.isAfter(taskDeadline) ||
          t.deadline!.isAtSameMomentAs(taskDeadline);
    }).toList();

    if (tasksToDelete.isNotEmpty) {
      _tasks.removeWhere((t) => tasksToDelete.contains(t));
      log('Deleted ${tasksToDelete.length} tasks in group $groupId from and after deadline $taskDeadline');
      notifyListeners(); // Notify listeners about the update
    } else {
      log('No tasks found to delete for repeatingGroupId: $groupId starting from $taskDeadline');
    }
  }

  // Delete only this specific task occurrence
  void _deleteOnlyThisTask(Task task) {
    _tasks.removeWhere((t) => t.id == task.id);
    log('Deleted only this occurrence of task: ${task.title}');
  }

  // Delete all tasks linked to a specific repeatingGroupId
  void deleteTasksByGroupId(String repeatingGroupId) {
    // Filter and remove all tasks with the specified groupId
    final tasksToDelete = _tasks
        .where((task) => task.repeatingGroupId == repeatingGroupId)
        .toList();

    if (tasksToDelete.isNotEmpty) {
      _tasks.removeWhere((task) => task.repeatingGroupId == repeatingGroupId);
      log('Deleted ${tasksToDelete.length} tasks with repeatingGroupId: $repeatingGroupId');
      notifyListeners(); // Notify listeners about the change
    } else {
      log('No tasks found with repeatingGroupId: $repeatingGroupId');
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
