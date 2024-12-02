import 'package:uuid/uuid.dart';
import 'package:app/models/subtask.dart'; // Import SubTask model
import 'package:app/models/attachment.dart';

class Task {
  final String id; // UUID
  final String title;
  final String description;
  final DateTime? deadline; // Store in UTC
  final String?
      flexibleDeadline; // Flexible deadline (e.g., "Today", "This Week")
  final DateTime creationDate; // Store in UTC
  final DateTime updatedAt; // Store in UTC
  final int priority; // Priority field (1 for high, 2 for medium, 3 for low)
  final bool isRepeating; // Indicates whether the task repeats
  final String?
      repeatInterval; // "daily", "weekly", "monthly", "yearly", or "custom"
  final int? customRepeatDays; // Number of days for custom intervals
  final DateTime? nextOccurrence; // Next occurrence for repeating tasks
  final String? repeatingGroupId; // Group ID for repeating tasks
  final String?
      alertFrequency; // "once", "hourly", "daily" for notification frequency
  List<Attachment> attachments;
  bool isCompleted;
  List<SubTask> subTasks; // List of SubTasks
  int points; // New points attribute
  final Map<String, dynamic>? customReminder; // New field for custom reminders
  final String category; // Category of the task (e.g., Research, Work, etc.)
  List<String> keywords; // Keywords for research tasks
  final String? suggestedPaper;
  final String? suggestedPaperUrl;
  final String? suggestedPaperAuthor; // Author(s) of the suggested paper
  final String? suggestedPaperPublishDate; // Publication date of the paper

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
    this.alertFrequency = "once", // Default alert frequency
    DateTime? creationDate,
    DateTime? updatedAt,
    String? id,
    this.isCompleted = false,
    List<Attachment>? attachments,
    List<SubTask>? subTasks,
    this.points = 0, // Initialize points to 0
    this.customReminder,
    this.category = "General", // Default category
    List<String>? keywords, // Initialize keywords
    this.suggestedPaper,
    this.suggestedPaperUrl,
    this.suggestedPaperAuthor,
    this.suggestedPaperPublishDate,
  })  : id = id ?? const Uuid().v4(),
        creationDate = creationDate?.toUtc() ?? DateTime.now().toUtc(),
        updatedAt = updatedAt?.toUtc() ?? DateTime.now().toUtc(),
        attachments = attachments ?? [],
        subTasks = subTasks ?? [],
        keywords = keywords ?? []; // Initialize empty keyword list if null

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? deadline,
    String? flexibleDeadline,
    DateTime? creationDate,
    DateTime? updatedAt, // Include updatedAt in copyWith
    int? priority, // Include priority in copyWith
    bool? isRepeating, // Include isRepeating in copyWith
    String? repeatInterval, // Include repeatInterval in copyWith
    int? customRepeatDays, // Include customRepeatDays in copyWith
    DateTime? nextOccurrence, // Include nextOccurrence in copyWith
    String? repeatingGroupId, // Include repeatingGroupId in copyWith
    String? alertFrequency, // Include alertFrequency in copyWith
    List<Attachment>? attachments,
    bool? isCompleted,
    List<SubTask>? subTasks,
    int? points, // Add points in copyWith
    Map<String, dynamic>? customReminder,
    String? category, // Include category in copyWith
    List<String>? keywords, // Include keywords in copyWith
    String? suggestedPaper,
    String? suggestedPaperUrl,
    String? suggestedPaperAuthor,
    String? suggestedPaperPublishDate,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline?.toUtc() ?? this.deadline?.toUtc(),
      flexibleDeadline: flexibleDeadline ?? this.flexibleDeadline,
      creationDate: creationDate?.toUtc() ?? this.creationDate,
      updatedAt: updatedAt?.toUtc() ?? DateTime.now().toUtc(),
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
      alertFrequency:
          alertFrequency ?? this.alertFrequency, // Update alertFrequency
      attachments: attachments ?? this.attachments,
      isCompleted: isCompleted ?? this.isCompleted,
      subTasks: subTasks ?? this.subTasks,
      points: points ?? this.points, // Update points
      customReminder: customReminder ?? this.customReminder,
      category: category ?? this.category, // Update category
      keywords: keywords ?? this.keywords, // Update keywords
      suggestedPaper: suggestedPaper ?? this.suggestedPaper,
      suggestedPaperUrl: suggestedPaperUrl ?? this.suggestedPaperUrl,
      suggestedPaperAuthor: suggestedPaperAuthor ?? this.suggestedPaperAuthor,
      suggestedPaperPublishDate:
          suggestedPaperPublishDate ?? this.suggestedPaperPublishDate,
    );
  }
}
