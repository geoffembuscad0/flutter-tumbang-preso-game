import 'package:flutter_test/flutter_test.dart';
import 'package:game_tumbang_preso/domain/domain.dart';
import 'package:game_tumbang_preso/state/game_controller.dart';

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

      controller.respondToHit(HitResponse.guardCan);
      expect(controller.state.phase, GamePhase.awaitingThrow);
      expect(controller.lastEvents.last, isA<CanRestored>());

      expect(notified, 3);
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
}