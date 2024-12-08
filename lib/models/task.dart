import 'package:uuid/uuid.dart';
import 'package:app/models/subtask.dart'; // Import SubTask model
import 'package:app/models/attachment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id; // UUID
  final String title;
  final String description;
  final DateTime? deadline; // Store in UTC
  final String? flexibleDeadline; // Flexible deadline
  final DateTime creationDate; // Store in UTC
  final DateTime updatedAt; // Store in UTC
  final int priority; // Priority (1: high, 2: medium, 3: low)
  final bool isRepeating;
  final String? repeatInterval;
  final int? customRepeatDays;
  final DateTime? nextOccurrence;
  final String? repeatingGroupId;
  final String? alertFrequency;
  List<Attachment> attachments;
  bool isCompleted;
  List<SubTask> subTasks;
  int points;
  final Map<String, dynamic>? customReminder;
  final String category;
  List<String> keywords;
  final String? suggestedPaper;
  final String? suggestedPaperUrl;
  final String? suggestedPaperAuthor;
  final String? suggestedPaperPublishDate;

  // New fields for user and project tracking
  final String createdBy; // User who created the task
  final String? assignedBy; // User who assigned the task
  final String? assignedTo; // User to whom the task is assigned
  final String? projectId; // Linked project ID if the task is part of a project

  Task({
    required this.title,
    required this.description,
    this.deadline,
    this.flexibleDeadline,
    this.priority = 2,
    this.isRepeating = false,
    this.repeatInterval,
    this.customRepeatDays,
    this.nextOccurrence,
    this.repeatingGroupId,
    this.alertFrequency = "once",
    DateTime? creationDate,
    DateTime? updatedAt,
    String? id,
    this.isCompleted = false,
    List<Attachment>? attachments,
    List<SubTask>? subTasks,
    this.points = 0,
    this.customReminder,
    this.category = "General",
    List<String>? keywords,
    this.suggestedPaper,
    this.suggestedPaperUrl,
    this.suggestedPaperAuthor,
    this.suggestedPaperPublishDate,
    required this.createdBy,
    this.assignedBy,
    this.assignedTo,
    this.projectId, // Added projectId
  })  : id = id ?? const Uuid().v4(),
        creationDate = creationDate?.toUtc() ?? DateTime.now().toUtc(),
        updatedAt = updatedAt?.toUtc() ?? DateTime.now().toUtc(),
        attachments = attachments ?? [],
        subTasks = subTasks ?? [],
        keywords = keywords ?? [];

  // Firestore data to Task object
  factory Task.fromMap(Map<String, dynamic> data, String documentId) {
    return Task(
      id: documentId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      deadline: (data['deadline'] as Timestamp?)?.toDate(),
      flexibleDeadline: data['flexibleDeadline'],
      creationDate: (data['creationDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      priority: data['priority'] ?? 2,
      isRepeating: data['isRepeating'] ?? false,
      repeatInterval: data['repeatInterval'],
      customRepeatDays: data['customRepeatDays'],
      nextOccurrence: (data['nextOccurrence'] as Timestamp?)?.toDate(),
      repeatingGroupId: data['repeatingGroupId'],
      alertFrequency: data['alertFrequency'] ?? 'once',
      attachments: (data['attachments'] as List?)
          ?.map((item) => Attachment.fromMap(item))
          .toList() ??
          [],
      isCompleted: data['isCompleted'] ?? false,
      subTasks: (data['subTasks'] as List?)
          ?.map((item) => SubTask.fromMap(item))
          .toList() ??
          [],
      points: int.tryParse(data['points']?.toString() ?? '0') ?? 0,
      customReminder: data['customReminder'],
      category: data['category'] ?? 'General',
      keywords: List<String>.from(data['keywords'] ?? []),
      suggestedPaper: data['suggestedPaper'],
      suggestedPaperUrl: data['suggestedPaperUrl'],
      suggestedPaperAuthor: data['suggestedPaperAuthor'],
      suggestedPaperPublishDate: data['suggestedPaperPublishDate'],
      createdBy: data['createdBy'] ?? '',
      assignedBy: data['assignedBy'],
      assignedTo: data['assignedTo'],
      projectId: data['projectId'], // Map projectId
    );
  }

  // Task object to Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'flexibleDeadline': flexibleDeadline,
      'creationDate': Timestamp.fromDate(creationDate),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'priority': priority,
      'isRepeating': isRepeating,
      'repeatInterval': repeatInterval,
      'customRepeatDays': customRepeatDays,
      'nextOccurrence': nextOccurrence != null ? Timestamp.fromDate(nextOccurrence!) : null,
      'repeatingGroupId': repeatingGroupId,
      'alertFrequency': alertFrequency,
      'attachments': attachments.map((e) => e.toMap()).toList(),
      'isCompleted': isCompleted,
      'subTasks': subTasks.map((e) => e.toMap()).toList(),
      'points': points,
      'customReminder': customReminder,
      'category': category,
      'keywords': keywords,
      'suggestedPaper': suggestedPaper,
      'suggestedPaperUrl': suggestedPaperUrl,
      'suggestedPaperAuthor': suggestedPaperAuthor,
      'suggestedPaperPublishDate': suggestedPaperPublishDate,
      'createdBy': createdBy,
      'assignedBy': assignedBy,
      'assignedTo': assignedTo,
      'projectId': projectId, // Include projectId
    };
  }

  // CopyWith method to create updated copies of the Task object
  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? deadline,
    String? flexibleDeadline,
    DateTime? creationDate,
    DateTime? updatedAt,
    int? priority,
    bool? isRepeating,
    String? repeatInterval,
    int? customRepeatDays,
    DateTime? nextOccurrence,
    String? repeatingGroupId,
    String? alertFrequency,
    List<Attachment>? attachments,
    bool? isCompleted,
    List<SubTask>? subTasks,
    int? points,
    Map<String, dynamic>? customReminder,
    String? category,
    List<String>? keywords,
    String? suggestedPaper,
    String? suggestedPaperUrl,
    String? suggestedPaperAuthor,
    String? suggestedPaperPublishDate,
    String? createdBy,
    String? assignedBy,
    String? assignedTo,
    String? projectId, // New field for Project ID
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      flexibleDeadline: flexibleDeadline ?? this.flexibleDeadline,
      creationDate: creationDate ?? this.creationDate,
      updatedAt: updatedAt ?? DateTime.now().toUtc(),
      priority: priority ?? this.priority,
      isRepeating: isRepeating ?? this.isRepeating,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      customRepeatDays: customRepeatDays ?? this.customRepeatDays,
      nextOccurrence: nextOccurrence ?? this.nextOccurrence,
      repeatingGroupId: repeatingGroupId ?? this.repeatingGroupId,
      alertFrequency: alertFrequency ?? this.alertFrequency,
      attachments: attachments ?? this.attachments,
      isCompleted: isCompleted ?? this.isCompleted,
      subTasks: subTasks ?? this.subTasks,
      points: points ?? this.points,
      customReminder: customReminder ?? this.customReminder,
      category: category ?? this.category,
      keywords: keywords ?? this.keywords,
      suggestedPaper: suggestedPaper ?? this.suggestedPaper,
      suggestedPaperUrl: suggestedPaperUrl ?? this.suggestedPaperUrl,
      suggestedPaperAuthor: suggestedPaperAuthor ?? this.suggestedPaperAuthor,
      suggestedPaperPublishDate: suggestedPaperPublishDate ?? this.suggestedPaperPublishDate,
      createdBy: createdBy ?? this.createdBy,
      assignedBy: assignedBy ?? this.assignedBy,
      assignedTo: assignedTo ?? this.assignedTo,
      projectId: projectId ?? this.projectId, // Copy projectId
    );
  }
}
