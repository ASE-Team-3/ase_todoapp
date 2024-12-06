import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Convert Firestore data to an Attachment object
  factory Attachment.fromMap(Map<String, dynamic> data) {
    return Attachment(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      path: data['path'] ?? '',
      type: _attachmentTypeFromString(data['type'] ?? 'file'),
    );
  }

  // Convert an Attachment object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'type': _attachmentTypeToString(type),
    };
  }

  // Helper method to convert AttachmentType enum to string
  String _attachmentTypeToString(AttachmentType type) {
    return type.toString().split('.').last;
  }

  // Helper method to convert string to AttachmentType enum
  static AttachmentType _attachmentTypeFromString(String type) {
    return AttachmentType.values.firstWhere(
          (e) => e.toString().split('.').last == type,
      orElse: () => AttachmentType.file, // Default to 'file' if not found
    );
  }
}
