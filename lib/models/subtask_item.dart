import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class SubTaskItem {
  final String id;
  final String title;
  bool isCompleted;

  SubTaskItem({
    required this.title,
    this.isCompleted = false,
    String? id,
  }) : id = id ?? const Uuid().v4();

  // Convert Firestore data to a SubTaskItem object
  factory SubTaskItem.fromMap(Map<String, dynamic> data) {
    return SubTaskItem(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  // Convert SubTaskItem to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
    };
  }
}
