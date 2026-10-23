# Tumbang Preso — Game Rules and Mechanics Specification

**Project:** `game_tumbang_preso`  
**Framework:** Flutter  
**Language:** Dart  
**Initial target:** Web browser  
**Potential future target:** Android  
**Document status:** Working specification — agreed rules are recorded; open questions are listed at the end.

## 1. Purpose and scope

This project is a simplified digital adaptation of the Filipino traditional game Tumbang Preso. It is designed for two players sharing one device. The first implementation focuses on the core game loop, scoring, role changes, and clear pass-the-device interactions.

The initial version does not include online multiplayer, accounts, matchmaking, or a tournament bracket. The game uses simplified random outcomes rather than simulated throwing physics or precise aiming.

## 2. Players and roles

There are exactly two players in a game:

- **Player 1**
- **Player 2**

Player identities remain fixed throughout the game. Gameplay roles change:

- **Attacker:** throws the slipper toward the can.
- **Taya:** responds to a missed throw by deciding whether to attempt a slipper capture, or responds after the can is knocked down by choosing between guarding the can and trying to catch the attacker.

The UI must clearly show each player's name, score, current role, and remaining slipper-capture attempts when relevant.

## 3. Player setup

1. The first participant enters a name and chooses either Player 1 or Player 2.
2. The second participant enters a name and is automatically assigned the remaining player identity.
3. Player numbers do not change after setup.
4. The game proceeds to the initial coin toss.

Validation for empty names and duplicate names should be handled by the UI. The exact validation behavior can be decided during implementation.

## 4. Initial coin toss

1. Player 1 privately chooses Heads or Tails.
2. The game randomly generates the coin result.
3. If Player 1's choice matches the result, Player 1 becomes the initial attacker and Player 2 becomes the initial taya.
4. If Player 1's choice does not match the result, Player 1 becomes the initial taya and Player 2 becomes the initial attacker.
5. The result and starting roles are displayed before gameplay begins.

## 5. Main gameplay loop

The attacker repeatedly throws the slipper. Each throw resolves through one of two paths: **Miss** or **Hit**. The first implementation uses randomized outcomes; it does not include aiming controls or physics simulation.

### 5.1 Miss path

1. The game randomly resolves the throw as a miss.
2. A pass-the-device screen prompts the taya to take the device. Private choices should not be revealed to the other player before both relevant players have made their selections.
3. The taya chooses:
   - **Attempt to Capture Slipper**, or
   - **Allow Next Throw**.
4. If the taya chooses to attempt a capture, the game randomly determines success or failure.
5. A successful capture awards the taya **+1 point**. A failed capture awards no points.
6. Every actual capture attempt consumes one of the taya's three capture attempts for the current role, regardless of success or failure.
7. Choosing **Allow Next Throw** does not consume a capture attempt.
8. The attacker recovers the slipper. Recovery itself awards no points.
9. The attacker may throw again. If the taya has used all three capture attempts for the current role, no further capture attempts are available until roles switch; the attacker can still keep throwing.

### 5.2 Slipper-capture limit

- The taya has a maximum of **three capture attempts per stint in the taya role**.
- Attempts are counted whether they succeed or fail.
- The counter is not reduced when the taya chooses **Allow Next Throw**.
- When the players switch roles, the new taya receives three capture attempts.
- The capture-attempt counter should be visible to the players when relevant.

### 5.3 Hit path: can knocked down

1. The game randomly resolves the throw as a hit.
2. The attacker receives **+1 point** for knocking down the can.
3. The attacker proceeds to retrieve the slipper.
4. The game presents a pass-the-device screen.
5. The taya chooses one response:
   - **Guard Can**
   - **Catch Player**
6. The game reveals and resolves the taya's choice.

The successful throw point is independent of what happens in the subsequent catch attempt. If the taya catches the attacker, the attacker keeps the point earned for knocking down the can.

### 5.4 Guard Can response

- The can is restored automatically to its upright position.
- The attacker retrieves the slipper safely.
- No additional points are awarded for this response.
- Roles do not change.
- The attacker may throw again.

### 5.5 Catch Player response

- The game randomly determines whether the taya successfully catches the attacker.
- **Successful catch:** the taya receives **+2 points**, the players switch roles, and the can is automatically restored to its upright position.
- **Failed catch:** no catch points are awarded; the attacker retrieves the slipper safely and remains the attacker.
- After a failed catch, the can must be restored before the next throw. This is the intended behavior for a consistent game loop.
- When roles switch, the new taya's slipper-capture counter resets to three.

## 6. Scoring

| Event | Player awarded points | Points |
|---|---|---:|
| Attacker knocks down the can | Attacker | +1 |
| Taya successfully catches the attacker | Taya | +2 |
| Taya successfully captures the slipper after a miss | Taya | +1 |
| Missed throw | Nobody | 0 |
| Failed slipper capture | Nobody | 0 |
| Failed catch | Nobody | 0 |
| Slipper recovery | Nobody | 0 |
| Guard Can response | Nobody beyond the earlier hit point | 0 additional |

Scores are cumulative for the whole game. The UI should show both scores clearly.

## 7. Winning condition and tie-breaker

- The target is **10 points**.
- The game checks the scores after the current gameplay exchange has fully resolved.
- If only one player has reached or exceeded 10 points, that player wins.
- If both players reach or exceed 10 points during the same exchange, the game proceeds to a Jack-en-Poy tie-breaker.
- If both players are at or above 10 after the exchange, the tie-breaker is used even if their scores are not numerically equal. This interpretation should be confirmed before implementation.

### 7.1 Jack-en-Poy tie-breaker

1. Player 1 privately selects Rock, Paper, or Scissors.
2. A pass-the-device screen lets Player 2 make a private selection.
3. Both selections are revealed simultaneously.
4. Standard Rock-Paper-Scissors rules determine the round winner.
5. If the round is a draw, repeat the selection process until one player wins.
6. The winner of Jack-en-Poy wins the game.

The repeat-on-draw behavior is the current proposed interpretation of the tie-breaker; confirm it before implementation if a strictly single-round tie-breaker is preferred.

## 8. Screen and interaction flow

1. **Welcome screen:** Play Game and How to Play.
2. **Player setup:** collect names and assign Player 1 / Player 2 identities.
3. **Coin toss:** Player 1 chooses Heads or Tails; reveal result and starting roles.
4. **Main game screen:** show can, slipper action, player names, scores, roles, and capture attempts remaining.
5. **Miss response / pass-the-device screen:** let the taya privately choose whether to attempt a capture or allow the next throw.
6. **Capture result:** reveal success or failure, apply any point, and return the slipper to the attacker.
7. **Hit response / pass-the-device screen:** let the taya privately choose Guard Can or Catch Player.
8. **Catch result:** reveal outcome, apply points, restore the can, and switch roles if caught.
9. **Score check:** after an exchange resolves, determine whether to continue, declare a winner, or begin Jack-en-Poy.
10. **Jack-en-Poy screens:** private selection for each player, reveal, and repeat on a draw.
11. **Victory screen:** display the winner and provide a way to start a new game.

## 9. Random outcomes

For the initial prototype:

- Throw outcome: randomly Hit or Miss.
- Slipper capture: randomly success or failure.
- Catch attempt: randomly success or failure.
- Coin toss: randomly Heads or Tails.
- Jack-en-Poy: each player selects Rock, Paper, or Scissors; the rules determine the outcome.

A **50% success chance** was proposed for slipper capture and catching the attacker. Treat those odds as provisional until confirmed. Throw hit/miss odds have not yet been specified.

Random outcome logic should be separated from UI code so it can be tested and adjusted later.

## 10. Shared-device privacy and usability

- Use a clear **Pass the Device** transition when a hidden choice is required.
- Do not show Player 1's or the taya's private selection to the other player before the other player has completed their selection.
- Reveal results only after all required choices are locked in.
- Use large, touch-friendly controls and a responsive layout for desktop and mobile browsers.
- Provide clear instructions and feedback for each outcome.
- Make it obvious whose turn or role it is.
- Ensure a player cannot submit the same action multiple times while an outcome is resolving.

## 11. Technical direction

- Build with Flutter and Dart.
- Develop the browser version first.
- Keep gameplay rules, score changes, role changes, and random outcome selection separated from presentation widgets where practical.
- Avoid adding online multiplayer or a tournament system to the initial scope.
- Verify the Flutter SDK's bundled Dart version with `flutter --version` before implementation; Flutter uses the Dart SDK bundled with the installed Flutter version.

## 12. Open questions to resolve before implementation

1. **Throw hit/miss probability:** Should a throw have a 50% chance to hit, or should we use another ratio?
2. **Capture and catch probabilities:** Confirm whether both actions should have a 50% success chance.
3. **Tie-breaker:** Should Jack-en-Poy repeat on a draw until someone wins, or must it be exactly one round?
4. **Winning threshold:** Confirm that if both players are at or above 10 points after the same exchange, Jack-en-Poy is used even when their scores are not equal.
5. **Name validation:** Decide how to handle blank names and duplicate player names.
6. **Game reset:** Decide whether starting a new game clears all scores and role state and returns to the welcome screen (recommended).

---

**Implementation rule:** If a mechanic is not explicitly confirmed in this document, treat it as provisional and ask before making a gameplay-changing assumption.
