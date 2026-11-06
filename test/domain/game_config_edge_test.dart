import 'package:flutter_test/flutter_test.dart';
import 'package:game_tumbang_preso/domain/domain.dart';

void main() {
  group('GameConfig validation', () {
    test('accepts the default configuration', () {
      const config = GameConfig();

      expect(config.targetScore, 10);
      expect(config.hitChance, 0.5);
      expect(config.captureChance, 0.5);
      expect(config.catchChance, 0.5);
      expect(config.captureAttemptsPerStint, 3);
    });

    test('rejects a target score of zero', () {
      expect(
        () => GameConfig(targetScore: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects negative hit probability', () {
      expect(
        () => GameConfig(hitChance: -0.1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects hit probability greater than one', () {
      expect(
        () => GameConfig(hitChance: 1.1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects invalid capture probability', () {
      expect(
        () => GameConfig(captureChance: -0.1),
        throwsA(isA<AssertionError>()),
      );

      expect(
        () => GameConfig(captureChance: 1.1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects invalid catch probability', () {
      expect(
        () => GameConfig(catchChance: -0.1),
        throwsA(isA<AssertionError>()),
      );

      expect(
        () => GameConfig(catchChance: 1.1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects a negative capture-attempt allowance', () {
      expect(
        () => GameConfig(captureAttemptsPerStint: -1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('accepts probability boundaries and zero capture attempts', () {
      const config = GameConfig(
        hitChance: 0,
        captureChance: 1,
        catchChance: 0,
        captureAttemptsPerStint: 0,
      );

      expect(config.hitChance, 0);
      expect(config.captureChance, 1);
      expect(config.catchChance, 0);
      expect(config.captureAttemptsPerStint, 0);
    });
  });

  group('DartRandomSource probability boundaries', () {
    final random = DartRandomSource();

    test('a zero probability always returns false', () {
      for (var i = 0; i < 100; i++) {
        expect(random.roll(0), isFalse);
      }
    });

    test('a probability of one always returns true', () {
      for (var i = 0; i < 100; i++) {
        expect(random.roll(1), isTrue);
      }
    });
  });
}