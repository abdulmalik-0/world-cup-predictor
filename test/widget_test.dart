import 'package:flutter_test/flutter_test.dart';
import 'package:world_cup_predictor/core/utils/scoring_logic.dart';

void main() {
  test('app scoring smoke test', () {
    expect(
      ScoringLogic.calculate(
        predictedHome: 2,
        predictedAway: 1,
        actualHome: 2,
        actualAway: 1,
        isSaudiMatch: false,
      ),
      3,
    );
  });
}
