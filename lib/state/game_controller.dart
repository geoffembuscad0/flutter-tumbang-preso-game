import 'package:flutter/foundation.dart';
import 'package:game_tumbang_preso/domain/domain.dart';
import 'package:game_tumbang_preso/state/tie_breaker_step.dart';
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
  TieBreakerStep _tieBreakerStep = TieBreakerStep.handoffFirst;

  GameState get state => _engine.state;

  GameConfig get config => _engine.config;

  Players get players => _engine.state.players;

  // What the shared device is waiting for in the current exchange.
  TurnStep get step => _step;

  // Where the current Jack-en-Poy round stands on the shared device. Only
  // meaningful while the engine is in its tie-breaker phase (or just after it
  // has been decided, while the last round is still being shown).
  TieBreakerStep get tieBreakerStep => _tieBreakerStep;

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

  // Locks in the hand of whoever is picking: Player 1 at
  // [TieBreakerStep.firstPick], Player 2 at [TieBreakerStep.secondPick]. The
  // controller works out which, so a screen cannot lock a hand for the wrong
  // player, and it is rejected at every other step (including before the
  // handoff is confirmed). The events never include the hand itself until
  // both are locked.
  List<GameEvent> lockHand(Hand hand) {
    final step = _tieBreakerStep;
    final PlayerId player;
    final TieBreakerStep next;
    switch (step) {
      case TieBreakerStep.firstPick:
        player = PlayerId.one;
        next = TieBreakerStep.handoffSecond;
      case TieBreakerStep.secondPick:
        player = PlayerId.two;
        next = TieBreakerStep.roundResult;
      case TieBreakerStep.handoffFirst:
      case TieBreakerStep.handoffSecond:
      case TieBreakerStep.roundResult:
        throw InvalidGameActionException(
          'Expected a hand pick but the device is at ${step.name}.',
        );
    }
    return _runEngine(
      () => _engine.submitTieBreakerHand(player, hand),
      nextTieBreaker: next,
    );
  }

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

  // --- Tie-breaker step transitions (no engine events) --------------------

  // Player 1 confirms they are holding the device. This is the only way into
  // [TieBreakerStep.firstPick].
  void confirmFirstHandoff() {
    _requireTieBreakerStep(TieBreakerStep.handoffFirst);
    _setTieBreakerStep(TieBreakerStep.firstPick);
  }

  // Player 2 confirms they are holding the device. This is the only way into
  // [TieBreakerStep.secondPick].
  void confirmSecondHandoff() {
    _requireTieBreakerStep(TieBreakerStep.handoffSecond);
    _setTieBreakerStep(TieBreakerStep.secondPick);
  }

  // Leaves the round result. After a draw the engine has already started the
  // next round, so this sends the device back to Player 1; after a win the
  // screen shows the winner, read from [state].
  void continueFromRound() {
    _requireTieBreakerStep(TieBreakerStep.roundResult);
    _setTieBreakerStep(TieBreakerStep.handoffFirst);
  }

  // --- Internals ---------------------------------------------------------

  List<GameEvent> _runEngine(
    List<GameEvent> Function() command, {
    TurnStep? next,
    TieBreakerStep? nextTieBreaker,
  }) {
    final events = List<GameEvent>.unmodifiable(command());
    _lastEvents = events;
    if (next != null) _step = next;
    if (nextTieBreaker != null) _tieBreakerStep = nextTieBreaker;
    notifyListeners();
    return events;
  }

  void _setStep(TurnStep next) {
    _step = next;
    notifyListeners();
  }

  void _setTieBreakerStep(TieBreakerStep next) {
    _tieBreakerStep = next;
    notifyListeners();
  }

  void _requireTieBreakerStep(TieBreakerStep expected) {
    if (_tieBreakerStep != expected) {
      throw InvalidGameActionException(
        'Expected tie-breaker step ${expected.name} but the device is at '
        '${_tieBreakerStep.name}.',
      );
    }
  }

  void _requireStep(TurnStep expected) {
    if (_step != expected) {
      throw InvalidGameActionException(
        'Expected step ${expected.name} but the device is at ${_step.name}.',
      );
    }
  }
}