// models/task.dart
import 'package:uuid/uuid.dart';
import 'package:app/models/subtask.dart'; // Import SubTask model
import 'package:app/models/attachment.dart';

class Task {
  final String id; // UUID
  final String title;
  final String description;
  final DateTime deadline;
  final DateTime creationDate;
  final int
      priority; // New priority field (1 for high, 2 for medium, 3 for low)
  List<Attachment> attachments;
  bool isCompleted;
  List<SubTask> subTasks; // List of SubTasks
  int points; // New points attribute

  Task({
    required this.title,
    required this.description,
    required this.deadline,
    this.priority = 2,
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
    DateTime? creationDate,
    int? priority,
    List<Attachment>? attachments,
    bool? isCompleted,
    List<SubTask>? subTasks,
    int? points, // Add points in copyWith
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      creationDate: creationDate ?? this.creationDate,
      priority: priority ?? this.priority,
      attachments: attachments ?? this.attachments,
      isCompleted: isCompleted ?? this.isCompleted,
      subTasks: subTasks ?? this.subTasks,
      points: points ?? this.points, // Update points
    );
  }
}
