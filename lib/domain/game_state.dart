import 'package:game_tumbang_preso/domain/enums.dart';
import 'package:game_tumbang_preso/domain/players.dart';
import 'package:game_tumbang_preso/domain/scores.dart';

/// Progress of a Jack-en-Poy tie-breaker (spec 7.1).
class TieBreakerState {
  const TieBreakerState({
    this.round = 1,
    this.awaiting = PlayerId.one,
    this.firstHand,
  });

  /// Starts at 1 and goes up after every draw.
  final int round;

  /// Whose private hand the engine is waiting for. Player 1 goes first.
  final PlayerId awaiting;

  /// Player 1's locked hand while Player 2 chooses.
  ///
  /// PRIVATE: never render this before both hands are in.
  final Hand? firstHand;
}

/// An immutable snapshot of the whole game. The UI renders from this and
/// never changes it directly.
class GameState {
  const GameState({
    required this.players,
    required this.phase,
    required this.scores,
    required this.captureAttemptsLeft,
    this.attacker,
    this.coinCall,
    this.coinResult,
    this.tieBreaker,
    this.winner,
    this.winMethod,
  });

  final Players players;
  final GamePhase phase;
  final Scores scores;

  /// Null until the coin toss has been resolved.
  final PlayerId? attacker;

  /// Capture attempts the current taya has left in this stint (spec 5.2).
  final int captureAttemptsLeft;

  /// Player 1's call and the flip result, kept to show on the toss screen.
  final CoinSide? coinCall;
  final CoinSide? coinResult;

  /// Set once a tie-breaker starts.
  final TieBreakerState? tieBreaker;

  final PlayerId? winner;
  final WinMethod? winMethod;

  PlayerId? get taya => attacker?.other;

  /// True while the can is lying down, between a hit and its response.
  bool get canIsDown => phase == GamePhase.awaitingHitResponse;

  bool get canAttemptCapture => captureAttemptsLeft > 0;

  bool get isFinished => phase == GamePhase.finished;

  String nameOf(PlayerId id) => players.of(id).name;

  GameState copyWith({
    GamePhase? phase,
    Scores? scores,
    PlayerId? attacker,
    int? captureAttemptsLeft,
    CoinSide? coinCall,
    CoinSide? coinResult,
    TieBreakerState? tieBreaker,
    PlayerId? winner,
    WinMethod? winMethod,
  }) {
    return GameState(
      players: players,
      phase: phase ?? this.phase,
      scores: scores ?? this.scores,
      captureAttemptsLeft: captureAttemptsLeft ?? this.captureAttemptsLeft,
      attacker: attacker ?? this.attacker,
      coinCall: coinCall ?? this.coinCall,
      coinResult: coinResult ?? this.coinResult,
      tieBreaker: tieBreaker ?? this.tieBreaker,
      winner: winner ?? this.winner,
      winMethod: winMethod ?? this.winMethod,
    );
  }
}
