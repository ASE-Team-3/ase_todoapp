import 'dart:developer';
import 'package:app/helpers/notification_helpers.dart';
import 'package:app/helpers/task_helpers.dart';
import 'package:app/services/notification_service.dart';
import 'package:app/services/research_service.dart';
import 'package:app/utils/datetime_utils.dart';
import 'package:app/utils/deadline_utils.dart';
import 'package:app/models/points_history_entry.dart';
import 'package:app/utils/keyword_generator.dart';
import 'package:app/utils/notification_utils.dart';
import 'package:flutter/material.dart';
import 'package:app/models/task.dart';
import 'package:app/models/subtask.dart';
import 'package:app/models/subtask_item.dart';
import 'package:app/models/attachment.dart';
import 'package:app/providers/points_manager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firebase Firestore import
import 'package:app/services/task_firestore_service.dart'; // Firebase service for tasks

class TaskProvider extends ChangeNotifier {
  final List<Task> _tasks = [];
  final ResearchService _researchService;
  final NotificationService _notificationService;
  final PointsManager _pointsManager =
      PointsManager(); // PointsManager instance
  final NotificationThrottler _notificationThrottler = NotificationThrottler();
  final TaskFirestoreService _taskService =
      TaskFirestoreService(); // Firestore service

  TaskProvider(FlutterLocalNotificationsPlugin plugin,
      {required ResearchService researchService})
      : _notificationService = NotificationService(plugin),
        _researchService = researchService {
    _notificationService.initialize();
    loadTasks(); // Load tasks from Firestore on initialization
    log('TaskProvider initialized and tasks loaded.');
  }

  List<PointsHistoryEntry> get pointsHistory => _pointsManager.history;
  int get totalPoints => _pointsManager.totalPoints;
  int get completedTasks => _tasks.where((task) => task.isCompleted).length;

  /// This function retrieves the list of tasks with their `DateTime` fields
  /// (such as `creationDate`, `deadline`, and `nextOccurrence`) converted
  /// from UTC to the user's local timezone.
  ///
  /// Usage:
  /// - Call this function whenever you need to display or manipulate tasks
  ///   with localized `DateTime` values.
  ///
  /// Note:
  /// - All operations on tasks (e.g., filtering by deadline) should use
  ///   the output of this function to ensure correct time interpretation.
  ///
  ///
  /// Returns:
  /// - A `List<Task>` where all `DateTime` fields are converted to local time.
  List<Task> Function() get tasks => () {
        return _tasks.map((task) {
          return task.copyWith(
            creationDate: convertUtcToLocal(task.creationDate),
            deadline: convertUtcToLocal(task.deadline),
            nextOccurrence: convertUtcToLocal(task.nextOccurrence),
            createdBy: task.createdBy, // Preserve the original `createdBy`
            assignedBy: task.assignedBy, // Preserve the original `assignedBy`
            assignedTo: task.assignedTo, // Preserve the original `assignedTo`
          );
        }).toList();
      };

  /// Loads tasks from Firestore and updates the local task list.
  void loadTasks() {
    log('Loading tasks from Firestore...');
    _taskService.getTasksForUser().listen((tasksFromFirestore) {
      _tasks.clear();
      _tasks.addAll(tasksFromFirestore); // Add the fetched tasks to the list
      notifyListeners(); // Notify listeners to update the UI
      log('Tasks loaded from Firestore and updated.');
    });
  }

  /// Adds a task to Firestore and schedules notifications if necessary.
  void addTask(Task task) async {
    log('Adding task: ${task.title}');
    if (task.category == "Research") {
      task = await _prepareResearchTask(task);
      log('Research task prepared: ${task.title}');
    }

    // Ensure deadlines are in UTC
    task = task.copyWith(
      deadline: task.deadline?.toUtc(),
      alertFrequency: task.alertFrequency, // Handle alert frequency
      customReminder: task.customReminder, // Handle custom reminder
    );

    if (task.flexibleDeadline != null && task.deadline == null) {
      final localDeadline =
          calculateDeadlineFromFlexible(task.flexibleDeadline!);
      task = task.copyWith(deadline: localDeadline?.toUtc());
    }

    if (!task.isCompleted && task.deadline != null) {
      _notificationService.scheduleNotification(
        title: 'Task Reminder',
        body: 'Don\'t forget: "${task.title}" is due soon!',
        deadline: task.deadline!,
        alertFrequency: task.alertFrequency,
        customReminder: task.customReminder,
      );
      log('Notification scheduled for task: ${task.title}');
    }
    // Handle repeating tasks
    if (task.isRepeating) {
      final repeatingGroupId = const Uuid().v4();
      final taskWithGroupId = task.copyWith(repeatingGroupId: repeatingGroupId);
      _taskService.generateRepeatingTasks(taskWithGroupId, repeatingGroupId);
    } else {
      // Add single instance task to the list
      await _taskService.addTask(task);
      log('Task added to Firestore: ${task.title}');
    }

    // Notify listeners about the new task
    notifyListeners();
  }

  /// Prepares a research task by generating keywords and fetching related papers.
  Future<Task> _prepareResearchTask(Task task) async {
    // Check if the task already has keywords
    if (task.keywords.isEmpty) {
      // Generate Keywords only if none exist
      final generatedKeywords =
          KeywordGenerator.generate(task.title, task.description);
      task = task.copyWith(keywords: generatedKeywords);
      log('Keywords generated for research task: ${task.title}');
    }

    // Fetch Related Research Papers
    try {
      final relatedPapers =
          await _researchService.fetchRelatedResearch(task.keywords);
      if (relatedPapers.isNotEmpty) {
        task = task.copyWith(
          suggestedPaper: relatedPapers[0]['title'],
          suggestedPaperUrl: relatedPapers[0]['url'],
          suggestedPaperAuthor: relatedPapers[0]['author'],
          suggestedPaperPublishDate: relatedPapers[0]['publishDate'],
        );
        log('Research papers found and added to task: ${task.title}');
      }
    } catch (e) {
      log("Error fetching research papers: $e");
      throw Exception("Failed to refresh suggested paper: $e");
    }

    return task;
  }

  Future<void> refreshSuggestedPaper(String taskId) async {
    final task = getTaskById(taskId);
    if (task == null) return;

    try {
      final newPaper =
          await _researchService.fetchDailyResearchPaper(task.keywords);
      updateTask(
        task,
        title: task.title,
        description: task.description,
        suggestedPaper: newPaper['title'],
        suggestedPaperAuthor: newPaper['author'],
        suggestedPaperPublishDate: newPaper['publishDate'],
        suggestedPaperUrl: newPaper['url'],
      );
      notifyListeners();
    } catch (e) {
      throw Exception("Failed to refresh suggested paper: $e");
    }
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
    int? points,
    String? category, // Add category
    List<String>? keywords, // Add keywords
    String? alertFrequency,
    Map<String, dynamic>? customReminder,
    String? suggestedPaper, // Add suggested paper title
    String? suggestedPaperAuthor, // Add suggested paper author
    String? suggestedPaperPublishDate, // Add suggested paper publish date
    String? suggestedPaperUrl, // Add suggested paper URL
  }) async {
    // Calculate new deadline
    final DateTime? calculatedDeadline = selectedDeadline?.toUtc() ??
        calculateFlexibleDeadline(flexibleDeadline);

    // Handle category change or research-related updates
    if (category != null && category == "Research") {
      task = await _prepareResearchTaskForUpdate(
        task: task,
        title: title,
        description: description,
        category: category,
        keywords: keywords,
      );
    } else if (category != null && category != task.category) {
      task = task.copyWith(
        category: category,
        keywords: [], // Clear keywords for non-research tasks
        suggestedPaper: null,
        suggestedPaperAuthor: null,
        suggestedPaperPublishDate: null,
        suggestedPaperUrl: null,
      );
    }

    // Update the task
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
      category: category ?? task.category,
      keywords: keywords ?? task.keywords,
      alertFrequency: alertFrequency ?? task.alertFrequency,
      customReminder: customReminder ?? task.customReminder,
      suggestedPaper: suggestedPaper ?? task.suggestedPaper,
      suggestedPaperAuthor: suggestedPaperAuthor ?? task.suggestedPaperAuthor,
      suggestedPaperPublishDate:
          suggestedPaperPublishDate ?? task.suggestedPaperPublishDate,
      suggestedPaperUrl: suggestedPaperUrl ?? task.suggestedPaperUrl,
      updatedAt: DateTime.now().toUtc(),
    );

    // Schedule notification
    scheduleTaskNotification(
      notificationService: _notificationService,
      task: updatedTask,
      title: 'Updated Reminder',
    );

    await _taskService.updateTask(updatedTask);
    log('Task updated in Firestore: ${task.title}');

    // Regenerate repeating tasks if needed
    if (updatedTask.isRepeating) {
      _taskService.generateRepeatingTasks(
          updatedTask, updatedTask.repeatingGroupId);
    }

    // Find the task index and update it
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      notifyListeners();
      log('Task updated in local list: ${task.title}');
    } else {
      log('Task with ID ${task.id} not found for update.');
    }
  }

  Future<Task> _prepareResearchTaskForUpdate({
    required Task task,
    required String title,
    required String description,
    required String category,
    List<String>? keywords,
  }) async {
    // Regenerate keywords if not explicitly provided
    final newKeywords =
        keywords ?? KeywordGenerator.generate(title, description);

    task = task.copyWith(
      category: category,
      keywords: newKeywords,
    );

    // Fetch related research papers if necessary
    try {
      final relatedPapers =
          await _researchService.fetchRelatedResearch(newKeywords);
      if (relatedPapers.isNotEmpty) {
        task = task.copyWith(
          suggestedPaper: relatedPapers[0]['title'],
          suggestedPaperUrl: relatedPapers[0]['url'],
        );
      } else {
        task = task.copyWith(suggestedPaper: null, suggestedPaperUrl: null);
      }
    } catch (e) {
      log("Error fetching research papers: $e");
      task = task.copyWith(suggestedPaper: null, suggestedPaperUrl: null);
    }

    return task;
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

    // Convert selectedDeadline to UTC
    final DateTime? utcSelectedDeadline = selectedDeadline?.toUtc();

    if (option == "all") {
      // Update all tasks with the same repeating groupId
      final firstTask = _tasks.firstWhere((t) => t.id == task.id);
      DateTime baseDeadline = utcSelectedDeadline ??
          calculateDeadlineFromFlexible(flexibleDeadline!)?.toUtc() ??
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
            ).toUtc(), // Ensure UTC
            repeatInterval: repeatInterval ?? _tasks[taskIndex].repeatInterval,
            customRepeatDays: customRepeatDays,
            flexibleDeadline: flexibleDeadline,
          );
        }
      }
    } else if (option == "this_and_following") {
      // Update this and all subsequent tasks
      bool update = false;
      DateTime baseDeadline = utcSelectedDeadline ??
          calculateDeadlineFromFlexible(flexibleDeadline!)?.toUtc() ??
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
            ).toUtc(), // Ensure UTC
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
          deadline: utcSelectedDeadline ?? _tasks[index].deadline,
          flexibleDeadline: flexibleDeadline ?? _tasks[index].flexibleDeadline,
          repeatInterval: repeatInterval ?? _tasks[index].repeatInterval,
          customRepeatDays: customRepeatDays ?? _tasks[index].customRepeatDays,
        );
      }
    }

    notifyListeners();
  }

  DateTime _calculateDynamicDeadline({
    required DateTime startDate,
    required String? interval,
    required int? customDays,
    required int iteration,
  }) {
    DateTime nextOccurrence = startDate;

    for (int i = 0; i < iteration; i++) {
      nextOccurrence = calculateNextOccurrence(
        interval: interval,
        customDays: customDays,
        lastOccurrence: nextOccurrence,
      );
    }

    return nextOccurrence.toUtc(); // Ensure UTC
  }

  // Extend repeating tasks beyond the current 2-year limit
  void extendRepeatingTasks(Task task, int additionalYears) {
    // Calculate the new end date based on the additional years
    final DateTime currentLimit = task.deadline ?? DateTime.now();
    final DateTime newLimit =
        currentLimit.add(Duration(days: additionalYears * 365));

    // Regenerate tasks up to the new limit
    _taskService.generateRepeatingTasks(
      task.copyWith(deadline: task.deadline), // Use the original deadline
      task.repeatingGroupId, // Ensure repeatingGroupId is preserved
      limit: newLimit, // Pass the new limit for task generation
    );

    notifyListeners();
  }

  // Handle overdue tasks by skipping or resetting deadlines
  void handleOverdueTask(Task task, bool skipToNext) {
    if (task.isRepeating && skipToNext) {
      final DateTime nextDeadline = calculateNextOccurrence(
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

  void toggleTaskCompletion(Task task) {
    final isNowCompleted = !task.isCompleted;

    // Ensure points are valid
    final points = task.points;

    // Update task immutably
    final updatedTask = task.copyWith(isCompleted: isNowCompleted);

    // Find the index of the task in the list and replace it immutably
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
    }

    // Award or deduct points based on completion status
    if (isNowCompleted) {
      _pointsManager.awardPoints(
        points,
        'Task "${task.title}" completed',
      );
      _notificationThrottler.sendThrottledNotification(
        sendNotification: _notificationService.sendNotification,
        title: 'Hurrah!',
        body: 'You completed the task: "${task.title}"!',
      );
    } else {
      _pointsManager.deductPoints(
        points,
        'Task "${task.title}" marked as incomplete',
      );
      log('Task marked as incomplete: "${task.title}"');
    }

    notifyListeners(); // Notify listeners about the state change
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

  /// Add a sub-task to a task.
  ///
  /// If the sub-task is a research paper (`SubTaskType.paper`), it checks for duplication
  /// based on the URL before adding it to prevent duplicate entries.
  /// Logs and skips addition if a duplicate paper is found.
  ///
  /// Parameters:
  /// - [taskId]: The ID of the task to which the sub-task will be added.
  /// - [subTask]: The sub-task object to be added.
  Future<void> addSubTask(String taskId, SubTask subTask) async {
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      final task = _tasks[taskIndex];

      // Check if the subTask is a paper and already exists
      if (subTask.type == SubTaskType.paper) {
        final isDuplicate = task.subTasks.any((existingSubTask) =>
            existingSubTask.type == SubTaskType.paper &&
            existingSubTask.url == subTask.url);

        if (isDuplicate) {
          log("Subtask with URL ${subTask.url} already exists. Skipping addition.");
          return;
        }
      }

      await _taskService.addSubTask(taskId, subTask);
      notifyListeners();
    } else {
      log("Task with ID $taskId not found. Could not add subtask.");
    }
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
    // final task = _tasks.firstWhere((t) => t.id == taskId);
    // final subTask = task.subTasks.firstWhere((st) => st.id == subTaskId);
    _taskService.addSubTaskItem(taskId, subTaskId, item);
    // subTask.toggleCompletion();
    // toggleTaskCompletion(task);
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
