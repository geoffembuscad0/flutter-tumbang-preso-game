import 'package:flutter_test/flutter_test.dart';
import 'package:game_tumbang_preso/domain/domain.dart';
import 'package:game_tumbang_preso/state/game_controller.dart';
import 'package:game_tumbang_preso/state/turn_step.dart';

import '../support/scripted_random_source.dart';

final _players = Players.fromSetup(
  firstName: 'Ana',
  firstChoice: PlayerId.one,
  secondName: 'Ben',
);

GameController _controller({
  List<CoinSide> coins = const [],
  List<bool> rolls = const [],
  GameConfig config = const GameConfig(),
}) {
  return GameController.newGame(
    players: _players,
    config: config,
    random: ScriptedRandomSource(coins: coins, rolls: rolls),
  );
}

/// A controller already past the coin toss, with Player 1 attacking.
GameController _started({List<bool> rolls = const []}) {
  final controller = _controller(coins: [CoinSide.heads], rolls: rolls);
  controller.callCoinToss(CoinSide.heads);
  return controller;
}

/// A controller in the middle of a game, built from an explicit state.
GameController _controllerAt({
  Scores scores = const Scores(),
  int attempts = 3,
  List<bool> rolls = const [],
}) {
  return GameController(
    GameEngine(
      players: _players,
      random: ScriptedRandomSource(rolls: rolls),
      initialState: GameState(
        players: _players,
        phase: GamePhase.awaitingThrow,
        scores: scores,
        attacker: PlayerId.one,
        captureAttemptsLeft: attempts,
      ),
    ),
  );
}

void main() {
  group('GameController', () {
    test('starts at the coin toss with the given players and no events', () {
      final controller = _controller();

      expect(controller.state.phase, GamePhase.coinToss);
      expect(controller.players.one.name, 'Ana');
      expect(controller.players.two.name, 'Ben');
      expect(controller.lastEvents, isEmpty);
    });

    test('newGame passes the config through to the engine', () {
      final controller = _controller(config: const GameConfig(targetScore: 3));

      expect(controller.config.targetScore, 3);
    });

    test('a command updates state, returns its events and notifies once', () {
      final controller = _controller(coins: [CoinSide.heads]);
      var notified = 0;
      controller.addListener(() => notified++);

      final events = controller.callCoinToss(CoinSide.heads);

      expect(controller.state.phase, GamePhase.awaitingThrow);
      expect(controller.state.attacker, PlayerId.one);
      expect(events.single, isA<CoinTossed>());
      expect(controller.lastEvents, events);
      expect(notified, 1);
    });

    test('the listener already sees the new state when it is notified', () {
      final controller = _controller(coins: [CoinSide.tails]);
      PlayerId? attackerSeen;
      controller.addListener(() => attackerSeen = controller.state.attacker);

      controller.callCoinToss(CoinSide.heads);

      expect(attackerSeen, PlayerId.two);
    });

    test('a rejected command throws, changes nothing and does not notify', () {
      final controller = _controller();
      var notified = 0;
      controller.addListener(() => notified++);

      expect(
        controller.throwSlipper,
        throwsA(isA<InvalidGameActionException>()),
      );

      expect(controller.state.phase, GamePhase.coinToss);
      expect(controller.lastEvents, isEmpty);
      expect(notified, 0);
    });

    test('each command in a round notifies and replaces lastEvents', () {
      final controller = _controller(coins: [CoinSide.heads], rolls: [true]);
      var notified = 0;
      controller.addListener(() => notified++);

      controller.callCoinToss(CoinSide.heads);
      controller.throwSlipper();
      expect(controller.state.phase, GamePhase.awaitingHitResponse);
      expect(controller.state.scores, const Scores(1, 0));
      expect(controller.lastEvents.first, isA<ThrowResolved>());

      controller.continueFromThrow();
      controller.confirmHandoff();
      controller.respondToHit(HitResponse.guardCan);
      expect(controller.state.phase, GamePhase.awaitingThrow);
      expect(controller.lastEvents.last, isA<CanRestored>());

      // coin toss, throw, two step changes, response
      expect(notified, 5);
    });

    test('a removed listener is no longer notified', () {
      final controller = _controller(coins: [CoinSide.heads]);
      var notified = 0;
      void listener() => notified++;

      controller.addListener(listener);
      controller.removeListener(listener);
      controller.callCoinToss(CoinSide.heads);

      expect(notified, 0);
    });
  });

  group('turn steps', () {
    test('a game starts at the throwing step', () {
      expect(_controller().step, TurnStep.throwing);
    });

    test('a hit moves through every step in order', () {
      final controller = _started(rolls: [true]);

      controller.throwSlipper();
      expect(controller.step, TurnStep.throwResult);

      controller.continueFromThrow();
      expect(controller.step, TurnStep.handoff);

      controller.confirmHandoff();
      expect(controller.step, TurnStep.privateChoice);

      controller.respondToHit(HitResponse.guardCan);
      expect(controller.step, TurnStep.responseResult);

      controller.continueFromResponse();
      expect(controller.step, TurnStep.throwing);
      expect(controller.state.phase, GamePhase.awaitingThrow);
    });

    test('a miss with capture attempts left also needs the handoff', () {
      final controller = _started(rolls: [false, true]);

      controller.throwSlipper();
      expect(controller.state.phase, GamePhase.awaitingMissResponse);
      controller.continueFromThrow();
      expect(controller.step, TurnStep.handoff);
      controller.confirmHandoff();
      controller.respondToMiss(MissResponse.attemptCapture);

      expect(controller.step, TurnStep.responseResult);
      expect(controller.state.scores, const Scores(0, 1));
    });

    test('a miss with no capture attempts left skips the handoff', () {
      final controller = _controllerAt(attempts: 0, rolls: [false]);

      controller.throwSlipper();
      expect(controller.step, TurnStep.throwResult);
      expect(controller.state.phase, GamePhase.awaitingThrow);

      controller.continueFromThrow();
      expect(controller.step, TurnStep.throwing);
    });

    test('the taya cannot choose before the handoff is confirmed', () {
      final controller = _started(rolls: [true]);
      controller.throwSlipper();
      var notified = 0;
      controller.addListener(() => notified++);

      // Throw result: the device is still with the attacker.
      expect(
        () => controller.respondToHit(HitResponse.catchPlayer),
        throwsA(isA<InvalidGameActionException>()),
      );

      // Handoff: the device is on its way but not yet confirmed.
      controller.continueFromThrow();
      notified = 0;
      expect(
        () => controller.respondToHit(HitResponse.catchPlayer),
        throwsA(isA<InvalidGameActionException>()),
      );

      expect(controller.state.phase, GamePhase.awaitingHitResponse);
      expect(controller.step, TurnStep.handoff);
      expect(notified, 0);

      // Once confirmed, the same command is accepted.
      controller.confirmHandoff();
      controller.respondToHit(HitResponse.guardCan);
      expect(controller.step, TurnStep.responseResult);
    });

    test('the miss response is gated by the handoff in the same way', () {
      final controller = _started(rolls: [false]);
      controller.throwSlipper();
      controller.continueFromThrow();

      expect(
        () => controller.respondToMiss(MissResponse.allowNextThrow),
        throwsA(isA<InvalidGameActionException>()),
      );
    });

    test('steps cannot be skipped or repeated', () {
      final controller = _started(rolls: [true]);

      expect(
        controller.confirmHandoff,
        throwsA(isA<InvalidGameActionException>()),
      );
      expect(
        controller.continueFromThrow,
        throwsA(isA<InvalidGameActionException>()),
      );
      expect(
        controller.continueFromResponse,
        throwsA(isA<InvalidGameActionException>()),
      );

      controller.throwSlipper();
      expect(
        controller.throwSlipper,
        throwsA(isA<InvalidGameActionException>()),
      );

      controller.continueFromThrow();
      controller.confirmHandoff();
      expect(
        controller.confirmHandoff,
        throwsA(isA<InvalidGameActionException>()),
      );
      expect(
        controller.continueFromResponse,
        throwsA(isA<InvalidGameActionException>()),
      );
    });

    test('a response cannot be submitted twice', () {
      final controller = _started(rolls: [true]);
      controller.throwSlipper();
      controller.continueFromThrow();
      controller.confirmHandoff();
      controller.respondToHit(HitResponse.guardCan);

      expect(
        () => controller.respondToHit(HitResponse.guardCan),
        throwsA(isA<InvalidGameActionException>()),
      );
    });

    test('step changes keep the last engine events for the result screens', () {
      final controller = _started(rolls: [true]);
      final throwEvents = controller.throwSlipper();

      controller.continueFromThrow();
      expect(identical(controller.lastEvents, throwEvents), isTrue);

      controller.confirmHandoff();
      expect(identical(controller.lastEvents, throwEvents), isTrue);

      final responseEvents = controller.respondToHit(HitResponse.guardCan);
      controller.continueFromResponse();
      expect(identical(controller.lastEvents, responseEvents), isTrue);
    });

    test('every step change notifies listeners once', () {
      final controller = _started(rolls: [true]);
      controller.throwSlipper();
      var notified = 0;
      controller.addListener(() => notified++);

      controller.continueFromThrow();
      controller.confirmHandoff();
      controller.respondToHit(HitResponse.guardCan);
      controller.continueFromResponse();

      expect(notified, 4);
    });

    test('a response that ends the game is shown before the winner', () {
      final controller = _controllerAt(
        scores: const Scores(9, 0),
        rolls: [true],
      );
      controller.throwSlipper();
      controller.continueFromThrow();
      controller.confirmHandoff();
      controller.respondToHit(HitResponse.guardCan);

      expect(controller.state.phase, GamePhase.finished);
      expect(controller.step, TurnStep.responseResult);

      controller.continueFromResponse();
      expect(controller.step, TurnStep.throwing);
      expect(controller.state.winner, PlayerId.one);
    });
  });
}