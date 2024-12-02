// models/subtask.dart
import 'package:uuid/uuid.dart';
import 'package:app/models/subtask_item.dart';

enum SubTaskType { paper, common, other }

class SubTask {
  final String id;
  final String title;
  final String description;
  final SubTaskType type; // New field to differentiate task types
  final String? author; // Author for paper tasks
  final String? publishDate; // Publish Date for paper tasks
  final String? url; // URL for paper tasks
  bool isCompleted;
  List<SubTaskItem> items;

  SubTask({
    required this.title,
    required this.description,
    this.type = SubTaskType.common,
    this.author,
    this.publishDate,
    this.url,
    this.isCompleted = false,
    List<SubTaskItem>? items,
    String? id,
  })  : id = id ?? const Uuid().v4(),
        items = items ?? [];

  void toggleCompletion() {
    isCompleted = items.every((item) => item.isCompleted);
  }

  SubTask copyWith({
    String? title,
    String? description,
    SubTaskType? type,
    String? author,
    String? publishDate,
    String? url,
    bool? isCompleted,
    List<SubTaskItem>? items,
    String? id,
  }) {
    return SubTask(
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      author: author ?? this.author,
      publishDate: publishDate ?? this.publishDate,
      url: url ?? this.url,
      isCompleted: isCompleted ?? this.isCompleted,
      items: items ?? this.items,
      id: id ?? this.id,
    );
  }
}
