# Tumbang Preso

A Flutter-based digital adaptation of **Tumbang Preso**, a traditional Filipino outdoor game. This project brings the familiar gameplay into a simple, interactive experience designed for two players sharing a single device.

The game is developed using Flutter and Dart, with an emphasis on maintainable architecture, clearly defined game mechanics, private player interactions, and a playful user interface.

> **Development status:** In progress. The foundational game engine, main gameplay flow, player interactions, Jack-en-Poy tie-breaker, and victory screen have been implemented. Testing, refinement, and UI polish are ongoing.

---

## Table of Contents

- [Project Overview](#project-overview)
- [Technology Stack](#technology-stack)
- [Current Progress](#current-progress)
- [Gameplay Flow](#gameplay-flow)
- [Game Mechanics](#game-mechanics)
- [Jack-en-Poy Tie-Breaker](#jack-en-poy-tie-breaker)
- [Project Structure](#project-structure)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
- [Development Commands](#development-commands)
- [Testing and Quality Checks](#testing-and-quality-checks)
- [Development Roadmap](#development-roadmap)
- [Contributing](#contributing)
- [License](#license)

---

## Project Overview

Tumbang Preso is a digital interpretation of the traditional Filipino game in which players take turns throwing a slipper toward a target.

This version is designed around a turn-based, two-player experience. Players take on different roles during an exchange, and the game tracks their scores, available actions, and progress toward the winning condition.

The application uses a shared-device interaction model. When a player needs to make a private decision, the interface presents a pass-the-device handoff before allowing the next player to interact.

The project separates game rules, application state management, and UI presentation so that gameplay behavior can be tested independently of screen design.

## Technology Stack

| Technology | Purpose |
|---|---|
| Flutter 3.47 | Cross-platform application framework |
| Dart 3.13 | Primary programming language |
| Material and custom Flutter widgets | User interface components |
| ChangeNotifier | Application state notification |
| Dart unit tests | Domain and game logic testing |
| Flutter widget tests | UI behavior and interaction testing |

The project uses Flutter and Dart directly rather than Angular with Capacitor.

**Version note:** The project targets the Dart SDK version specified in `pubspec.yaml`. Ensure your installed Flutter SDK provides a compatible Dart version.

## Current Progress

The project has progressed beyond the initial Flutter scaffold. Its current implementation includes the domain engine, state management, gameplay screens, player interactions, and end-of-game presentation.

### Implemented Features

- **Welcome screen:** Provides the initial entry point and access to the game's instructions.
- **How to Play:** Presents the game instructions through an in-app dialog.
- **Player setup:** Allows players to enter their names, with validation for empty and duplicate names.
- **Coin toss:** Determines which player starts as the attacker.
- **Game state management:** Tracks the current game phase, player roles, scores, and available actions.
- **Game engine:** Handles gameplay rules, validates player actions, and coordinates game events.
- **Throwing gameplay:** Supports the slipper-throwing flow and the resolution of hit-or-miss outcomes.
- **Private player interactions:** Uses pass-the-device screens to prevent one player from seeing another player's private choices.
- **Turn management:** Coordinates the sequence of gameplay actions and player role changes.
- **Scoring system:** Tracks points and evaluates the game's winning conditions.
- **Jack-en-Poy tie-breaker:** Provides a rock-paper-scissors sequence when a tie-breaker is required.
- **Victory screen:** Displays the winner, final scores, and the method of victory.
- **New Game flow:** Allows players to return to player setup and begin another match.
- **Reusable UI components:** Uses shared visual components and styling for a consistent interface.

### Testing Progress

The project includes automated tests for the domain engine, controller behavior, and important UI interactions.

Dedicated Jack-en-Poy widget tests are being added to verify:

- Player handoff sequencing.
- Private hand selection.
- Prevention of premature hand reveals.
- Round resolution and hand reveals.
- Draw handling and subsequent rounds.
- Final winner presentation.
- Victory screen interactions.

The latest reported `flutter analyze` run completed without errors. The full test suite still needs to be executed and verified.

## Gameplay Flow

The intended gameplay sequence is:

1. **Welcome:** Players enter the game through the welcome screen.
2. **Player setup:** Both players enter their names.
3. **Coin toss:** The starting attacker is determined.
4. **Throw the slipper:** The attacker performs a throw.
5. **Reveal the outcome:** The game presents whether the throw hits or misses.
6. **Respond to the outcome:** The appropriate gameplay action is presented to the current player.
7. **Pass the device privately:** When a player must make a private choice, the game displays a handoff screen.
8. **Resolve the exchange:** The engine applies the appropriate scoring, remaining attempts, and role changes.
9. **Check the winning condition:** The game determines whether another exchange is needed or the match has ended.
10. **Resolve a tie-breaker:** If both players meet the target score, the game proceeds to Jack-en-Poy.
11. **Present the winner:** The victory screen displays the winner and final scores.
12. **Play again:** Players can start another match through the New Game action.

## Game Mechanics

The game engine is designed around explicit game phases and validated player actions.

### Player Roles

Players have stable identities, while their gameplay roles can change during the match.

- **Attacker:** The player who throws the slipper.
- **Taya:** The player responsible for the target and the applicable response after a throw.

The roles may change as a result of gameplay, depending on the rules implemented by the game engine.

### Throw Outcomes

A throw resolves into one of two outcomes:

- **Hit:** The target is hit, and the game proceeds to the appropriate response phase.
- **Miss:** The target is not hit, and the taya may be given an opportunity to attempt a capture if the rules and remaining attempts allow it.

The outcome is determined by the game logic, not by the animation or presentation layer.

### Scoring and Winning Conditions

The current configuration provides the following starting values:

| Setting | Current default |
|---|---:|
| Target score | 10 points |
| Knockdown points | 1 point |
| Catch points | 2 points |
| Capture points | 1 point |
| Capture attempts per stint | 3 |
| Hit chance | 50% — provisional |
| Capture chance | 50% — provisional |
| Catch chance | 50% — provisional |

These are implementation defaults, not necessarily final rules. The probabilities and scoring values may change as the game is reviewed and tested.

The game checks the players' scores against the configured target score. When both players meet or exceed the target score, the game proceeds to a tie-breaker instead of immediately declaring a winner.

## Jack-en-Poy Tie-Breaker

Jack-en-Poy is the game's tie-breaking mechanic, based on the familiar rock-paper-scissors game.

It is used when both players meet or exceed the target score.

### How It Works

1. Player 1 receives the device and privately selects Rock, Paper, or Scissors.
2. The game locks Player 1's selection without revealing it.
3. The device is handed to Player 2.
4. Player 2 privately selects Rock, Paper, or Scissors.
5. Once both selections have been submitted, the game reveals both hands.
6. The winner is determined using the standard rock-paper-scissors rules.
7. If both players select the same hand, the round is declared a draw and another round begins.
8. The process repeats until a winner is determined.

### Privacy and Interaction

The tie-breaker uses separate interaction stages:

- **First handoff:** Prepares the device for Player 1.
- **First selection:** Allows Player 1 to make a private choice.
- **Second handoff:** Transfers the device to Player 2.
- **Second selection:** Allows Player 2 to make a private choice.
- **Round result:** Reveals both selections and presents the round outcome.

The first player's selection remains hidden while the second player is making a choice. Both hands are revealed only after the second player submits their selection.

The game controller manages these transitions to ensure that the expected player is the only one allowed to submit a selection at each stage.

## Project Structure

The codebase separates domain logic, application state management, and UI presentation.

```text
lib/
├── core/
│   └── app_theme.dart
│
├── domain/
│   ├── game_engine.dart
│   ├── game_state.dart
│   ├── game_config.dart
│   ├── game_event.dart
│   ├── players.dart
│   ├── scores.dart
│   ├── enums.dart
│   └── random_source.dart
│
├── state/
│   ├── game_controller.dart
│   ├── turn_step.dart
│   └── tie_breaker_step.dart
│
├── ui/
│   ├── setup/
│   ├── coin_toss/
│   ├── game/
│   │   ├── stages/
│   │   └── widgets/
│   └── widgets/
│
└── main.dart

test/
├── domain/
├── state/
├── ui/
├── game_screen_test.dart
├── throw_flow_test.dart
└── welcome_screen_test.dart
```

The tree is a high-level overview. Individual files and additional test files may be added as development continues.

## Architecture

The project follows a separation of responsibilities between three main areas.

### Domain Layer

The domain layer contains the core game rules and state.

Its responsibilities include:

- Maintaining the game state.
- Validating gameplay actions.
- Applying scoring rules.
- Determining game outcomes.
- Managing game phases and events.
- Resolving tie-breaker selections.

The domain layer should remain independent of Flutter UI widgets.

### State Layer

The state layer coordinates the interaction between the domain engine and the presentation layer.

The `GameController`:

- Delegates gameplay operations to the game engine.
- Exposes the current game state.
- Coordinates player interaction steps.
- Manages pass-the-device transitions.
- Notifies the UI when the state changes.

The controller manages application interaction flow without owning the actual game rules.

### UI Layer

The UI layer is responsible for presenting game information and collecting player input.

It includes:

- Welcome and player setup screens.
- Coin-toss presentation.
- Gameplay stages.
- Jack-en-Poy stages.
- Victory presentation.
- Reusable widgets and visual components.

Widgets should communicate gameplay actions through the controller rather than implementing game rules directly.

### Architectural Principles

- Keep game rules and scoring in the domain layer.
- Keep widgets responsible for displaying state and collecting player input.
- Route gameplay actions through the game controller and engine.
- Use explicit game phases to determine which actions are currently valid.
- Inject randomness so that game outcomes can be tested deterministically.
- Keep private player choices hidden during pass-the-device interactions.
- Avoid allowing animation timing to determine actual gameplay results.
- Keep navigation and presentation responsibilities separate from game rules.

## Getting Started

### Prerequisites

Install a compatible Flutter SDK and ensure the Flutter and Dart command-line tools are available.

Verify your environment:

```bash
flutter --version
dart --version
flutter doctor
```

### Get the Source Code

Clone the repository and enter the project directory:

```bash
git clone https://github.com/geoffembuscad0/flutter-tumbang-preso-game.git
cd flutter-tumbang-preso-game
```

### Install Dependencies

```bash
flutter pub get
```

### Run the Application

Choose a supported device or browser, then run:

```bash
flutter devices
flutter run
```

For a web run, if web support is configured in your Flutter environment:

```bash
flutter run -d chrome
```

The available targets depend on your local Flutter installation and project configuration.

## Development Commands

Use the following commands during development:

| Command | Purpose |
|---|---|
| `flutter pub get` | Resolve project dependencies |
| `dart format lib test` | Format Dart source and test files |
| `flutter analyze` | Check for static analysis issues |
| `flutter test` | Run the complete automated test suite |
| `flutter test test/ui/tie_breaker_stages_test.dart` | Run the Jack-en-Poy widget tests |
| `flutter run` | Run the application on a selected device |
| `flutter build web` | Build the web version, if web support is configured |

## Testing and Quality Checks

Testing is important because the game has several phase-dependent actions, private player interactions, and branching outcomes.

The project uses:

- **Unit tests** to verify domain rules and game-engine behavior.
- **Controller tests** to verify state transitions and interaction sequencing.
- **Widget tests** to verify UI behavior and player interactions.

### Recommended Test Coverage

- Coin-toss role assignment.
- Valid and invalid actions for each game phase.
- Hit and miss outcomes.
- Capture attempts and exhaustion of available attempts.
- Successful catches and role changes.
- Score updates and winning conditions.
- Tie-breaker hand submission and resolution.
- Correct sequencing of events and state transitions.
- Private-choice interactions that do not reveal a player's selection prematurely.
- Draw handling in Jack-en-Poy.
- Final winner presentation.
- New-game navigation and initialization.

Use the injected `RandomSource` to control random outcomes in unit tests rather than relying on unpredictable random values.

### Quality Checks

Before considering a feature complete, run:

```bash
dart format lib test
flutter analyze
flutter test
```

A clean static analysis result does not guarantee that all automated tests pass. Both analysis and test execution should be verified.

## Development Roadmap

### Phase 1 — Foundation

- [x] Initialize the Flutter project.
- [x] Establish the initial domain model and game phases.
- [x] Implement foundational game-engine actions and scoring.
- [x] Add the welcome screen.
- [x] Add player setup and validation.
- [x] Add the coin-toss screen.
- [x] Establish reusable UI components.
- [x] Implement the game controller.

### Phase 2 — Core Gameplay

- [x] Implement the main throwing gameplay flow.
- [x] Connect throw actions to the game engine.
- [x] Resolve and reveal hit-or-miss outcomes.
- [x] Implement private player interactions.
- [x] Add pass-the-device handoff screens.
- [x] Connect gameplay actions to phase-specific state transitions.
- [x] Implement score changes and role changes.

### Phase 3 — Complete the Match

- [x] Implement the Jack-en-Poy tie-breaker flow.
- [x] Implement private hand selection.
- [x] Implement draw handling and repeated rounds.
- [x] Reveal both hands after submission.
- [x] Implement the victory screen.
- [x] Display the final winner and scores.
- [x] Add the New Game action and return-to-setup flow.

### Phase 4 — Quality and Polish

- [x] Establish domain unit tests.
- [x] Add controller tests.
- [x] Add initial gameplay widget tests.
- [x] Add dedicated Jack-en-Poy widget tests.
- [ ] Run and verify the complete automated test suite.
- [ ] Expand test coverage for remaining gameplay edge cases.
- [ ] Check responsive layouts on supported screen sizes.
- [ ] Review accessibility and reduced-motion behavior.
- [ ] Verify the application on intended target platforms.
- [ ] Review and finalize configurable probabilities and scoring values.
- [ ] Keep the game rules specification synchronized with the implementation.

## Contributing

This project is being developed incrementally. Changes should preserve the separation between game logic and UI presentation.

When adding a gameplay feature:

1. Confirm the intended rule and its expected state transitions.
2. Implement or update the relevant domain logic.
3. Add deterministic tests for the behavior.
4. Connect the behavior to the appropriate screen and controller.
5. Verify the UI interaction.
6. Update the documentation when the implementation or rules change.

## License

No license information is specified here. Add a `LICENSE` file and update this section once the project's licensing terms have been decided.