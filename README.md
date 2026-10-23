# Tumbang Preso

A digital adaptation of **Tumbang Preso**, a traditional Filipino street game, built with **Flutter** and **Dart**.

The project is being developed as a two-player game on a shared device. The initial target is the web browser, with Android as a possible future platform.

## Project Status

🚧 **In development** — gameplay rules and application structure are being planned before implementation.

The first version will focus on the core game loop, scoring, role changes, and shared-device interactions. It will use simplified randomized outcomes rather than aiming controls or throwing physics.

## Planned Features

- Two-player setup with player names and fixed Player 1 / Player 2 identities
- Randomized opening coin toss to determine the initial attacker and *taya*
- Throw outcomes: hit or miss
- Scoring for knocking down the can, catching the attacker, and capturing the slipper
- A limit of three slipper-capture attempts per stint as *taya*
- Automatic can restoration at the appropriate points in the game
- A first-to-10-points winning condition
- Jack-en-Poy (Rock-Paper-Scissors) tie-breaker
- Pass-the-device screens for private player choices
- Responsive layout for desktop and mobile browsers

These features are planned and may change as the game rules are finalized.

## Technology

- [Flutter](https://flutter.dev/) — UI framework
- [Dart](https://dart.dev/) — programming language

Flutter includes a Dart SDK, so use the Dart version bundled with the installed Flutter SDK. Check the installed versions with:

```bash
flutter --version
dart --version
flutter doctor
```

## Getting Started

### Prerequisites

Install Flutter and ensure the Flutter SDK is available on your `PATH`. Follow the official [Flutter installation guide](https://docs.flutter.dev/get-started/install).

### Run the project

Clone this repository, enter the project directory, and fetch dependencies:

```bash
git clone <repository-url>
cd game_tumbang_preso
flutter pub get
```

Run the web version:

```bash
flutter run -d web-server
```

Flutter will print a local URL in the terminal. Open that URL in your browser. The `web-server` device is useful when you want to open the app in a browser yourself instead of having Flutter launch Chrome automatically.

To build the web version:

```bash
flutter build web
```

The build output is written to `build/web/`.

> **Note:** This repository was initialized with `flutter create --empty game_tumbang_preso`. The app is still at the planning stage, so gameplay screens and mechanics may not be implemented yet.

## Game Rules

The game is designed for two players sharing one device:

- Player identities remain fixed, while the attacker and *taya* roles can switch during play.
- Knocking down the can awards the attacker **1 point**.
- A successful catch awards the *taya* **2 points** and changes the roles.
- A successful slipper capture after a missed throw awards the *taya* **1 point**.
- The *taya* has up to **three slipper-capture attempts per stint in that role**. Choosing not to attempt a capture does not use an attempt.
- The first player to reach **10 points** wins, subject to the agreed tie-breaker rules.

Refer to the game specification for the full rules, screen flow, and decisions still awaiting confirmation.

## Documentation

- [`docs/GAME_RULES_AND_MECHANICS.md`](docs/GAME_RULES_AND_MECHANICS.md) — current game rules, scoring, gameplay flow, technical direction, and open questions.

## Development Principles

- Finalize gameplay rules before implementing them.
- Keep game logic separate from presentation where practical.
- Prefer small, testable changes.
- Test scoring, role changes, random outcomes, and winning conditions as the implementation grows.
- Keep the first version focused on local two-player gameplay; online multiplayer and tournament features are outside the initial scope.

## Contributing

This project is currently being developed as a personal learning project. Suggestions and improvements are welcome as the scope evolves.

## License

No license has been selected yet. Unless a license is added to this repository, reuse and redistribution are not expressly granted.