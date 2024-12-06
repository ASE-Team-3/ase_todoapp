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
  final PointsManager _pointsManager = PointsManager(); // PointsManager instance
  final NotificationThrottler _notificationThrottler = NotificationThrottler();
  final TaskFirestoreService _taskService = TaskFirestoreService(); // Firestore service

  TaskProvider(FlutterLocalNotificationsPlugin plugin, {required ResearchService researchService})
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
      );
    }).toList();
  };

  /// Loads tasks from Firestore and updates the local task list.
  void loadTasks() {
    log('Loading tasks from Firestore...');
    _taskService.getTasks().listen((tasksFromFirestore) {
      _tasks.clear();
      _tasks.addAll(tasksFromFirestore);  // Add the fetched tasks to the list
      notifyListeners();  // Notify listeners to update the UI
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

    task = task.copyWith(deadline: task.deadline?.toUtc());

    if (task.flexibleDeadline != null && task.deadline == null) {
      final localDeadline = calculateDeadlineFromFlexible(task.flexibleDeadline!);
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
      _generateRepeatingTasks(taskWithGroupId, repeatingGroupId);
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
    if (task.keywords.isEmpty) {
      final generatedKeywords = KeywordGenerator.generate(task.title, task.description);
      task = task.copyWith(keywords: generatedKeywords);
      log('Keywords generated for research task: ${task.title}');
    }

    try {
      final relatedPapers = await _researchService.fetchRelatedResearch(task.keywords);
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

  /// Generates repeating tasks based on the task's repetition group ID.
  void _generateRepeatingTasks(Task task, String groupId) {
    log('Generating repeating tasks for: ${task.title}');
    DateTime? nextOccurrence = task.deadline ?? task.nextOccurrence;
    while (nextOccurrence != null && nextOccurrence.isBefore(DateTime.now().add(Duration(days: 730)))) {
      final newTask = task.copyWith(
        id: const Uuid().v4(),
        isCompleted: false,
        deadline: nextOccurrence,
        repeatingGroupId: groupId,
        nextOccurrence: null,
      );

      _tasks.add(newTask);
      log('New repeating task generated: ${newTask.title}');
      nextOccurrence = _calculateNextOccurrence(task.repeatInterval, task.customRepeatDays, nextOccurrence);
    }
    log('Completed repeating tasks generation for: ${task.title}');
  }

  /// Calculates the next occurrence based on the repeat interval and custom days.
  DateTime _calculateNextOccurrence(String? interval, int? customDays, DateTime lastOccurrence) {
    switch (interval) {
      case "daily":
        return lastOccurrence.add(Duration(days: 1));
      case "weekly":
        return lastOccurrence.add(Duration(days: 7));
      case "monthly":
        return DateTime(lastOccurrence.year, lastOccurrence.month + 1, lastOccurrence.day);
      case "yearly":
        return DateTime(lastOccurrence.year + 1, lastOccurrence.month, lastOccurrence.day);
      case "custom":
        return lastOccurrence.add(Duration(days: customDays ?? 0));
      default:
        throw Exception("Invalid repeat interval");
    }
  }

  /// Prepares and updates repeating tasks when there's a change in the task.
  Future<Task> _prepareRepeatingTaskForUpdate({
    required Task task,
    required String title,
    required String description,
    required String category,
    List<String>? keywords,
  }) async {
    log('Preparing repeating task for update: ${task.title}');
    final newKeywords = keywords ?? KeywordGenerator.generate(title, description);

    task = task.copyWith(
      category: category,
      keywords: newKeywords,
    );

    try {
      final relatedPapers = await _researchService.fetchRelatedResearch(newKeywords);
      if (relatedPapers.isNotEmpty) {
        task = task.copyWith(
          suggestedPaper: relatedPapers[0]['title'],
          suggestedPaperUrl: relatedPapers[0]['url'],
        );
        log('Updated research papers for task: ${task.title}');
      } else {
        task = task.copyWith(suggestedPaper: null, suggestedPaperUrl: null);
      }
    } catch (e) {
      log("Error fetching research papers: $e");
      task = task.copyWith(suggestedPaper: null, suggestedPaperUrl: null);
    }

    return task;
  }

  /// Updates a task and regenerates repeating tasks if necessary.
  Future<void> updateTask(
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
        String? category,
        List<String>? keywords,
        String? alertFrequency,
        Map<String, dynamic>? customReminder,
        String? suggestedPaper,
        String? suggestedPaperAuthor,
        String? suggestedPaperPublishDate,
        String? suggestedPaperUrl,
      }) async {
    log('Updating task: ${task.title}');
    final DateTime? calculatedDeadline = selectedDeadline?.toUtc() ?? calculateFlexibleDeadline(flexibleDeadline);

    if (category != null && category == "Research") {
      task = await _prepareRepeatingTaskForUpdate(
        task: task,
        title: title,
        description: description,
        category: category,
        keywords: keywords,
      );
    }

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
      suggestedPaperPublishDate: suggestedPaperPublishDate ?? task.suggestedPaperPublishDate,
      suggestedPaperUrl: suggestedPaperUrl ?? task.suggestedPaperUrl,
      updatedAt: DateTime.now().toUtc(),
    );

    await _taskService.updateTask(updatedTask);
    log('Task updated in Firestore: ${task.title}');

    if (updatedTask.isRepeating) {
      _generateRepeatingTasks(updatedTask, updatedTask.repeatingGroupId!);
    }

    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      notifyListeners();
      log('Task updated in local list: ${task.title}');
    } else {
      log('Task with ID ${task.id} not found for update.');
    }
  }
}
