/// The two fixed player identities.
///
/// Identities never change during a game; only the roles
/// (attacker / taya) move between them.
enum PlayerId {
  one,
  two;

  PlayerId get other => this == PlayerId.one ? PlayerId.two : PlayerId.one;

  /// 1 or 2, for display ("Player 1").
  int get number => this == PlayerId.one ? 1 : 2;
}

enum CoinSide { heads, tails }

enum ThrowOutcome { hit, miss }

/// The taya's private choice after a missed throw (spec 5.1).
enum MissResponse { attemptCapture, allowNextThrow }

/// The taya's private choice after the can is knocked down (spec 5.3).
enum HitResponse { guardCan, catchPlayer }

/// Jack-en-Poy hands (spec 7.1).
enum Hand {
  rock,
  paper,
  scissors;

  bool beats(Hand other) => switch (this) {
    Hand.rock => other == Hand.scissors,
    Hand.paper => other == Hand.rock,
    Hand.scissors => other == Hand.paper,
  };
}

/// Where the game is waiting. The UI picks its screen from this.
enum GamePhase {
  /// Player 1 must call heads or tails.
  coinToss,

  /// The attacker is about to throw.
  awaitingThrow,

  /// A throw missed; the taya chooses to attempt a capture or not.
  awaitingMissResponse,

  /// The can is down; the taya chooses to guard or catch.
  awaitingHitResponse,

  /// Both players reached the target together; Jack-en-Poy is under way.
  tieBreaker,

  /// There is a winner.
  finished,
}

enum ScoreReason { canKnockedDown, successfulCatch, slipperCaptured }

enum WinMethod { reachedTarget, tieBreaker }

/// What the scores say once an exchange has fully resolved (spec 7).
enum ScoreVerdict { keepPlaying, player1Wins, player2Wins, tieBreaker }
