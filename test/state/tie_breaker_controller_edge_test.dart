import 'package:flutter_test/flutter_test.dart';
import 'package:game_tumbang_preso/domain/domain.dart';
import 'package:game_tumbang_preso/state/game_controller.dart';
import 'package:game_tumbang_preso/state/tie_breaker_step.dart';

final _players = Players.fromSetup(
  firstName: 'Ana',
  firstChoice: PlayerId.one,
  secondName: 'Ben',
);

GameController _controller() {
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
  group('Jack-en-Poy controller safeguards', () {
    test('cannot select a hand before Player 1 confirms handoff', () {
      final controller = _controller();

      expect(
        () => controller.lockHand(Hand.rock),
        throwsA(isA<InvalidGameActionException>()),
      );

      expect(controller.tieBreakerStep, TieBreakerStep.handoffFirst);
      expect(controller.state.tieBreaker!.firstHand, isNull);
    });

    test('cannot skip Player 1 selection to confirm Player 2 handoff', () {
      final controller = _controller();

      expect(
        controller.confirmSecondHandoff,
        throwsA(isA<InvalidGameActionException>()),
      );

      expect(controller.tieBreakerStep, TieBreakerStep.handoffFirst);
    });

    test('Player 2 cannot select before confirming the handoff', () {
      final controller = _controller();

      controller.confirmFirstHandoff();
      controller.lockHand(Hand.rock);

      expect(controller.tieBreakerStep, TieBreakerStep.handoffSecond);

      expect(
        () => controller.lockHand(Hand.paper),
        throwsA(isA<InvalidGameActionException>()),
      );

      expect(controller.state.tieBreaker!.firstHand, Hand.rock);
    });

    test('cannot submit another hand after Player 1 has locked theirs', () {
      final controller = _controller();

      controller.confirmFirstHandoff();
      controller.lockHand(Hand.rock);

      expect(
        () => controller.lockHand(Hand.scissors),
        throwsA(isA<InvalidGameActionException>()),
      );

      expect(controller.state.tieBreaker!.firstHand, Hand.rock);
    });

    test('a draw returns the controller to Player 1 for another round', () {
      final controller = _controller();

      controller.confirmFirstHandoff();
      controller.lockHand(Hand.rock);

      controller.confirmSecondHandoff();
      controller.lockHand(Hand.rock);

      expect(controller.tieBreakerStep, TieBreakerStep.roundResult);
      expect(controller.state.tieBreaker!.round, 2);

      controller.continueFromRound();

      expect(controller.tieBreakerStep, TieBreakerStep.handoffFirst);
      expect(controller.state.tieBreaker!.awaiting, PlayerId.one);
      expect(controller.state.tieBreaker!.firstHand, isNull);
    });

    test('cannot continue a round before both hands are submitted', () {
      final controller = _controller();

      expect(
        controller.continueFromRound,
        throwsA(isA<InvalidGameActionException>()),
      );

      controller.confirmFirstHandoff();
      controller.lockHand(Hand.paper);

      expect(
        controller.continueFromRound,
        throwsA(isA<InvalidGameActionException>()),
      );
    });
  });
}
