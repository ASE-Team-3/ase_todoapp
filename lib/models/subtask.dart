// models/subtask.dart
import 'package:uuid/uuid.dart';
import 'package:app/models/subtask_item.dart';

class SubTask {
  final String id; // UUID
  final String title;
  final String description;
  bool isCompleted;
  List<SubTaskItem> items;

  SubTask({
    required this.title,
    required this.description,
    this.isCompleted = false,
    List<SubTaskItem>? items,
    String? id,
  })  : id = id ?? const Uuid().v4(),
        items = items ?? [];

  void toggleCompletion() {
    isCompleted = items.every((item) => item.isCompleted);
  }
}
