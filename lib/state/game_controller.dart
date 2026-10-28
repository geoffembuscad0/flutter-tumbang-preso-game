import 'package:flutter/foundation.dart';
import 'package:game_tumbang_preso/domain/domain.dart';
/*
 Connects the [GameEngine] to the UI.

 Screens read [state] and rebuild when the controller notifies (for example
 with a `ListenableBuilder`). They change the game only through the command
 methods below, which forward to the engine and then notify listeners.

 Each command returns the events it produced, and the same list stays
 available as [lastEvents], so a screen can play a reveal step by step.

 A command that the engine rejects (wrong phase) throws
 [InvalidGameActionException] and leaves the state unchanged, and nothing
 is notified.

 The controller owns no timers or streams, so it needs no cleanup; it is
 simply garbage collected once the last screen using it is gone. */
class GameController extends ChangeNotifier {
  GameController(this._engine);

    // Starts a fresh game for [players]. Pass a scripted [random] in tests.
  factory GameController.newGame({
    required Players players,
    GameConfig config = const GameConfig(),
    RandomSource? random,
  }) {
    return GameController(
      GameEngine(players: players, config: config, random: random),
    );
  }

  final GameEngine _engine;
  List<GameEvent> _lastEvents = const [];

  GameState get state => _engine.state;

  GameConfig get config => _engine.config;

  Players get players => _engine.state.players;

// Events produced by the most recent command; empty before the first one.
  List<GameEvent> get lastEvents => _lastEvents;

  List<GameEvent> callCoinToss(CoinSide call) =>
      _run(() => _engine.callCoinToss(call));

  List<GameEvent> throwSlipper() => _run(_engine.throwSlipper);

  List<GameEvent> respondToMiss(MissResponse response) =>
      _run(() => _engine.respondToMiss(response));

  List<GameEvent> respondToHit(HitResponse response) =>
      _run(() => _engine.respondToHit(response));

  List<GameEvent> submitTieBreakerHand(PlayerId player, Hand hand) =>
      _run(() => _engine.submitTieBreakerHand(player, hand));

  List<GameEvent> _run(List<GameEvent> Function() command) {
    final events = List<GameEvent>.unmodifiable(command());
    _lastEvents = events;
    notifyListeners();
    return events;
  }
}