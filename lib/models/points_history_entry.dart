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
}
