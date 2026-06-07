import 'package:world_cup_predictor/models/match.dart';
import 'package:world_cup_predictor/models/prediction.dart';

/// A single finished prediction, with running total for the chart.
class StatEntry {
  const StatEntry({
    required this.match,
    required this.prediction,
    required this.cumulativePoints,
  });

  final Match match;
  final Prediction prediction;
  final int cumulativePoints;

  bool get isExact =>
      match.homeScore == prediction.homeScore &&
      match.awayScore == prediction.awayScore;

  bool get isCorrectOutcome {
    final ph = prediction.homeScore, pa = prediction.awayScore;
    final ah = match.homeScore!, aa = match.awayScore!;
    return (ph > pa && ah > aa) ||
        (ph < pa && ah < aa) ||
        (ph == pa && ah == aa);
  }
}

class MyStats {
  const MyStats({
    required this.totalPoints,
    required this.predictionsMade,
    required this.exactHits,
    required this.correctOutcomes,
    required this.finishedEntries,
  });

  final int totalPoints;
  final int predictionsMade;
  final int exactHits;
  final int correctOutcomes;
  final List<StatEntry> finishedEntries; // chronological by kickoff

  int get matchesScored => finishedEntries.length;

  double get accuracy =>
      matchesScored == 0 ? 0 : correctOutcomes / matchesScored;

  double get exactRate =>
      matchesScored == 0 ? 0 : exactHits / matchesScored;

  factory MyStats.empty() => const MyStats(
        totalPoints: 0,
        predictionsMade: 0,
        exactHits: 0,
        correctOutcomes: 0,
        finishedEntries: [],
      );

  factory MyStats.fromRows(List<Map<String, dynamic>> rows) {
    final finished = <StatEntry>[];
    var total = 0;
    var exact = 0;
    var correct = 0;
    var predictionsMade = 0;

    // Build (match, prediction) pairs for finished matches, sorted by kickoff.
    final pairs = <(Match, Prediction)>[];
    for (final row in rows) {
      predictionsMade++;
      final matchJson = row['matches'];
      if (matchJson is! Map) continue;
      final match = Match.fromJson(Map<String, dynamic>.from(matchJson));
      final prediction = Prediction.fromJson(row);
      if (match.isFinished &&
          match.homeScore != null &&
          match.awayScore != null) {
        pairs.add((match, prediction));
      }
    }

    pairs.sort((a, b) => a.$1.kickoffAt.compareTo(b.$1.kickoffAt));

    var running = 0;
    for (final (match, prediction) in pairs) {
      running += prediction.pointsEarned ?? 0;
      final entry = StatEntry(
        match: match,
        prediction: prediction,
        cumulativePoints: running,
      );
      finished.add(entry);
      total += prediction.pointsEarned ?? 0;
      if (entry.isExact) exact++;
      if (entry.isCorrectOutcome) correct++;
    }

    return MyStats(
      totalPoints: total,
      predictionsMade: predictionsMade,
      exactHits: exact,
      correctOutcomes: correct,
      finishedEntries: finished,
    );
  }
}
