/// Where one exchange stands on the shared device.
///
/// The engine's `GamePhase` says what the *rules* are waiting for. This says
/// what the *device* is waiting for: who is holding it and what they may see.
/// It exists so the pass-the-device handoff (spec section 10) is a real state
/// the controller enforces, not something a screen can skip or bypass.
///
/// A normal exchange moves forward one step at a time:
///
/// ```text
/// throwing -> throwResult -> handoff -> privateChoice -> responseResult
///     ^            |                                          |
///     +------------+ (miss, no capture attempts left)         |
///     +-------------------------------------------------------+
/// ```
enum TurnStep {
  /// The attacker is about to throw (engine phase: awaitingThrow).
  throwing,

  /// The throw has resolved and the attacker's device shows the outcome.
  /// Both players may look at this.
  throwResult,

  /// The device is being passed to the taya. The screen shows only who to
  /// pass to; nothing about the choice, so it is safe for the attacker to
  /// see. The taya confirms they are holding it to move on.
  handoff,

  /// The taya holds the device and makes the private choice. Only now may the
  /// choice buttons exist; the engine's response commands are rejected in
  /// every other step.
  privateChoice,

  /// The taya's choice has resolved and the result is shown to both players.
  responseResult,
}