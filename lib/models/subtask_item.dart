// models/subtask_item.dart
import 'package:uuid/uuid.dart';

class SubTaskItem {
  final String id;
  final String title;
  bool isCompleted;

  SubTaskItem({
    required this.title,
    this.isCompleted = false,
    String? id,
  }) : id = id ?? const Uuid().v4();
}
