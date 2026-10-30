import 'package:flutter_test/flutter_test.dart';
import 'package:game_tumbang_preso/domain/domain.dart';
import 'package:game_tumbang_preso/ui/game/summaries.dart';

final _players = Players.fromSetup(
  firstName: 'Ana',
  firstChoice: PlayerId.one,
  secondName: 'Ben',
);

void main() {
  group('summarizeThrow', () {
    test('a hit names the attacker and the point', () {
      final summary = summarizeThrow(const [
        ThrowResolved(attacker: PlayerId.one, outcome: ThrowOutcome.hit),
        PointsAwarded(
          player: PlayerId.one,
          points: 1,
          reason: ScoreReason.canKnockedDown,
        ),
      ], _players);

      expect(summary.headline, 'Hit!');
      expect(summary.details, ['The can is down. Ana scores 1 point.']);
    });

    test('a miss says the can is still standing', () {
      final summary = summarizeThrow(const [
        ThrowResolved(attacker: PlayerId.two, outcome: ThrowOutcome.miss),
      ], _players);

      expect(summary.headline, 'Missed!');
      expect(summary.details, ['The can is still standing.']);
    });

    test('a miss with no capture attempts left explains the skip', () {
      final summary = summarizeThrow(const [
        ThrowResolved(attacker: PlayerId.one, outcome: ThrowOutcome.miss),
        CaptureUnavailable(taya: PlayerId.two),
      ], _players);

      expect(summary.details, hasLength(2));
      expect(
        summary.details.last,
        'Ben has no capture attempts left, so Ana throws again.',
      );
    });

    test('events without a throw are rejected', () {
      expect(
        () => summarizeThrow(const [], _players),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('summarizeResponse after a miss', () {
    test('Allow Next Throw', () {
      final summary = summarizeResponse(
        const [
          MissResponded(
            taya: PlayerId.two,
            response: MissResponse.allowNextThrow,
          ),
        ],
        _players,
        10,
      );

      expect(summary.headline, 'Next throw');
      expect(summary.details, ['Ben lets Ana throw again.']);
    });

    test('a successful capture scores and reports attempts left', () {
      final summary = summarizeResponse(
        const [
          MissResponded(
            taya: PlayerId.two,
            response: MissResponse.attemptCapture,
          ),
          CaptureAttempted(taya: PlayerId.two, success: true, attemptsLeft: 2),
          PointsAwarded(
            player: PlayerId.two,
            points: 1,
            reason: ScoreReason.slipperCaptured,
          ),
        ],
        _players,
        10,
      );

      expect(summary.headline, 'Slipper captured!');
      expect(summary.details, [
        'Ben scores 1 point.',
        '2 capture attempts left.',
      ]);
    });

    test('a failed capture awards nothing and counts the attempt', () {
      final summary = summarizeResponse(
        const [
          MissResponded(
            taya: PlayerId.two,
            response: MissResponse.attemptCapture,
          ),
          CaptureAttempted(taya: PlayerId.two, success: false, attemptsLeft: 1),
        ],
        _players,
        10,
      );

      expect(summary.headline, 'Capture failed.');
      expect(summary.details, [
        'No points this time.',
        '1 capture attempt left.',
      ]);
    });

    test('using the last attempt says none are left', () {
      final summary = summarizeResponse(
        const [
          MissResponded(
            taya: PlayerId.two,
            response: MissResponse.attemptCapture,
          ),
          CaptureAttempted(taya: PlayerId.two, success: false, attemptsLeft: 0),
        ],
        _players,
        10,
      );

      expect(summary.details.last, 'No capture attempts left.');
    });
  });

  group('summarizeResponse after a hit', () {
    test('Guard Can', () {
      final summary = summarizeResponse(
        const [
          HitResponded(taya: PlayerId.two, response: HitResponse.guardCan),
          CanRestored(),
        ],
        _players,
        10,
      );

      expect(summary.headline, 'Can guarded.');
      expect(summary.details.first, 'Ben puts the can back up.');
    });

    test('a successful catch scores and swaps the roles', () {
      final summary = summarizeResponse(
        const [
          HitResponded(taya: PlayerId.two, response: HitResponse.catchPlayer),
          CatchAttempted(taya: PlayerId.two, success: true),
          PointsAwarded(
            player: PlayerId.two,
            points: 2,
            reason: ScoreReason.successfulCatch,
          ),
          RolesSwapped(attacker: PlayerId.two, taya: PlayerId.one),
          CanRestored(),
        ],
        _players,
        10,
      );

      expect(summary.headline, 'Caught!');
      expect(summary.details, [
        'Ben catches Ana and scores 2 points.',
        'Ben is the attacker now, and Ana is the taya.',
      ]);
    });

    test('a failed catch lets the attacker escape', () {
      final summary = summarizeResponse(
        const [
          HitResponded(taya: PlayerId.two, response: HitResponse.catchPlayer),
          CatchAttempted(taya: PlayerId.two, success: false),
          CanRestored(),
        ],
        _players,
        10,
      );

      expect(summary.headline, 'Got away!');
      expect(summary.details.first, 'Ana escapes. No catch points.');
    });
  });

  group('summarizeResponse at the end of an exchange', () {
    test('a winning response says who won', () {
      final summary = summarizeResponse(
        const [
          HitResponded(taya: PlayerId.two, response: HitResponse.guardCan),
          CanRestored(),
          GameWon(winner: PlayerId.one, method: WinMethod.reachedTarget),
        ],
        _players,
        10,
      );

      expect(summary.details.last, 'Ana wins the game!');
    });

    test('both reaching the target announces Jack-en-Poy', () {
      final summary = summarizeResponse(
        const [
          HitResponded(taya: PlayerId.two, response: HitResponse.catchPlayer),
          CatchAttempted(taya: PlayerId.two, success: true),
          CanRestored(),
          TieBreakerStarted(),
        ],
        _players,
        10,
      );

      expect(
        summary.details.last,
        'Both players reached 10, so Jack-en-Poy decides the winner.',
      );
    });

    test('events without a response are rejected', () {
      expect(
        () => summarizeResponse(const [], _players, 10),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('summarizeTieBreakerRound', () {
    test('a Player 1 win names the winner and the rule', () {
      final summary = summarizeTieBreakerRound(const [
        TieBreakerHandLocked(player: PlayerId.two),
        TieBreakerRoundResolved(
          round: 1,
          player1Hand: Hand.rock,
          player2Hand: Hand.scissors,
          winner: PlayerId.one,
        ),
        GameWon(winner: PlayerId.one, method: WinMethod.tieBreaker),
      ], _players);

      expect(summary.headline, 'Ana wins Jack-en-Poy!');
      expect(summary.details, ['Rock breaks Scissors.']);
      expect(summary.isDraw, isFalse);
      expect(summary.winner, PlayerId.one);
      expect(summary.player1Hand, Hand.rock);
      expect(summary.player2Hand, Hand.scissors);
    });

    test('a Player 2 win uses the winning hand for the rule', () {
      final summary = summarizeTieBreakerRound(const [
        TieBreakerRoundResolved(
          round: 3,
          player1Hand: Hand.paper,
          player2Hand: Hand.scissors,
          winner: PlayerId.two,
        ),
      ], _players);

      expect(summary.headline, 'Ben wins Jack-en-Poy!');
      expect(summary.details, ['Scissors cut Paper.']);
      expect(summary.round, 3);
    });

    test('every winning hand has its own rule', () {
      String rule(Hand winning, Hand losing) {
        return summarizeTieBreakerRound([
          TieBreakerRoundResolved(
            round: 1,
            player1Hand: winning,
            player2Hand: losing,
            winner: PlayerId.one,
          ),
        ], _players).details.single;
      }

      expect(rule(Hand.rock, Hand.scissors), 'Rock breaks Scissors.');
      expect(rule(Hand.paper, Hand.rock), 'Paper covers Rock.');
      expect(rule(Hand.scissors, Hand.paper), 'Scissors cut Paper.');
    });

    test('a draw says so and that the round repeats', () {
      final summary = summarizeTieBreakerRound(const [
        TieBreakerRoundResolved(
          round: 2,
          player1Hand: Hand.paper,
          player2Hand: Hand.paper,
          winner: null,
        ),
      ], _players);

      expect(summary.headline, 'Draw!');
      expect(summary.isDraw, isTrue);
      expect(summary.winner, isNull);
      expect(summary.details.first, 'Both chose Paper.');
    });

    test('events without a round are rejected', () {
      expect(
        () => summarizeTieBreakerRound(const [], _players),
        throwsA(isA<StateError>()),
      );
    });

    test('handName gives display names', () {
      expect(handName(Hand.rock), 'Rock');
      expect(handName(Hand.paper), 'Paper');
      expect(handName(Hand.scissors), 'Scissors');
    });
  });
}