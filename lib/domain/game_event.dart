import 'package:game_tumbang_preso/domain/enums.dart';

/// Something that happened while resolving a command. Every engine command
/// returns its events in order, so the UI can reveal results step by step
/// (spec 8) without re-deriving them from state changes.
sealed class GameEvent {
  const GameEvent();
}

final class CoinTossed extends GameEvent {
  const CoinTossed({
    required this.call,
    required this.result,
    required this.attacker,
    required this.taya,
  });

  final CoinSide call;
  final CoinSide result;
  final PlayerId attacker;
  final PlayerId taya;
}

final class ThrowResolved extends GameEvent {
  const ThrowResolved({required this.attacker, required this.outcome});

  final PlayerId attacker;
  final ThrowOutcome outcome;
}

final class PointsAwarded extends GameEvent {
  const PointsAwarded({
    required this.player,
    required this.points,
    required this.reason,
  });

  final PlayerId player;
  final int points;
  final ScoreReason reason;
}

final class MissResponded extends GameEvent {
  const MissResponded({required this.taya, required this.response});

  final PlayerId taya;
  final MissResponse response;
}

final class CaptureAttempted extends GameEvent {
  const CaptureAttempted({
    required this.taya,
    required this.success,
    required this.attemptsLeft,
  });

  final PlayerId taya;
  final bool success;
  final int attemptsLeft;
}

/// A throw missed but the taya has no capture attempts left, so the engine
/// skipped the miss-response step and the attacker may throw again.
final class CaptureUnavailable extends GameEvent {
  const CaptureUnavailable({required this.taya});

  final PlayerId taya;
}

final class HitResponded extends GameEvent {
  const HitResponded({required this.taya, required this.response});

  final PlayerId taya;
  final HitResponse response;
}

final class CatchAttempted extends GameEvent {
  const CatchAttempted({required this.taya, required this.success});

  final PlayerId taya;
  final bool success;
}

final class RolesSwapped extends GameEvent {
  const RolesSwapped({required this.attacker, required this.taya});

  /// The new roles after the swap.
  final PlayerId attacker;
  final PlayerId taya;
}

final class CanRestored extends GameEvent {
  const CanRestored();
}

final class TieBreakerStarted extends GameEvent {
  const TieBreakerStarted();
}

/// A hand was locked in. The hand itself is deliberately not included.
final class TieBreakerHandLocked extends GameEvent {
  const TieBreakerHandLocked({required this.player});

  final PlayerId player;
}

final class TieBreakerRoundResolved extends GameEvent {
  const TieBreakerRoundResolved({
    required this.round,
    required this.player1Hand,
    required this.player2Hand,
    required this.winner,
  });

  final int round;
  final Hand player1Hand;
  final Hand player2Hand;

  /// Null means a draw, and another round follows.
  final PlayerId? winner;
}

final class GameWon extends GameEvent {
  const GameWon({required this.winner, required this.method});

  final PlayerId winner;
  final WinMethod method;
}
