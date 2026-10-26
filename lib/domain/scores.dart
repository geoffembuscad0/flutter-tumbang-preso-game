import 'package:game_tumbang_preso/domain/enums.dart';

/// Immutable cumulative scores for the whole game (spec 6).
class Scores {
  const Scores([this.one = 0, this.two = 0]);

  final int one;
  final int two;

  int of(PlayerId id) => id == PlayerId.one ? one : two;

  Scores add(PlayerId id, int points) => id == PlayerId.one
      ? Scores(one + points, two)
      : Scores(one, two + points);

  /// Applies the winning rule from spec 7. Call it only after an exchange
  /// has fully resolved.
  ///
  /// Both players at or above [target] means Jack-en-Poy, even when the
  /// scores differ (PROVISIONAL: spec open question 4).
  ScoreVerdict verdict(int target) {
    final oneReached = one >= target;
    final twoReached = two >= target;
    if (oneReached && twoReached) return ScoreVerdict.tieBreaker;
    if (oneReached) return ScoreVerdict.player1Wins;
    if (twoReached) return ScoreVerdict.player2Wins;
    return ScoreVerdict.keepPlaying;
  }

  @override
  bool operator ==(Object other) =>
      other is Scores && other.one == one && other.two == two;

  @override
  int get hashCode => Object.hash(one, two);

  @override
  String toString() => 'Scores($one-$two)';
}
