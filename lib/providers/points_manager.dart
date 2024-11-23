import 'package:app/models/points_history_entry.dart';

class PointsManager {
  int _totalPoints = 0;
  final List<PointsHistoryEntry> _history = [];

  int get totalPoints => _totalPoints;

  List<PointsHistoryEntry> get history => List.unmodifiable(_history);

  void awardPoints(int points, String reason) {
    _totalPoints += points;
    _addHistoryEntry(points, true, reason);
  }

  void deductPoints(int points, String reason) {
    _totalPoints -= points;
    _addHistoryEntry(points, false, reason);
  }

  void _addHistoryEntry(int points, bool awarded, String reason) {
    _history.add(
      PointsHistoryEntry(
        timestamp: DateTime.now(),
        points: points,
        action: awarded ? 'Awarded' : 'Deducted',
        reason: reason,
      ),
    );
  }
}
