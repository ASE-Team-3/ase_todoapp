// models/attachment.dart
enum AttachmentType { file, link, image, video }

class Attachment {
  final String id;
  final String name;
  final String path; // File path or URL
  final AttachmentType type;

  Attachment({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
  });
}
