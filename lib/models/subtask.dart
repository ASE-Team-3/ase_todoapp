import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'subtask_item.dart';  // Ensure you have the correct import for SubTaskItem

// Enum to represent subtask status
enum SubtaskStatus { pending, inProgress, completed }

class SubTask {
  final String id; // Unique identifier for each subtask
  final String title; // Title of the subtask
  final String description; // Description of the subtask
  final SubtaskStatus status; // Status of the subtask (pending, inProgress, completed)
  final DateTime creationDate; // Date the subtask was created (stored in UTC)
  final DateTime updatedAt; // Date the subtask was last updated (stored in UTC)
  final String? author; // Optional field for the author of the subtask (if applicable)
  final DateTime? publishDate; // Optional field for the publish date of the subtask (if applicable)
  final String? url; // Optional URL related to the subtask (if applicable)
  final List<SubTaskItem> items; // List of SubTaskItems (tasks associated with the subtask)

  // Constructor for creating a SubTask object
  SubTask({
    required this.title,
    required this.description,
    this.status = SubtaskStatus.pending, // Default status is pending
    this.author,
    this.publishDate,
    this.url,
    DateTime? creationDate,
    DateTime? updatedAt,
    String? id,
    List<SubTaskItem>? items, // Add the list of SubTaskItems
  })  : id = id ?? const Uuid().v4(),
        creationDate = creationDate?.toUtc() ?? DateTime.now().toUtc(),
        updatedAt = updatedAt?.toUtc() ?? DateTime.now().toUtc(),
        items = items ?? [];  // Initialize with an empty list if null

  // Convert Firestore document data to a Subtask object
  factory SubTask.fromMap(Map<String, dynamic> data) {
    return SubTask(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: _subtaskStatusFromString(data['status'] ?? 'pending'),
      creationDate: (data['creationDate'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      author: data['author'],  // Optional author field
      publishDate: data['publishDate'] != null
          ? (data['publishDate'] as Timestamp).toDate()
          : null,
      url: data['url'],  // Optional URL field
      items: (data['items'] as List<dynamic>?)?.map((item) => SubTaskItem.fromMap(item)).toList() ?? [],  // Convert items to SubTaskItem list if they exist
    );
  }

  // Convert a Subtask object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': _subtaskStatusToString(status),
      'creationDate': Timestamp.fromDate(creationDate),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'author': author,
      'publishDate': publishDate != null ? Timestamp.fromDate(publishDate!) : null,
      'url': url,
      'items': items.map((item) => item.toMap()).toList(),  // Map SubTaskItem objects to Map
    };
  }

  // Helper method to convert SubtaskStatus enum to string
  String _subtaskStatusToString(SubtaskStatus status) {
    return status.toString().split('.').last;
  }

  // Helper method to convert string to SubtaskStatus enum
  static SubtaskStatus _subtaskStatusFromString(String status) {
    return SubtaskStatus.values.firstWhere(
          (e) => e.toString().split('.').last == status,
      orElse: () => SubtaskStatus.pending, // Default to 'pending' if status is not found
    );
  }
}
