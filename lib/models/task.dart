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
  List<Attachment> attachments;
  bool isCompleted;
  List<SubTask> subTasks; // List of SubTasks

  Task({
    required this.title,
    required this.description,
    required this.deadline,
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
    List<Attachment>? attachments,
    bool? isCompleted,
    List<SubTask>? subTasks,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      creationDate: creationDate ?? this.creationDate,
      attachments: attachments ?? this.attachments,
      isCompleted: isCompleted ?? this.isCompleted,
      subTasks: subTasks ?? this.subTasks,
    );
  }
}
