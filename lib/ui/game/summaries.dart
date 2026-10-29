import 'package:game_tumbang_preso/domain/domain.dart';

/// Plain-language description of what just happened, built from engine
/// events so the screens never re-derive outcomes from state changes.
class OutcomeSummary {
  const OutcomeSummary({required this.headline, this.details = const []});

  final String headline;
  final List<String> details;
}

String _points(int n) => n == 1 ? '1 point' : '$n points';

String _attempts(int left) {
  if (left <= 0) return 'No capture attempts left.';
  return '$left capture attempt${left == 1 ? '' : 's'} left.';
}

/// Describes a resolved throw (spec 5.1 and 5.3).
OutcomeSummary summarizeThrow(List<GameEvent> events, Players players) {
  ThrowResolved? thrown;
  PointsAwarded? award;
  CaptureUnavailable? unavailable;
  for (final event in events) {
    if (event is ThrowResolved) thrown = event;
    if (event is PointsAwarded) award = event;
    if (event is CaptureUnavailable) unavailable = event;
  }
  if (thrown == null) {
    throw StateError('The events contain no resolved throw.');
  }

  final attacker = players.of(thrown.attacker).name;
  final taya = players.of(thrown.attacker.other).name;

  if (thrown.outcome == ThrowOutcome.hit) {
    return OutcomeSummary(
      headline: 'Hit!',
      details: [
        'The can is down. $attacker scores ${_points(award?.points ?? 0)}.',
      ],
    );
  }
  return OutcomeSummary(
    headline: 'Missed!',
    details: [
      'The can is still standing.',
      if (unavailable != null)
        '$taya has no capture attempts left, so $attacker throws again.',
    ],
  );
}

/// Describes the taya's resolved choice and any end-of-exchange result
/// (spec 5.1 to 5.5 and 7).
OutcomeSummary summarizeResponse(
  List<GameEvent> events,
  Players players,
  int targetScore,
) {
  MissResponded? missResponse;
  CaptureAttempted? capture;
  HitResponded? hitResponse;
  CatchAttempted? catchAttempt;
  RolesSwapped? swap;
  PointsAwarded? award;
  GameWon? won;
  var tieBreakerStarted = false;
  for (final event in events) {
    if (event is MissResponded) missResponse = event;
    if (event is CaptureAttempted) capture = event;
    if (event is HitResponded) hitResponse = event;
    if (event is CatchAttempted) catchAttempt = event;
    if (event is RolesSwapped) swap = event;
    if (event is PointsAwarded) award = event;
    if (event is GameWon) won = event;
    if (event is TieBreakerStarted) tieBreakerStarted = true;
  }

  late final String headline;
  final details = <String>[];

  if (missResponse != null) {
    final taya = players.of(missResponse.taya).name;
    final attacker = players.of(missResponse.taya.other).name;
    if (missResponse.response == MissResponse.allowNextThrow) {
      headline = 'Next throw';
      details.add('$taya lets $attacker throw again.');
    } else if (capture != null && capture.success) {
      headline = 'Slipper captured!';
      details.add('$taya scores ${_points(award?.points ?? 0)}.');
      details.add(_attempts(capture.attemptsLeft));
    } else {
      headline = 'Capture failed.';
      details.add('No points this time.');
      details.add(_attempts(capture?.attemptsLeft ?? 0));
    }
  } else if (hitResponse != null) {
    final taya = players.of(hitResponse.taya).name;
    final attacker = players.of(hitResponse.taya.other).name;
    if (hitResponse.response == HitResponse.guardCan) {
      headline = 'Can guarded.';
      details.add('$taya puts the can back up.');
      details.add('$attacker gets the slipper back safely.');
    } else if (catchAttempt != null && catchAttempt.success) {
      headline = 'Caught!';
      details.add(
        '$taya catches $attacker and scores ${_points(award?.points ?? 0)}.',
      );
      if (swap != null) {
        details.add(
          '${players.of(swap.attacker).name} is the attacker now, and '
          '${players.of(swap.taya).name} is the taya.',
        );
      }
    } else {
      headline = 'Got away!';
      details.add('$attacker escapes. No catch points.');
      details.add('The can is back up.');
    }
  } else {
    throw StateError('The events contain no response from the taya.');
  }

  if (won != null) {
    details.add('${players.of(won.winner).name} wins the game!');
  } else if (tieBreakerStarted) {
    details.add(
      'Both players reached $targetScore, so Jack-en-Poy decides the winner.',
    );
  }

  return OutcomeSummary(headline: headline, details: details);
}