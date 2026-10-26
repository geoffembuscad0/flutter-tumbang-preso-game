import 'package:game_tumbang_preso/domain/enums.dart';
import 'package:game_tumbang_preso/domain/game_config.dart';
import 'package:game_tumbang_preso/domain/game_event.dart';
import 'package:game_tumbang_preso/domain/game_state.dart';
import 'package:game_tumbang_preso/domain/players.dart';
import 'package:game_tumbang_preso/domain/random_source.dart';
import 'package:game_tumbang_preso/domain/scores.dart';

/// Thrown when a command arrives in the wrong phase, for example a second
/// tap on the same button while an outcome is already resolved. Rejecting
/// these is how the engine honours spec 10 ("cannot submit the same action
/// multiple times").
class InvalidGameActionException implements Exception {
  const InvalidGameActionException(this.message);

  final String message;

  @override
  String toString() => 'InvalidGameActionException: $message';
}
/*
/// The rules of Tumbang Preso, with no UI and no hidden randomness.
///
/// Drive it with one command per step; each returns the [GameEvent]s that
/// resulted, and [state] always holds the current snapshot:
///
/// 1. [callCoinToss]
/// 2. [throwSlipper], then [respondToMiss] or [respondToHit] as the phase
///    says, repeating until the phase is tieBreaker or finished
/// 3. [submitTieBreakerHand] twice per round, Player 1 first
///
*/
// Start a new game by creating a new engine (spec open question 6).
class GameEngine {
  GameEngine({
    required Players players,
    this.config = const GameConfig(),
    RandomSource? random,
    GameState? initialState,
  }) : _random = random ?? DartRandomSource(),
       _state =
           initialState ??
           GameState(
             players: players,
             phase: GamePhase.coinToss,
             scores: const Scores(),
             captureAttemptsLeft: config.captureAttemptsPerStint,
           );

  final GameConfig config;
  final RandomSource _random;
  GameState _state;

  GameState get state => _state;

  /// Player 1 calls the coin; the engine flips it and sets the starting
  /// roles (spec 4).
  List<GameEvent> callCoinToss(CoinSide call) {
    _require(GamePhase.coinToss);
    final result = _random.flipCoin();
    final attacker = call == result ? PlayerId.one : PlayerId.two;
    _state = _state.copyWith(
      coinCall: call,
      coinResult: result,
      attacker: attacker,
      phase: GamePhase.awaitingThrow,
    );
    return [
      CoinTossed(
        call: call,
        result: result,
        attacker: attacker,
        taya: attacker.other,
      ),
    ];
  }

  /// The attacker throws. A hit scores immediately but the exchange stays
  /// open until the taya responds; a miss waits for the taya's choice unless
  /// no capture attempts are left (spec 5.1, 5.3).
  List<GameEvent> throwSlipper() {
    _require(GamePhase.awaitingThrow);
    final attacker = _state.attacker!;
    final hit = _random.roll(config.hitChance);
    final events = <GameEvent>[
      ThrowResolved(
        attacker: attacker,
        outcome: hit ? ThrowOutcome.hit : ThrowOutcome.miss,
      ),
    ];

    if (hit) {
      _award(
        attacker,
        config.knockdownPoints,
        ScoreReason.canKnockedDown,
        events,
      );
      _state = _state.copyWith(phase: GamePhase.awaitingHitResponse);
    } else if (_state.canAttemptCapture) {
      _state = _state.copyWith(phase: GamePhase.awaitingMissResponse);
    } else {
      events.add(CaptureUnavailable(taya: _state.taya!));
      _finishExchange(events);
    }
    return events;
  }

  /// The taya's choice after a miss (spec 5.1, 5.2). Only an actual capture
  /// attempt uses up one of the stint's attempts.
  List<GameEvent> respondToMiss(MissResponse response) {
    _require(GamePhase.awaitingMissResponse);
    final taya = _state.taya!;
    final events = <GameEvent>[MissResponded(taya: taya, response: response)];

    if (response == MissResponse.attemptCapture) {
      final success = _random.roll(config.captureChance);
      final attemptsLeft = _state.captureAttemptsLeft - 1;
      _state = _state.copyWith(captureAttemptsLeft: attemptsLeft);
      events.add(
        CaptureAttempted(
          taya: taya,
          success: success,
          attemptsLeft: attemptsLeft,
        ),
      );
      if (success) {
        _award(taya, config.capturePoints, ScoreReason.slipperCaptured, events);
      }
    }

    _finishExchange(events);
    return events;
  }

  /// The taya's choice after the can is knocked down (spec 5.3 to 5.5). The
  /// can is restored in every case.
  List<GameEvent> respondToHit(HitResponse response) {
    _require(GamePhase.awaitingHitResponse);
    final taya = _state.taya!;
    final events = <GameEvent>[HitResponded(taya: taya, response: response)];

    if (response == HitResponse.catchPlayer) {
      final success = _random.roll(config.catchChance);
      events.add(CatchAttempted(taya: taya, success: success));
      if (success) {
        _award(taya, config.catchPoints, ScoreReason.successfulCatch, events);
        _swapRoles(events);
      }
    }

    events.add(const CanRestored());
    _finishExchange(events);
    return events;
  }

  /// Locks in a Jack-en-Poy hand. Player 1 submits first, then Player 2; the
  /// round resolves when the second hand arrives. A draw starts a new round
  /// (spec 7.1; repeat-on-draw is PROVISIONAL, open question 3).
  List<GameEvent> submitTieBreakerHand(PlayerId player, Hand hand) {
    _require(GamePhase.tieBreaker);
    final tieBreaker = _state.tieBreaker!;
    if (player != tieBreaker.awaiting) {
      throw InvalidGameActionException(
        'Waiting for Player ${tieBreaker.awaiting.number}, '
        'not Player ${player.number}.',
      );
    }

    final events = <GameEvent>[TieBreakerHandLocked(player: player)];
    final firstHand = tieBreaker.firstHand;

    if (firstHand == null) {
      _state = _state.copyWith(
        tieBreaker: TieBreakerState(
          round: tieBreaker.round,
          awaiting: PlayerId.two,
          firstHand: hand,
        ),
      );
      return events;
    }

    final PlayerId? roundWinner = firstHand.beats(hand)
        ? PlayerId.one
        : hand.beats(firstHand)
        ? PlayerId.two
        : null;
    events.add(
      TieBreakerRoundResolved(
        round: tieBreaker.round,
        player1Hand: firstHand,
        player2Hand: hand,
        winner: roundWinner,
      ),
    );

    if (roundWinner == null) {
      _state = _state.copyWith(
        tieBreaker: TieBreakerState(round: tieBreaker.round + 1),
      );
    } else {
      _declareWinner(roundWinner, WinMethod.tieBreaker, events);
    }
    return events;
  }

  void _require(GamePhase expected) {
    if (_state.phase != expected) {
      throw InvalidGameActionException(
        'Expected phase ${expected.name} but the game is in '
        '${_state.phase.name}.',
      );
    }
  }

  void _award(
    PlayerId player,
    int points,
    ScoreReason reason,
    List<GameEvent> events,
  ) {
    _state = _state.copyWith(scores: _state.scores.add(player, points));
    events.add(PointsAwarded(player: player, points: points, reason: reason));
  }

  /// The taya becomes the attacker and the new taya gets a fresh set of
  /// capture attempts (spec 5.5).
  void _swapRoles(List<GameEvent> events) {
    final newAttacker = _state.taya!;
    _state = _state.copyWith(
      attacker: newAttacker,
      captureAttemptsLeft: config.captureAttemptsPerStint,
    );
    events.add(RolesSwapped(attacker: newAttacker, taya: newAttacker.other));
  }

  /// Runs once an exchange has fully resolved: continue, win, or tie-break.
  void _finishExchange(List<GameEvent> events) {
    switch (_state.scores.verdict(config.targetScore)) {
      case ScoreVerdict.keepPlaying:
        _state = _state.copyWith(phase: GamePhase.awaitingThrow);
      case ScoreVerdict.player1Wins:
        _declareWinner(PlayerId.one, WinMethod.reachedTarget, events);
      case ScoreVerdict.player2Wins:
        _declareWinner(PlayerId.two, WinMethod.reachedTarget, events);
      case ScoreVerdict.tieBreaker:
        _state = _state.copyWith(
          phase: GamePhase.tieBreaker,
          tieBreaker: const TieBreakerState(),
        );
        events.add(const TieBreakerStarted());
    }
  }

  void _declareWinner(
    PlayerId winner,
    WinMethod method,
    List<GameEvent> events,
  ) {
    _state = _state.copyWith(
      phase: GamePhase.finished,
      winner: winner,
      winMethod: method,
    );
    events.add(GameWon(winner: winner, method: method));
  }
}
