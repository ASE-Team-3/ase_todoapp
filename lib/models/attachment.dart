// models/attachment.dart
import 'package:uuid/uuid.dart';

enum AttachmentType { file, link, image, video }

class Attachment {
  final String id;
  final String name;
  final String path; // File path or URL
  final AttachmentType type;

  Attachment({
    required this.name,
    required this.path,
    required this.type,
    String? id,
  }) : id = id ?? const Uuid().v4();
}
