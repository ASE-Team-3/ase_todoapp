import 'package:uuid/uuid.dart';
import 'package:app/models/subtask.dart'; // Import SubTask model
import 'package:app/models/attachment.dart';

class Task {
  final String id; // UUID
  final String title;
  final String description;
  final DateTime? deadline; // Specific deadline
  final String?
      flexibleDeadline; // Flexible deadline (e.g., "Today", "This Week")
  final DateTime creationDate;
  final int priority; // Priority field (1 for high, 2 for medium, 3 for low)
  final bool isRepeating; // Indicates whether the task repeats
  final String?
      repeatInterval; // "daily", "weekly", "monthly", "yearly", or "custom"
  final int? customRepeatDays; // Number of days for custom intervals
  final DateTime? nextOccurrence; // Next occurrence for repeating tasks
  final String? repeatingGroupId; // Group ID for repeating tasks
  List<Attachment> attachments;
  bool isCompleted;
  List<SubTask> subTasks; // List of SubTasks
  int points; // New points attribute

  Task({
    required this.title,
    required this.description,
    this.deadline, // Retain the deadline field
    this.flexibleDeadline,
    this.priority = 2, // Default priority (medium)
    this.isRepeating = false, // Default: not a repeating task
    this.repeatInterval,
    this.customRepeatDays,
    this.nextOccurrence,
    this.repeatingGroupId, // Default null for non-repeating tasks
    DateTime? creationDate,
    String? id,
    this.isCompleted = false,
    List<Attachment>? attachments,
    List<SubTask>? subTasks,
    this.points = 0, // Initialize points to 0
  })  : id = id ?? const Uuid().v4(),
        creationDate = creationDate ?? DateTime.now(),
        attachments = attachments ?? [],
        subTasks = subTasks ?? [];

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? deadline,
    String? flexibleDeadline,
    DateTime? creationDate,
    int? priority, // Include priority in copyWith
    bool? isRepeating, // Include isRepeating in copyWith
    String? repeatInterval, // Include repeatInterval in copyWith
    int? customRepeatDays, // Include customRepeatDays in copyWith
    DateTime? nextOccurrence, // Include nextOccurrence in copyWith
    String? repeatingGroupId, // Include repeatingGroupId in copyWith
    List<Attachment>? attachments,
    bool? isCompleted,
    List<SubTask>? subTasks,
    int? points, // Add points in copyWith
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline, // Retain the deadline parameter
      flexibleDeadline: flexibleDeadline ?? this.flexibleDeadline,
      creationDate: creationDate ?? this.creationDate,
      priority: priority ?? this.priority, // Set the new priority field
      isRepeating: isRepeating ?? this.isRepeating, // Update isRepeating field
      repeatInterval:
          repeatInterval ?? this.repeatInterval, // Update repeatInterval
      customRepeatDays:
          customRepeatDays ?? this.customRepeatDays, // Update customRepeatDays
      nextOccurrence:
          nextOccurrence ?? this.nextOccurrence, // Update nextOccurrence
      repeatingGroupId:
          repeatingGroupId ?? this.repeatingGroupId, // Update repeatingGroupId
      attachments: attachments ?? this.attachments,
      isCompleted: isCompleted ?? this.isCompleted,
      subTasks: subTasks ?? this.subTasks,
      points: points ?? this.points, // Update points
    );
  }
}
