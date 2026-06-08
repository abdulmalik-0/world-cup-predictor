/// Client-side scoring mirror (authoritative scoring is on Supabase).
class ScoringLogic {
  static int calculate({
    required int predictedHome,
    required int predictedAway,
    required int actualHome,
    required int actualAway,
    required bool isSaudiMatch,
  }) {
    final multiplier = isSaudiMatch ? 2 : 1;
    var base = 0;

    if (predictedHome == actualHome && predictedAway == actualAway) {
      base = 3;
    } else if (_sameOutcome(predictedHome, predictedAway, actualHome, actualAway)) {
      base = 1;
    }

    return base * multiplier;
  }

  static bool _sameOutcome(int ph, int pa, int ah, int aa) {
    if (ph > pa && ah > aa) return true;
    if (ph < pa && ah < aa) return true;
    if (ph == pa && ah == aa) return true;
    return false;
  }

  static String pointsLabel({required bool isSaudiMatch, required bool isExact}) {
    if (isSaudiMatch) {
      return isExact ? '6 نقاط (دبل 🔥)' : '2 نقطة (دبل 🔥)';
    }
    return isExact ? '3 نقاط' : '1 نقطة';
  }
}
