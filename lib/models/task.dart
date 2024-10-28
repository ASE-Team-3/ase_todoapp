// models/task.dart
import 'package:uuid/uuid.dart';

class Task {
  final String id; // UUID
  final String title;
  final String description;
  final DateTime deadline;
  final DateTime creationDate;
  bool isCompleted;

  Task({
    required this.title,
    required this.description,
    required this.deadline,
    DateTime? creationDate,
    String? id, // Nullable parameter for UUID
    this.isCompleted = false,
  })  : id = id ?? const Uuid().v4(), // Generate a new UUID if none is provided
        creationDate = creationDate ?? DateTime.now();
}
