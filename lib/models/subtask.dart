import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'subtask_item.dart';

// Enum to represent subtask types
enum SubTaskType { paper, common, other }

// Enum to represent subtask statuses
enum SubtaskStatus { pending, inProgress, completed }

class SubTask {
  final String id; // Unique identifier for each subtask
  final String title; // Title of the subtask
  final String description; // Description of the subtask
  final SubTaskType type; // Type of the subtask (paper, common, other)
  final SubtaskStatus status; // Status of the subtask
  final DateTime creationDate; // Creation timestamp
  final DateTime updatedAt; // Last updated timestamp
  final String? author; // Optional field for author (used for paper type)
  final DateTime? publishDate; // Optional publish date (for paper type)
  final String? url; // Optional URL (for paper type)
  bool isCompleted; // Completion flag
  List<SubTaskItem> items; // Subtask items list

  // Constructor
  SubTask({
    required this.title,
    required this.description,
    this.type = SubTaskType.common, // Default type
    this.status = SubtaskStatus.pending, // Default status
    this.author,
    this.publishDate,
    this.url,
    this.isCompleted = false,
    List<SubTaskItem>? items,
    DateTime? creationDate,
    DateTime? updatedAt,
    String? id,
  })  : id = id ?? const Uuid().v4(),
        creationDate = creationDate?.toUtc() ?? DateTime.now().toUtc(),
        updatedAt = updatedAt?.toUtc() ?? DateTime.now().toUtc(),
        items = items ?? [];

  // Convert Firestore document data to a Subtask object
  factory SubTask.fromMap(Map<String, dynamic> data) {
    return SubTask(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: _subTaskTypeFromString(data['type'] ?? 'common'),
      status: _subtaskStatusFromString(data['status'] ?? 'pending'),
      creationDate: (data['creationDate'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      author: data['author'],
      publishDate: data['publishDate'] != null
          ? (data['publishDate'] as Timestamp).toDate()
          : null,
      url: data['url'],
      isCompleted: data['isCompleted'] ?? false,
      items: (data['items'] as List<dynamic>?)
              ?.map((item) => SubTaskItem.fromMap(item))
              .toList() ??
          [],
    );
  }

  // Convert a Subtask object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': _subTaskTypeToString(type),
      'status': _subtaskStatusToString(status),
      'creationDate': Timestamp.fromDate(creationDate),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'author': author,
      'publishDate':
          publishDate != null ? Timestamp.fromDate(publishDate!) : null,
      'url': url,
      'isCompleted': isCompleted,
      'items': items.map((item) => item.toMap()).toList(),
    };
  }

  // Helper method to toggle completion status based on all items
  void toggleCompletion() {
    isCompleted = items.every((item) => item.isCompleted);
  }

  // Create a copy of SubTask with updated fields
  SubTask copyWith({
    String? title,
    String? description,
    SubTaskType? type,
    SubtaskStatus? status,
    String? author,
    DateTime? publishDate,
    String? url,
    bool? isCompleted,
    List<SubTaskItem>? items,
    DateTime? creationDate,
    DateTime? updatedAt,
    String? id,
  }) {
    return SubTask(
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      author: author ?? this.author,
      publishDate: publishDate ?? this.publishDate,
      url: url ?? this.url,
      isCompleted: isCompleted ?? this.isCompleted,
      items: items ?? this.items,
      creationDate: creationDate ?? this.creationDate,
      updatedAt: updatedAt ?? this.updatedAt,
      id: id ?? this.id,
    );
  }

  // Helper: Convert SubTaskType enum to String
  String _subTaskTypeToString(SubTaskType type) {
    return type.toString().split('.').last;
  }

  // Helper: Convert String to SubTaskType enum
  static SubTaskType _subTaskTypeFromString(String type) {
    return SubTaskType.values.firstWhere(
      (e) => e.toString().split('.').last == type,
      orElse: () => SubTaskType.common,
    );
  }

  // Helper: Convert SubtaskStatus enum to String
  String _subtaskStatusToString(SubtaskStatus status) {
    return status.toString().split('.').last;
  }

  // Helper: Convert String to SubtaskStatus enum
  static SubtaskStatus _subtaskStatusFromString(String status) {
    return SubtaskStatus.values.firstWhere(
      (e) => e.toString().split('.').last == status,
      orElse: () => SubtaskStatus.pending,
    );
  }
}
