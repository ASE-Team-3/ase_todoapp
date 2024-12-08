import 'package:cloud_firestore/cloud_firestore.dart';

class Project {
  final String id; // Firestore Document ID
  final String name; // Project name
  final String description; // Project description
  final String createdBy; // User ID of the project owner
  final List<String> members; // List of user IDs assigned to the project
  final DateTime creationDate; // Creation date
  final DateTime updatedAt; // Last updated date

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.createdBy,
    this.members = const [], // Initialize to empty list if null
    DateTime? creationDate,
    DateTime? updatedAt,
  })  : creationDate = creationDate ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Factory to convert Firestore data into a Project object
  factory Project.fromMap(Map<String, dynamic> data, String documentId) {
    return Project(
      id: documentId,
      name: data['name'] ?? 'Unnamed Project',
      description: data['description'] ?? '',
      createdBy: data['createdBy'] ?? '',
      members: List<String>.from(data['members'] ?? []), // Safely map members to List<String>
      creationDate: (data['creationDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert Project to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'createdBy': createdBy,
      'members': members, // Save members list to Firestore
      'creationDate': Timestamp.fromDate(creationDate),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // CopyWith method to allow updates to specific fields
  Project copyWith({
    String? id,
    String? name,
    String? description,
    String? createdBy,
    List<String>? members,
    DateTime? creationDate,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      members: members ?? this.members,
      creationDate: creationDate ?? this.creationDate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
