# Tumbang Preso

A Flutter-based digital adaptation of **Tumbang Preso**, a traditional Filipino outdoor game. The project aims to bring the familiar gameplay into a simple, interactive experience for players sharing a device.

The game is being developed with Flutter and Dart, with an emphasis on clear game rules, a maintainable codebase, and a playful user interface.

> **Development status:** In progress. Core game logic and initial screens are under development. The main throwing gameplay and private pass-the-device interactions are not yet complete.

## Table of Contents

- [Project Overview](#project-overview)
- [Technology Stack](#technology-stack)
- [Current Progress](#current-progress)
- [Planned Gameplay Flow](#planned-gameplay-flow)
- [Game Mechanics](#game-mechanics)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Development Commands](#development-commands)
- [Testing and Quality Checks](#testing-and-quality-checks)
- [Development Roadmap](#development-roadmap)
- [Contributing](#contributing)

## Project Overview

Tumbang Preso is a digital interpretation of the traditional Filipino game in which players take turns throwing a slipper toward a target.

This version is designed around a turn-based, two-player experience. Players take on different roles during an exchange, and the game tracks their scores, available actions, and progress toward the winning condition.

The project separates game rules from the user interface so that gameplay can be tested and refined independently of screen design.

## Technology Stack

| Technology | Purpose |
|---|---|
| Flutter 3.47 | Cross-platform application framework |
| Dart 3.13 | Primary programming language |
| Material and custom Flutter widgets | User interface components |
| Dart unit and Flutter widget tests | Planned automated testing |

The project uses Flutter and Dart directly rather than Angular with Capacitor.

**Version note:** The project targets the Dart SDK version specified in `pubspec.yaml`. Ensure your installed Flutter SDK provides a compatible Dart version.

## Current Progress

The project has progressed beyond the initial empty Flutter scaffold. The current implementation includes foundational game logic, state management, and initial user-interface screens.

### Implemented foundations

- **Game state and phases:** The domain layer represents the current phase of a game and the state needed to manage an exchange.
- **Game engine:** A dedicated engine handles gameplay actions, validates actions against the current phase, and coordinates game events.
- **Scoring:** A scoring component evaluates scores and winning conditions.
- **Player setup:** Player names can be normalized and validated, including checks for empty names and duplicate names.
- **Random outcomes:** Randomness is abstracted behind a `RandomSource`, making deterministic gameplay tests possible.
- **Initial screens:** The project includes a welcome flow, player setup, and a coin-toss screen.
- **Reusable UI components:** Shared visual components and styling provide a foundation for a consistent game interface.
- **Controller layer:** The game controller delegates gameplay operations to the domain engine rather than owning the rules itself.

### In progress

- Main throwing screen and slipper-throw interaction.
- Hit-or-miss outcome reveal.
- Taya's private response and pass-the-device flow.
- Complete gameplay controls driven by the current game phase.
- End-of-game presentation and restart flow.
- Automated tests covering the game rules and important UI interactions.

The game logic and initial screens provide a foundation, but the complete end-to-end gameplay experience is not yet finished.

## Planned Gameplay Flow

The intended gameplay flow is:

1. **Welcome:** Start a new game.
2. **Player setup:** Enter and validate both players' names.
3. **Coin toss:** Determine which player starts as the attacker.
4. **Throw the slipper:** The attacker performs a throw.
5. **Reveal the outcome:** Show whether the throw hits or misses.
6. **Respond to the outcome:** Present the appropriate action for the current situation.
7. **Pass the device privately:** When the taya must make a private choice, transition to a screen that prevents the other player from seeing the choice.
8. **Resolve the exchange:** Apply the appropriate scoring, remaining attempts, and role changes.
9. **Check the winning condition:** Continue to another exchange or present the end-of-game screen.
10. **Play again:** Allow players to start a new game.

This flow is the intended direction of development. Some steps are still awaiting their corresponding gameplay screens and integration.

## Game Mechanics

The game engine is designed around explicit game phases and validated player actions.

### Player roles

Players have stable identities, while their gameplay roles can change during the match.

- **Attacker:** The player who throws the slipper.
- **Taya:** The player responsible for the target and the applicable response after a throw.

The roles may change as a result of gameplay, depending on the rules implemented by the game engine.

### Throw outcomes

A throw resolves into one of two outcomes:

- **Hit:** The target is hit, and the game proceeds to the appropriate response phase.
- **Miss:** The target is not hit, and the taya may be given an opportunity to attempt a capture if the rules and remaining attempts allow it.

The outcome is determined by the game logic, not by the animation or presentation layer.

### Provisional probabilities

The hit chance is currently configured at **50%** as a temporary development default.

This value is **not a finalized game-balance decision**. It will remain configurable while the gameplay screens are developed and tested.

Other probabilities, including capture and catch chances, are also configurable through the game configuration. Their final values and intended balance remain subject to review.

### Scoring and winning conditions

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

These are implementation defaults, not necessarily final rules. The rules and scoring values may change as the game is reviewed and tested.

The current scoring logic also includes a tie-breaker phase for a situation in which both players meet or exceed the target score. The precise winning and tie-breaker rules should be reviewed before the mechanics are considered final.

For the detailed rules specification, see `docs/GAME_RULES_AND_MECHANICS.md` if that document is present in your local repository. The specification should be kept synchronized with the actual game engine as decisions are finalized.

## Project Structure

The codebase separates the domain logic, application coordination, and presentation layer.

The following is a conceptual overview of the main areas; consult the current repository tree for the exact file layout.

```text
lib/
├── domain/
│   ├── game_engine.dart
│   ├── game_state.dart
│   ├── game_config.dart
│   ├── game_event.dart
│   ├── players.dart
│   ├── scores.dart
│   ├── enums.dart
│   └── random_source.dart
├── presentation/
│   └── screens and reusable UI components
└── application/
    └── game controller and application coordination

test/
└── automated tests (to be expanded)
```

The directory names above illustrate the architectural responsibilities; they are not intended to replace the actual repository layout.

### Architectural principles

- Keep game rules and scoring in the domain layer.
- Keep widgets responsible for displaying state and collecting player input.
- Route gameplay actions through the game controller and engine.
- Use explicit game phases to determine which actions are currently valid.
- Inject randomness so that game outcomes can be tested deterministically.
- Keep private player choices hidden during pass-the-device interactions.
- Avoid allowing animation timing to determine the actual gameplay result.

## Getting Started

### Prerequisites

Install a compatible Flutter SDK and ensure the Flutter and Dart command-line tools are available.

Verify your environment:

```bash
flutter --version
dart --version
flutter doctor
```

### Get the source code

Clone the repository and enter the project directory:

```bash
git clone https://github.com/geoffembuscad0/flutter-tumbang-preso-game.git
cd flutter-tumbang-preso-game
```

### Install dependencies

```bash
flutter pub get
```

### Run the application

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
| `flutter analyze` | Check for static analysis issues |
| `flutter test` | Run automated tests |
| `flutter run` | Run the application on a selected device |
| `flutter build web` | Build the web version, if web support is configured |

## Testing and Quality Checks

Testing is important because the game has several phase-dependent actions and branching outcomes.

The domain layer should be tested independently from the UI wherever possible.

Recommended test coverage includes:

- Coin-toss role assignment.
- Valid and invalid actions for each game phase.
- Hit and miss outcomes.
- Capture attempts and exhaustion of available attempts.
- Successful catches and role changes.
- Score updates and winning conditions.
- Tie-breaker hand submission and resolution.
- Correct sequencing of events and state transitions.
- New-game initialization and state reset.
- Private-choice interactions that do not reveal a player's selection prematurely.

Use the injected `RandomSource` to control random outcomes in unit tests rather than relying on unpredictable random values.

Before considering a feature complete, run:

```bash
flutter analyze
flutter test
```

The current repository status should be verified locally; this README does not claim that all tests or quality checks have already passed.

## Development Roadmap

### Phase 1 — Foundation

- [x] Initialize the Flutter project.
- [x] Establish the initial domain model and game phases.
- [x] Implement foundational game-engine actions and scoring.
- [x] Add initial welcome, player setup, and coin-toss screens.
- [x] Establish reusable UI components.

### Phase 2 — Core gameplay

- [ ] Implement the main throwing screen.
- [ ] Connect the throw action to the game engine.
- [ ] Reveal hit or miss outcomes.
- [ ] Implement the taya's private-choice screen.
- [ ] Add a clear pass-the-device handoff flow.
- [ ] Connect all gameplay actions to phase-specific state transitions.
- [ ] Verify score changes and role changes through tests.

### Phase 3 — Complete the match

- [ ] Implement the end-of-game screen.
- [ ] Finalize the tie-breaker rules.
- [ ] Implement a reliable new-game and restart flow.
- [ ] Review and finalize configurable probabilities and scoring values.

### Phase 4 — Quality and polish

- [ ] Expand domain unit-test coverage.
- [ ] Add widget tests for important gameplay interactions.
- [ ] Check responsive layouts on supported screen sizes.
- [ ] Review accessibility and reduced-motion behavior.
- [ ] Run static analysis and automated tests.
- [ ] Verify the application on the intended target platforms.
- [ ] Update the documentation to reflect finalized rules and implementation.

## Contributing

This project is being developed incrementally. Changes should preserve the separation between game logic and UI presentation.

When adding a gameplay feature:

1. Confirm the intended rule and its expected state transitions.
2. Implement or update the relevant domain logic.
3. Add deterministic tests for the behavior.
4. Connect the behavior to the appropriate screen and controller.
5. Verify the UI interaction and update the documentation.

## License

No license information is specified here. Add a `LICENSE` file and update this section once the project's licensing terms have been decided.