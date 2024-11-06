// models/task.dart
import 'package:uuid/uuid.dart';
import 'package:app/models/subtask.dart'; // Import SubTask model
import 'package:app/models/attachment.dart';

class Task {
  final String id; // UUID
  final String title;
  final String description;
  final DateTime deadline; // Keep the original deadline property
  final DateTime creationDate;
  final int
      priority; // New priority field (1 for high, 2 for medium, 3 for low)
  List<Attachment> attachments;
  bool isCompleted;
  List<SubTask> subTasks; // List of SubTasks

  Task({
    required this.title,
    required this.description,
    required this.deadline, // Retain the deadline field
    this.priority = 2, // Default priority (medium)
    DateTime? creationDate,
    String? id, // Nullable parameter for UUID
    this.isCompleted = false,
    List<Attachment>? attachments,
    List<SubTask>? subTasks, // Optional list of sub-tasks
  })  : id = id ?? const Uuid().v4(), // Generate a new UUID if none is provided
        creationDate = creationDate ?? DateTime.now(),
        attachments = attachments ?? [],
        subTasks = subTasks ?? []; // Initialize sub-tasks list

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? deadline,
    DateTime? creationDate,
    int? priority, // Include priority in copyWith
    List<Attachment>? attachments,
    bool? isCompleted,
    List<SubTask>? subTasks,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline, // Retain the deadline parameter
      creationDate: creationDate ?? this.creationDate,
      priority: priority ?? this.priority, // Set the new priority field
      attachments: attachments ?? this.attachments,
      isCompleted: isCompleted ?? this.isCompleted,
      subTasks: subTasks ?? this.subTasks,
    );
  }
}
