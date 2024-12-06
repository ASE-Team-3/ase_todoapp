import 'package:cloud_firestore/cloud_firestore.dart';

class PointsHistoryEntry {
  final DateTime timestamp;
  final int points;
  final String action; // e.g., 'Awarded' or 'Deducted'
  final String reason; // Reason for the points change.

  PointsHistoryEntry({
    required this.timestamp,
    required this.points,
    required this.action,
    required this.reason,
  });

  // Convert Firestore data to a PointsHistoryEntry object
  factory PointsHistoryEntry.fromMap(Map<String, dynamic> data) {
    return PointsHistoryEntry(
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      points: data['points'] ?? 0,
      action: data['action'] ?? '',
      reason: data['reason'] ?? '',
    );
  }

  // Convert a PointsHistoryEntry object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'points': points,
      'action': action,
      'reason': reason,
    };
  }
}
