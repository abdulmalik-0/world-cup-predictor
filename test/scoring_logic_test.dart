import 'package:flutter_test/flutter_test.dart';
import 'package:world_cup_predictor/core/utils/scoring_logic.dart';

void main() {
  group('ScoringLogic', () {
    test('exact score regular match = 3', () {
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

    test('correct winner regular match = 1', () {
      expect(
        ScoringLogic.calculate(
          predictedHome: 1,
          predictedAway: 0,
          actualHome: 3,
          actualAway: 1,
          isSaudiMatch: false,
        ),
        1,
      );
    });

    test('wrong prediction = 0', () {
      expect(
        ScoringLogic.calculate(
          predictedHome: 2,
          predictedAway: 0,
          actualHome: 0,
          actualAway: 1,
          isSaudiMatch: false,
        ),
        0,
      );
    });

    test('exact score saudi match = 6', () {
      expect(
        ScoringLogic.calculate(
          predictedHome: 2,
          predictedAway: 1,
          actualHome: 2,
          actualAway: 1,
          isSaudiMatch: true,
        ),
        6,
      );
    });

    test('correct winner saudi match = 2', () {
      expect(
        ScoringLogic.calculate(
          predictedHome: 1,
          predictedAway: 1,
          actualHome: 0,
          actualAway: 0,
          isSaudiMatch: true,
        ),
        2,
      );
    });
  });
}
