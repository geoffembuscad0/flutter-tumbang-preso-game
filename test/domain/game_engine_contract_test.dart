import 'package:flutter_test/flutter_test.dart';
import 'package:game_tumbang_preso/domain/domain.dart';

import '../support/scripted_random_source.dart';

final _players = Players.fromSetup(
  firstName: 'Ana',
  firstChoice: PlayerId.one,
  secondName: 'Ben',
);

GameEngine _engineAt({
  GamePhase phase = GamePhase.awaitingThrow,
  Scores scores = const Scores(),
  PlayerId attacker = PlayerId.one,
  int attempts = 3,
  GameConfig config = const GameConfig(),
  ScriptedRandomSource? random,
}) {
  return GameEngine(
    players: _players,
    config: config,
    random: random ?? ScriptedRandomSource(),
    initialState: GameState(
      players: _players,
      phase: phase,
      scores: scores,
      attacker: attacker,
      captureAttemptsLeft: attempts,
    ),
  );
}

void main() {
  group('GameEngine event contracts', () {
    test('a successful catch produces events in the correct order', () {
      final engine = _engineAt(
        phase: GamePhase.awaitingHitResponse,
        scores: const Scores(4, 0),
        attempts: 1,
        config: const GameConfig(catchPoints: 5),
        random: ScriptedRandomSource(rolls: [true]),
      );

      final events = engine.respondToHit(HitResponse.catchPlayer);

      expect(events, hasLength(5));
      expect(events[0], isA<HitResponded>());
      expect(events[1], isA<CatchAttempted>());
      expect(events[2], isA<PointsAwarded>());
      expect(events[3], isA<RolesSwapped>());
      expect(events[4], isA<CanRestored>());

      expect(engine.state.scores, const Scores(4, 5));
      expect(engine.state.attacker, PlayerId.two);
    });

    test('a failed catch restores the can without swapping roles', () {
      final engine = _engineAt(
        phase: GamePhase.awaitingHitResponse,
        scores: const Scores(1, 0),
        attempts: 2,
        random: ScriptedRandomSource(rolls: [false]),
      );

      final events = engine.respondToHit(HitResponse.catchPlayer);

      expect(events, hasLength(3));
      expect(events[0], isA<HitResponded>());
      expect(events[1], isA<CatchAttempted>());
      expect(events[2], isA<CanRestored>());

      expect(engine.state.attacker, PlayerId.one);
      expect(engine.state.captureAttemptsLeft, 2);
      expect(engine.state.scores, const Scores(1, 0));
      expect(engine.state.canIsDown, isFalse);
    });

    test('a successful catch resets attempts to the configured allowance', () {
      final engine = _engineAt(
        phase: GamePhase.awaitingHitResponse,
        attempts: 0,
        config: const GameConfig(
          catchChance: 1,
          captureAttemptsPerStint: 2,
          catchPoints: 3,
        ),
        random: ScriptedRandomSource(rolls: [true]),
      );

      engine.respondToHit(HitResponse.catchPlayer);

      expect(engine.state.attacker, PlayerId.two);
      expect(engine.state.captureAttemptsLeft, 2);
      expect(engine.state.scores.two, 3);
    });

    test('a miss with no capture attempts emits events in order', () {
      final engine = _engineAt(
        attempts: 0,
        random: ScriptedRandomSource(rolls: [false]),
      );

      final events = engine.throwSlipper();

      expect(events, hasLength(2));
//      expect(events[0,], isA<ThrowResolved>());
      expect(events[0], isA<ThrowResolved>());
      expect(events[1], isA<CaptureUnavailable>());

      expect(engine.state.phase, GamePhase.awaitingThrow);
      expect(engine.state.captureAttemptsLeft, 0);
    });

    test('allowing the next throw does not request randomness', () {
      final random = ScriptedRandomSource();

      final engine = _engineAt(
        phase: GamePhase.awaitingMissResponse,
        random: random,
      );

      engine.respondToMiss(MissResponse.allowNextThrow);

      expect(random.requestedChances, isEmpty);
      expect(random.rollsLeft, 0);
      expect(engine.state.captureAttemptsLeft, 3);
    });

    test('an invalid command does not consume a scripted random roll', () {
      final random = ScriptedRandomSource(rolls: [true]);

      final engine = _engineAt(
        phase: GamePhase.awaitingThrow,
        random: random,
      );

      final before = engine.state;

      expect(
        () => engine.respondToMiss(MissResponse.attemptCapture),
        throwsA(isA<InvalidGameActionException>()),
      );

      expect(identical(engine.state, before), isTrue);
      expect(random.rollsLeft, 1);
      expect(random.requestedChances, isEmpty);
    });

    test('a second coin toss is rejected without changing the result', () {
      final engine = GameEngine(
        players: _players,
        random: ScriptedRandomSource(coins: [CoinSide.heads]),
      );

      engine.callCoinToss(CoinSide.heads);

      final before = engine.state;

      expect(
        () => engine.callCoinToss(CoinSide.tails),
        throwsA(isA<InvalidGameActionException>()),
      );

      expect(identical(engine.state, before), isTrue);
      expect(engine.state.coinCall, CoinSide.heads);
      expect(engine.state.coinResult, CoinSide.heads);
    });
  });
}