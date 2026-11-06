import 'package:flutter_test/flutter_test.dart';
import 'package:game_tumbang_preso/domain/domain.dart';
import 'package:game_tumbang_preso/state/game_controller.dart';
import 'package:game_tumbang_preso/state/tie_breaker_step.dart';

final _players = Players.fromSetup(
  firstName: 'Ana',
  firstChoice: PlayerId.one,
  secondName: 'Ben',
);

GameController _tieBreakerController() {
  return GameController(
    GameEngine(
      players: _players,
      initialState: GameState(
        players: _players,
        phase: GamePhase.tieBreaker,
        scores: const Scores(10, 10),
        attacker: PlayerId.one,
        captureAttemptsLeft: 3,
        tieBreaker: const TieBreakerState(),
      ),
    ),
  );
}

void main() {
  group('Tie-breaker controller event contract', () {
    test('Player 1 hand remains private until Player 2 submits', () {
      final controller = _tieBreakerController();

      controller.confirmFirstHandoff();

      final firstEvents = controller.lockHand(Hand.rock);

      expect(firstEvents, hasLength(1));
      expect(firstEvents.single, isA<TieBreakerHandLocked>());
      expect(controller.state.tieBreaker!.firstHand, Hand.rock);
      expect(controller.state.tieBreaker!.awaiting, PlayerId.two);

      // The event reveals only which player locked a hand.
      expect(firstEvents.single, isNot(isA<TieBreakerRoundResolved>()));
    });

    test('a winning round updates the game before leaving the result step', () {
      final controller = _tieBreakerController();

      controller.confirmFirstHandoff();
      controller.lockHand(Hand.rock);

      controller.confirmSecondHandoff();
      final events = controller.lockHand(Hand.scissors);

      expect(controller.state.phase, GamePhase.finished);
      expect(controller.state.winner, PlayerId.one);
      expect(controller.state.winMethod, WinMethod.tieBreaker);

      expect(controller.tieBreakerStep, TieBreakerStep.roundResult);
      expect(events.whereType<TieBreakerRoundResolved>(), hasLength(1));
      expect(events.whereType<GameWon>(), hasLength(1));
    });

    test('a draw preserves the round result while the device is handed back', () {
      final controller = _tieBreakerController();

      controller.confirmFirstHandoff();
      controller.lockHand(Hand.paper);

      controller.confirmSecondHandoff();
      final events = controller.lockHand(Hand.paper);

      expect(controller.state.tieBreaker!.round, 2);
      expect(controller.tieBreakerStep, TieBreakerStep.roundResult);

      controller.continueFromRound();

      expect(controller.tieBreakerStep, TieBreakerStep.handoffFirst);
      expect(controller.state.tieBreaker!.awaiting, PlayerId.one);
      expect(controller.state.tieBreaker!.firstHand, isNull);

      // Step-only transitions do not replace the previous engine events.
      expect(identical(controller.lastEvents, events), isTrue);
    });

    test('every valid tie-breaker transition notifies listeners once', () {
      final controller = _tieBreakerController();
      var notifications = 0;

      controller.addListener(() => notifications++);

      controller.confirmFirstHandoff();
      controller.lockHand(Hand.rock);
      controller.confirmSecondHandoff();
      controller.lockHand(Hand.scissors);
      controller.continueFromRound();

      expect(notifications, 5);
    });

    test('rejected transitions do not notify or change the current step', () {
      final controller = _tieBreakerController();
      var notifications = 0;

      controller.addListener(() => notifications++);

      expect(
        controller.confirmSecondHandoff,
        throwsA(isA<InvalidGameActionException>()),
      );

      expect(
        () => controller.lockHand(Hand.rock),
        throwsA(isA<InvalidGameActionException>()),
      );

      expect(controller.tieBreakerStep, TieBreakerStep.handoffFirst);
      expect(controller.state.tieBreaker!.firstHand, isNull);
      expect(notifications, 0);
    });

    test('engine event lists cannot be modified by callers', () {
      final controller = _tieBreakerController();

      controller.confirmFirstHandoff();

      final events = controller.lockHand(Hand.rock);

      expect(
        () => events.add(const TieBreakerStarted()),
        throwsA(isA<UnsupportedError>()),
      );

      expect(
        () => controller.lastEvents.add(const TieBreakerStarted()),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}