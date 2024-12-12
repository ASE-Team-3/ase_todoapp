import 'package:cloud_firestore/cloud_firestore.dart';

class PointsHistory {
  final String id;
  final String taskId;
  final int points;
  final String reason;
  final DateTime timestamp;
  final String action; // New field: 'Awarded' or 'Deducted'

  PointsHistory({
    required this.id,
    required this.taskId,
    required this.points,
    required this.reason,
    required this.timestamp,
    required this.action, // Include 'action' field
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'points': points,
      'reason': reason,
      'timestamp': timestamp.toIso8601String(),
      'action': action, // Include 'action' in the map
    };
  }

  factory PointsHistory.fromMap(Map<String, dynamic> map) {
    return PointsHistory(
      id: map['id'] ?? 'unknown_id', // Default if null
      taskId: map['taskId'] ?? 'unknown_task', // Default if null
      points:
          (map['points'] as num?)?.toInt() ?? 0, // Safely handle int or null
      reason: map['reason'] ?? 'No reason provided', // Default if null
      timestamp: _parseTimestamp(map['timestamp']), // Handle Timestamp
      action: map['action'] ?? 'Unknown', // Default if null
    );
  }

  /// Handles Firestore Timestamp and String parsing
  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate(); // Convert Firestore Timestamp to DateTime
    } else if (value is String) {
      try {
        return DateTime.parse(value); // Parse ISO8601 String
      } catch (e) {
        print("Error parsing date string: $e");
        return DateTime.now(); // Fallback to current time
      }
    } else {
      print("Unknown timestamp format: $value");
      return DateTime.now(); // Fallback to current time
    }
  }
}
