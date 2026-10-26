import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_tumbang_preso/domain/domain.dart';

import '../support/scripted_random_source.dart';

final _players = Players.fromSetup(
  firstName: 'Ana',
  firstChoice: PlayerId.one,
  secondName: 'Ben',
);

/// Builds an engine already in the middle of a game, with scripted rolls.
/// Player 1 is the attacker unless told otherwise.
GameEngine _engineAt({
  GamePhase phase = GamePhase.awaitingThrow,
  Scores scores = const Scores(),
  PlayerId attacker = PlayerId.one,
  int attempts = 3,
  List<bool> rolls = const [],
  GameConfig config = const GameConfig(),
  ScriptedRandomSource? random,
  TieBreakerState? tieBreaker,
}) {
  return GameEngine(
    players: _players,
    config: config,
    random: random ?? ScriptedRandomSource(rolls: rolls),
    initialState: GameState(
      players: _players,
      phase: phase,
      scores: scores,
      attacker: attacker,
      captureAttemptsLeft: attempts,
      tieBreaker: tieBreaker,
    ),
  );
}

void main() {
  group('coin toss', () {
    test('Player 1 becomes attacker when the call matches', () {
      final engine = GameEngine(
        players: _players,
        random: ScriptedRandomSource(coins: [CoinSide.heads]),
      );
      final events = engine.callCoinToss(CoinSide.heads);

      expect(engine.state.attacker, PlayerId.one);
      expect(engine.state.taya, PlayerId.two);
      expect(engine.state.phase, GamePhase.awaitingThrow);
      expect(engine.state.coinCall, CoinSide.heads);
      expect(engine.state.coinResult, CoinSide.heads);
      final toss = events.single as CoinTossed;
      expect(toss.attacker, PlayerId.one);
    });

    test('Player 1 becomes taya when the call does not match', () {
      final engine = GameEngine(
        players: _players,
        random: ScriptedRandomSource(coins: [CoinSide.tails]),
      );
      engine.callCoinToss(CoinSide.heads);

      expect(engine.state.attacker, PlayerId.two);
      expect(engine.state.taya, PlayerId.one);
    });

    test('a new game starts at the coin toss with 3 attempts and 0-0', () {
      final engine = GameEngine(players: _players);
      expect(engine.state.phase, GamePhase.coinToss);
      expect(engine.state.attacker, isNull);
      expect(engine.state.scores, const Scores(0, 0));
      expect(engine.state.captureAttemptsLeft, 3);
    });
  });

  group('throw', () {
    test('a hit scores 1 for the attacker and waits for the taya', () {
      final engine = _engineAt(rolls: [true]);
      final events = engine.throwSlipper();

      expect(engine.state.scores, const Scores(1, 0));
      expect(engine.state.phase, GamePhase.awaitingHitResponse);
      expect(engine.state.canIsDown, isTrue);
      final award = events.whereType<PointsAwarded>().single;
      expect(award.player, PlayerId.one);
      expect(award.reason, ScoreReason.canKnockedDown);
    });

    test('a miss scores nothing and waits for the taya', () {
      final engine = _engineAt(rolls: [false]);
      final events = engine.throwSlipper();

      expect(engine.state.scores, const Scores(0, 0));
      expect(engine.state.phase, GamePhase.awaitingMissResponse);
      expect((events.first as ThrowResolved).outcome, ThrowOutcome.miss);
    });

    test('a miss with no attempts left skips straight to the next throw', () {
      final engine = _engineAt(attempts: 0, rolls: [false]);
      final events = engine.throwSlipper();

      expect(engine.state.phase, GamePhase.awaitingThrow);
      expect(events.whereType<CaptureUnavailable>(), hasLength(1));
    });

    test('the throw uses the configured hit chance', () {
      final random = ScriptedRandomSource(rolls: [false]);
      final engine = _engineAt(
        config: const GameConfig(hitChance: 0.7),
        random: random,
      );
      engine.throwSlipper();
      expect(random.requestedChances, [0.7]);
    });
  });

  group('miss response', () {
    test('Allow Next Throw uses no attempt and awards nothing', () {
      final engine = _engineAt(
        phase: GamePhase.awaitingMissResponse,
        attempts: 3,
      );
      final events = engine.respondToMiss(MissResponse.allowNextThrow);

      expect(engine.state.captureAttemptsLeft, 3);
      expect(engine.state.scores, const Scores(0, 0));
      expect(engine.state.phase, GamePhase.awaitingThrow);
      expect(events.whereType<CaptureAttempted>(), isEmpty);
    });

    test('a successful capture scores 1 for the taya and uses an attempt', () {
      final engine = _engineAt(
        phase: GamePhase.awaitingMissResponse,
        rolls: [true],
      );
      final events = engine.respondToMiss(MissResponse.attemptCapture);

      expect(engine.state.scores, const Scores(0, 1));
      expect(engine.state.captureAttemptsLeft, 2);
      expect(engine.state.phase, GamePhase.awaitingThrow);
      final award = events.whereType<PointsAwarded>().single;
      expect(award.player, PlayerId.two);
      expect(award.reason, ScoreReason.slipperCaptured);
    });

    test('a failed capture scores nothing but still uses an attempt', () {
      final engine = _engineAt(
        phase: GamePhase.awaitingMissResponse,
        rolls: [false],
      );
      engine.respondToMiss(MissResponse.attemptCapture);

      expect(engine.state.scores, const Scores(0, 0));
      expect(engine.state.captureAttemptsLeft, 2);
    });

    test('attempts run out after three tries and the fourth miss skips', () {
      final engine = _engineAt(
        rolls: [false, false, false, false, false, false, false],
      );
      for (var i = 0; i < 3; i++) {
        engine.throwSlipper();
        expect(engine.state.phase, GamePhase.awaitingMissResponse);
        engine.respondToMiss(MissResponse.attemptCapture);
      }
      expect(engine.state.captureAttemptsLeft, 0);
      expect(engine.state.canAttemptCapture, isFalse);

      engine.throwSlipper();
      expect(engine.state.phase, GamePhase.awaitingThrow);
    });

    test('capture uses the configured chance', () {
      final random = ScriptedRandomSource(rolls: [true]);
      final engine = _engineAt(
        phase: GamePhase.awaitingMissResponse,
        config: const GameConfig(captureChance: 0.25),
        random: random,
      );
      engine.respondToMiss(MissResponse.attemptCapture);
      expect(random.requestedChances, [0.25]);
    });
  });

  group('hit response: guard can', () {
    test('restores the can, awards nothing more and keeps the roles', () {
      final engine = _engineAt(
        phase: GamePhase.awaitingHitResponse,
        scores: const Scores(1, 0),
        attempts: 2,
      );
      final events = engine.respondToHit(HitResponse.guardCan);

      expect(engine.state.scores, const Scores(1, 0));
      expect(engine.state.attacker, PlayerId.one);
      expect(engine.state.captureAttemptsLeft, 2);
      expect(engine.state.phase, GamePhase.awaitingThrow);
      expect(engine.state.canIsDown, isFalse);
      expect(events.whereType<CanRestored>(), hasLength(1));
      expect(events.whereType<PointsAwarded>(), isEmpty);
    });
  });

  group('hit response: catch player', () {
    test('success gives the taya 2, swaps roles and resets attempts', () {
      final engine = _engineAt(
        phase: GamePhase.awaitingHitResponse,
        scores: const Scores(1, 0), // the attacker's knockdown point
        attempts: 1,
        rolls: [true],
      );
      final events = engine.respondToHit(HitResponse.catchPlayer);

      expect(engine.state.scores, const Scores(1, 2));
      expect(engine.state.attacker, PlayerId.two);
      expect(engine.state.taya, PlayerId.one);
      expect(engine.state.captureAttemptsLeft, 3);
      expect(engine.state.phase, GamePhase.awaitingThrow);
      final swap = events.whereType<RolesSwapped>().single;
      expect(swap.attacker, PlayerId.two);
      expect(events.whereType<CanRestored>(), hasLength(1));
    });

    test('failure awards nothing, keeps roles and attempts, restores can', () {
      final engine = _engineAt(
        phase: GamePhase.awaitingHitResponse,
        scores: const Scores(1, 0),
        attempts: 1,
        rolls: [false],
      );
      final events = engine.respondToHit(HitResponse.catchPlayer);

      expect(engine.state.scores, const Scores(1, 0));
      expect(engine.state.attacker, PlayerId.one);
      expect(engine.state.captureAttemptsLeft, 1);
      expect(engine.state.phase, GamePhase.awaitingThrow);
      expect(events.whereType<CanRestored>(), hasLength(1));
      expect(events.whereType<RolesSwapped>(), isEmpty);
    });

    test('catch uses the configured chance and points', () {
      final random = ScriptedRandomSource(rolls: [true]);
      final engine = _engineAt(
        phase: GamePhase.awaitingHitResponse,
        config: const GameConfig(catchChance: 0.4, catchPoints: 3),
        random: random,
      );
      engine.respondToHit(HitResponse.catchPlayer);
      expect(random.requestedChances, [0.4]);
      expect(engine.state.scores.two, 3);
    });
  });

  group('winning', () {
    test('a hit to 10 is only decided after the taya responds', () {
      final engine = _engineAt(scores: const Scores(9, 3), rolls: [true]);
      engine.throwSlipper();

      expect(engine.state.scores.one, 10);
      expect(engine.state.phase, GamePhase.awaitingHitResponse);
      expect(engine.state.winner, isNull);

      final events = engine.respondToHit(HitResponse.guardCan);
      expect(engine.state.phase, GamePhase.finished);
      expect(engine.state.winner, PlayerId.one);
      expect(engine.state.winMethod, WinMethod.reachedTarget);
      expect(events.whereType<GameWon>(), hasLength(1));
    });

    test('a successful capture can win the game for the taya', () {
      final engine = _engineAt(
        phase: GamePhase.awaitingMissResponse,
        scores: const Scores(4, 9),
        rolls: [true],
      );
      engine.respondToMiss(MissResponse.attemptCapture);

      expect(engine.state.phase, GamePhase.finished);
      expect(engine.state.winner, PlayerId.two);
    });

    test('a successful catch can win the game for the taya', () {
      final engine = _engineAt(
        phase: GamePhase.awaitingHitResponse,
        scores: const Scores(6, 8),
        rolls: [true],
      );
      engine.respondToHit(HitResponse.catchPlayer);

      expect(engine.state.scores, const Scores(6, 10));
      expect(engine.state.winner, PlayerId.two);
    });

    test('both reaching 10 in one exchange starts the tie-breaker', () {
      final engine = _engineAt(
        phase: GamePhase.awaitingHitResponse,
        scores: const Scores(10, 8), // attacker just hit from 9
        rolls: [true],
      );
      final events = engine.respondToHit(HitResponse.catchPlayer);

      expect(engine.state.scores, const Scores(10, 10));
      expect(engine.state.phase, GamePhase.tieBreaker);
      expect(engine.state.winner, isNull);
      expect(events.whereType<TieBreakerStarted>(), hasLength(1));
    });

    test('unequal scores at or above 10 still go to the tie-breaker', () {
      final engine = _engineAt(
        phase: GamePhase.awaitingHitResponse,
        scores: const Scores(10, 9),
        rolls: [true],
      );
      engine.respondToHit(HitResponse.catchPlayer);

      expect(engine.state.scores, const Scores(10, 11));
      expect(engine.state.phase, GamePhase.tieBreaker);
    });

    test('the target comes from the config', () {
      final engine = _engineAt(
        config: const GameConfig(targetScore: 3),
        scores: const Scores(2, 0),
        rolls: [true],
      );
      engine.throwSlipper();
      engine.respondToHit(HitResponse.guardCan);
      expect(engine.state.winner, PlayerId.one);
    });
  });

  group('Jack-en-Poy tie-breaker', () {
    GameEngine tieBreakerEngine() => _engineAt(
      phase: GamePhase.tieBreaker,
      scores: const Scores(10, 10),
      tieBreaker: const TieBreakerState(),
    );

    test('Player 1 locks first and the hand stays private in events', () {
      final engine = tieBreakerEngine();
      final events = engine.submitTieBreakerHand(PlayerId.one, Hand.rock);

      expect(engine.state.tieBreaker!.awaiting, PlayerId.two);
      expect(events.single, isA<TieBreakerHandLocked>());
      expect(engine.state.phase, GamePhase.tieBreaker);
    });

    test('the winning hand wins the game', () {
      final engine = tieBreakerEngine();
      engine.submitTieBreakerHand(PlayerId.one, Hand.rock);
      final events = engine.submitTieBreakerHand(PlayerId.two, Hand.scissors);

      expect(engine.state.phase, GamePhase.finished);
      expect(engine.state.winner, PlayerId.one);
      expect(engine.state.winMethod, WinMethod.tieBreaker);
      final round = events.whereType<TieBreakerRoundResolved>().single;
      expect(round.winner, PlayerId.one);
      expect(round.player2Hand, Hand.scissors);
    });

    test('Player 2 can win', () {
      final engine = tieBreakerEngine();
      engine.submitTieBreakerHand(PlayerId.one, Hand.rock);
      engine.submitTieBreakerHand(PlayerId.two, Hand.paper);
      expect(engine.state.winner, PlayerId.two);
    });

    test('a draw repeats the round until someone wins', () {
      final engine = tieBreakerEngine();
      engine.submitTieBreakerHand(PlayerId.one, Hand.paper);
      final draw = engine.submitTieBreakerHand(PlayerId.two, Hand.paper);

      expect(draw.whereType<TieBreakerRoundResolved>().single.winner, isNull);
      expect(engine.state.phase, GamePhase.tieBreaker);
      expect(engine.state.tieBreaker!.round, 2);
      expect(engine.state.tieBreaker!.awaiting, PlayerId.one);
      expect(engine.state.tieBreaker!.firstHand, isNull);
      expect(engine.state.winner, isNull);

      engine.submitTieBreakerHand(PlayerId.one, Hand.scissors);
      engine.submitTieBreakerHand(PlayerId.two, Hand.paper);
      expect(engine.state.winner, PlayerId.one);
    });

    test('Player 2 cannot go first', () {
      final engine = tieBreakerEngine();
      expect(
        () => engine.submitTieBreakerHand(PlayerId.two, Hand.rock),
        throwsA(isA<InvalidGameActionException>()),
      );
    });

    test('Player 1 cannot submit twice in a row', () {
      final engine = tieBreakerEngine();
      engine.submitTieBreakerHand(PlayerId.one, Hand.rock);
      expect(
        () => engine.submitTieBreakerHand(PlayerId.one, Hand.paper),
        throwsA(isA<InvalidGameActionException>()),
      );
    });
  });

  group('invalid actions', () {
    test('throwing before the coin toss is rejected', () {
      final engine = GameEngine(players: _players);
      expect(engine.throwSlipper, throwsA(isA<InvalidGameActionException>()));
    });

    test('responding to a hit when no hit happened is rejected', () {
      final engine = _engineAt();
      expect(
        () => engine.respondToHit(HitResponse.guardCan),
        throwsA(isA<InvalidGameActionException>()),
      );
    });

    test('a response cannot be submitted twice', () {
      final engine = _engineAt(phase: GamePhase.awaitingMissResponse);
      engine.respondToMiss(MissResponse.allowNextThrow);
      expect(
        () => engine.respondToMiss(MissResponse.allowNextThrow),
        throwsA(isA<InvalidGameActionException>()),
      );
    });

    test('nothing can happen after the game is finished', () {
      final engine = _engineAt(
        phase: GamePhase.finished,
        scores: const Scores(10, 0),
      );
      expect(engine.throwSlipper, throwsA(isA<InvalidGameActionException>()));
      expect(
        () => engine.callCoinToss(CoinSide.heads),
        throwsA(isA<InvalidGameActionException>()),
      );
    });

    test('a rejected command leaves the state untouched', () {
      final engine = _engineAt(rolls: [true]);
      final before = engine.state;
      try {
        engine.respondToHit(HitResponse.guardCan);
      } on InvalidGameActionException {
        // expected
      }
      expect(identical(engine.state, before), isTrue);
    });
  });

  group('full-game simulation', () {
    // Plays 300 seeded games with random choices and checks the invariants
    // that must hold in every state.
    test('every game terminates with a valid winner', () {
      for (var seed = 0; seed < 300; seed++) {
        final choices = Random(seed + 10000);
        final engine = GameEngine(
          players: _players,
          random: DartRandomSource(Random(seed)),
        );
        engine.callCoinToss(
          choices.nextBool() ? CoinSide.heads : CoinSide.tails,
        );

        var steps = 0;
        while (!engine.state.isFinished) {
          expect(steps++ < 5000, isTrue);
          switch (engine.state.phase) {
            case GamePhase.coinToss:
            case GamePhase.finished:
              fail('unreachable phase ${engine.state.phase}');
            case GamePhase.awaitingThrow:
              engine.throwSlipper();
            case GamePhase.awaitingMissResponse:
              engine.respondToMiss(MissResponse.values[choices.nextInt(2)]);
            case GamePhase.awaitingHitResponse:
              engine.respondToHit(HitResponse.values[choices.nextInt(2)]);
            case GamePhase.tieBreaker:
              final awaiting = engine.state.tieBreaker!.awaiting;
              engine.submitTieBreakerHand(
                awaiting,
                Hand.values[choices.nextInt(3)],
              );
          }

          final state = engine.state;
          expect(state.scores.one >= 0 && state.scores.two >= 0, isTrue);
          expect(
            state.captureAttemptsLeft >= 0 && state.captureAttemptsLeft <= 3,
            isTrue,
          );
          if (state.phase == GamePhase.awaitingThrow) {
            expect(state.scores.verdict(10), ScoreVerdict.keepPlaying);
          }
        }

        final state = engine.state;
        expect(state.winner, isNotNull);
        if (state.winMethod == WinMethod.reachedTarget) {
          expect(state.scores.of(state.winner!) >= 10, isTrue);
          expect(state.scores.of(state.winner!.other) < 10, isTrue);
        } else {
          expect(state.scores.one >= 10 && state.scores.two >= 10, isTrue);
        }
      }
    });
  });
}
