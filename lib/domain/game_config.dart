/// Every tunable rule value in one place.
///
/// Values marked PROVISIONAL are not yet confirmed in the specification
/// (sections 9 and 12). Change them here, never inside the engine.
class GameConfig {
  const GameConfig({
    this.targetScore = 10,
    this.hitChance = 0.5,
    this.captureChance = 0.5,
    this.catchChance = 0.5,
    this.captureAttemptsPerStint = 3,
    this.knockdownPoints = 1,
    this.catchPoints = 2,
    this.capturePoints = 1,
  }) : assert(targetScore > 0),
       assert(hitChance >= 0 && hitChance <= 1),
       assert(captureChance >= 0 && captureChance <= 1),
       assert(catchChance >= 0 && catchChance <= 1),
       assert(captureAttemptsPerStint >= 0);

  /// First player to reach this score wins (spec 7).
  final int targetScore;

  /// Chance a throw knocks the can down. PROVISIONAL: spec open question 1.
  final double hitChance;

  /// Chance a slipper-capture attempt succeeds. PROVISIONAL: question 2.
  final double captureChance;

  /// Chance a catch attempt succeeds. PROVISIONAL: question 2.
  final double catchChance;

  /// Capture attempts the taya gets per stint in that role (spec 5.2).
  final int captureAttemptsPerStint;

  /// Points to the attacker for knocking the can down (spec 6).
  final int knockdownPoints;

  /// Points to the taya for catching the attacker (spec 6).
  final int catchPoints;

  /// Points to the taya for capturing the slipper after a miss (spec 6).
  final int capturePoints;
}
