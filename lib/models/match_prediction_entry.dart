import 'package:world_cup_predictor/models/prediction.dart';

/// A colleague's prediction for a match, with profile info for display.
class MatchPredictionEntry {
  const MatchPredictionEntry({
    required this.prediction,
    required this.fullName,
    required this.department,
  });

  final Prediction prediction;
  final String fullName;
  final String department;

  factory MatchPredictionEntry.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return MatchPredictionEntry(
      prediction: Prediction.fromJson(json),
      fullName: profile?['full_name'] as String? ?? '—',
      department: profile?['department'] as String? ?? '',
    );
  }
}
