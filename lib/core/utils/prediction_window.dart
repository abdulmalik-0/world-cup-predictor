import 'package:world_cup_predictor/core/constants/app_constants.dart';

DateTime predictionClosesAt(DateTime kickoff) =>
    kickoff.subtract(const Duration(minutes: predictionLockMinutes));

bool isPredictionOpen(DateTime kickoff) =>
    DateTime.now().isBefore(predictionClosesAt(kickoff));

Duration timeUntilPredictionCloses(DateTime kickoff) {
  final closes = predictionClosesAt(kickoff);
  final now = DateTime.now();
  if (!now.isBefore(closes)) return Duration.zero;
  return closes.difference(now);
}

String formatCountdown(Duration d) {
  if (d <= Duration.zero) return 'مغلق';
  if (d.inDays > 0) {
    return '${d.inDays}ي ${d.inHours.remainder(24)}س ${d.inMinutes.remainder(60)}د';
  }
  if (d.inHours > 0) {
    return '${d.inHours}س ${d.inMinutes.remainder(60)}د ${d.inSeconds.remainder(60)}ث';
  }
  return '${d.inMinutes}د ${d.inSeconds.remainder(60)}ث';
}

bool isSaudiTeamCode(String code) =>
    code.toUpperCase().trim() == saudiTeamCode;
