import 'package:flutter/foundation.dart';
import 'package:game_tumbang_preso/domain/domain.dart';
import 'package:game_tumbang_preso/state/turn_step.dart';

// Connects the [GameEngine] to the UI.
//
// Screens read [state] and [step] and rebuild when the controller notifies
// (for example with a `ListenableBuilder`). They change the game only through
// the command methods below.
//
// There are two layers of "what happens next":
//
// * [state] (the engine) decides what the rules allow.
// * [step] decides what the shared device may show, and is how the
//   pass-the-device handoff is enforced: the taya's private choice commands
//   are rejected unless the handoff has been confirmed.
//
// Engine commands return the events they produced, which also stay available
// as [lastEvents]. Step-only commands ([continueFromThrow],
// [confirmHandoff], [continueFromResponse]) leave [lastEvents] untouched, so
// a result screen can still read the events of the throw or response it is
// showing.
//
// A command that is not allowed right now throws
// [InvalidGameActionException], leaves everything unchanged and notifies
// nobody.
//
// The controller owns no timers or streams, so it needs no cleanup; it is
// simply garbage collected once the last screen using it is gone.
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
  TurnStep _step = TurnStep.throwing;

  GameState get state => _engine.state;

  GameConfig get config => _engine.config;

  Players get players => _engine.state.players;

  // What the shared device is waiting for in the current exchange.
  TurnStep get step => _step;

  // Events produced by the most recent engine command; empty before the
  // first one.
  List<GameEvent> get lastEvents => _lastEvents;

  // --- Engine commands --------------------------------------------------

  List<GameEvent> callCoinToss(CoinSide call) =>
      _runEngine(() => _engine.callCoinToss(call));

  // The attacker throws. Allowed only at [TurnStep.throwing].
  List<GameEvent> throwSlipper() {
    _requireStep(TurnStep.throwing);
    return _runEngine(_engine.throwSlipper, next: TurnStep.throwResult);
  }

  // The taya's choice after a miss. Allowed only at
  // [TurnStep.privateChoice], that is, after the handoff was confirmed.
  List<GameEvent> respondToMiss(MissResponse response) {
    _requireStep(TurnStep.privateChoice);
    return _runEngine(
      () => _engine.respondToMiss(response),
      next: TurnStep.responseResult,
    );
  }

  // The taya's choice after a hit. Allowed only at [TurnStep.privateChoice].
  List<GameEvent> respondToHit(HitResponse response) {
    _requireStep(TurnStep.privateChoice);
    return _runEngine(
      () => _engine.respondToHit(response),
      next: TurnStep.responseResult,
    );
  }

  List<GameEvent> submitTieBreakerHand(PlayerId player, Hand hand) =>
      _runEngine(() => _engine.submitTieBreakerHand(player, hand));

  // --- Step transitions (no engine events) ------------------------------

  // Leaves the throw result. When the taya has a choice to make this starts
  // the handoff; when the engine skipped the response (a miss with no
  // capture attempts left) the attacker simply throws again.
  void continueFromThrow() {
    _requireStep(TurnStep.throwResult);
    final needsResponse =
        state.phase == GamePhase.awaitingMissResponse ||
        state.phase == GamePhase.awaitingHitResponse;
    _setStep(needsResponse ? TurnStep.handoff : TurnStep.throwing);
  }

  // The taya confirms they are holding the device. This is the only way
  // into [TurnStep.privateChoice].
  void confirmHandoff() {
    _requireStep(TurnStep.handoff);
    _setStep(TurnStep.privateChoice);
  }

  // Leaves the result of the taya's choice. What comes next (another throw,
  // the tie-breaker or the winner) is read from [state].
  void continueFromResponse() {
    _requireStep(TurnStep.responseResult);
    _setStep(TurnStep.throwing);
  }

  // --- Internals ---------------------------------------------------------

  List<GameEvent> _runEngine(
    List<GameEvent> Function() command, {
    TurnStep? next,
  }) {
    final events = List<GameEvent>.unmodifiable(command());
    _lastEvents = events;
    if (next != null) _step = next;
    notifyListeners();
    return events;
  }

  void _setStep(TurnStep next) {
    _step = next;
    notifyListeners();
  }

  void _requireStep(TurnStep expected) {
    if (_step != expected) {
      throw InvalidGameActionException(
        'Expected step ${expected.name} but the device is at ${_step.name}.',
      );
    }
  }
}