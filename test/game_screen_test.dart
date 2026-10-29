import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_tumbang_preso/core/app_theme.dart';
import 'package:game_tumbang_preso/domain/domain.dart';
import 'package:game_tumbang_preso/state/game_controller.dart';
import 'package:game_tumbang_preso/ui/game/game_screen.dart';

import 'support/scripted_random_source.dart';

final _players = Players.fromSetup(
  firstName: 'Ana',
  firstChoice: PlayerId.one,
  secondName: 'Ben',
);

// A game that is past the coin toss, with Player 1 attacking.
GameController _startedGame({List<bool> rolls = const []}) {
  final controller = GameController.newGame(
    players: _players,
    random: ScriptedRandomSource(coins: [CoinSide.heads], rolls: rolls),
  );
  controller.callCoinToss(CoinSide.heads);
  return controller;
}

// A game dropped straight into [phase], for the screens at the end of a game.
GameController _gameAt(
  GamePhase phase, {
  Scores scores = const Scores(),
  TieBreakerState? tieBreaker,
  PlayerId? winner,
}) {
  return GameController(
    GameEngine(
      players: _players,
      initialState: GameState(
        players: _players,
        phase: phase,
        scores: scores,
        attacker: PlayerId.one,
        captureAttemptsLeft: 3,
        tieBreaker: tieBreaker,
        winner: winner,
        winMethod: winner == null ? null : WinMethod.reachedTarget,
      ),
    ),
  );
}

Future<void> _pumpGame(WidgetTester tester, GameController controller) {
  return tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: GameScreen(controller: controller),
    ),
  );
}

String _score(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(Key(key))).data!;

void main() {
  testWidgets('shows names, roles, scores, target and capture attempts', (
    tester,
  ) async {
    await _pumpGame(tester, _startedGame());

    expect(find.text('Game on'), findsOneWidget);
    expect(find.text('First to 10 points wins.'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Ben'), findsOneWidget);
    expect(find.text('Attacker'), findsOneWidget);
    expect(find.text('Taya'), findsOneWidget);
    expect(_score(tester, 'score-one'), '0');
    expect(_score(tester, 'score-two'), '0');
    expect(find.text('Ana’s throw'), findsOneWidget);
    expect(find.text('Ben’s capture attempts left: 3'), findsOneWidget);
  });

  testWidgets('rebuilds when the controller notifies', (tester) async {
    final controller = _startedGame(rolls: [true]);
    await _pumpGame(tester, controller);
    expect(_score(tester, 'score-one'), '0');

    controller.throwSlipper(); // a hit: +1 for the attacker
    await tester.pump();

    expect(_score(tester, 'score-one'), '1');
    expect(find.text('Hit!'), findsOneWidget);
    expect(find.byKey(const Key('pass-device')), findsOneWidget);
  });

  testWidgets('follows the controller through the handoff on its own', (
    tester,
  ) async {
    final controller = _startedGame(rolls: [true]);
    await _pumpGame(tester, controller);

    controller.throwSlipper();
    controller.continueFromThrow();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Pass the device to Ben'), findsOneWidget);
    expect(find.byKey(const Key('guard-can')), findsNothing);

    controller.confirmHandoff();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('guard-can')), findsOneWidget);
  });

  testWidgets('shows the Jack-en-Poy placeholder when both reach the target', (
    tester,
  ) async {
    await _pumpGame(
      tester,
      _gameAt(
        GamePhase.tieBreaker,
        scores: const Scores(10, 10),
        tieBreaker: const TieBreakerState(),
      ),
    );

    expect(find.text('Jack-en-Poy'), findsOneWidget);
  });

  testWidgets('shows the winner when the game is finished', (tester) async {
    await _pumpGame(
      tester,
      _gameAt(
        GamePhase.finished,
        scores: const Scores(10, 4),
        winner: PlayerId.one,
      ),
    );

    expect(find.text('Ana wins!'), findsOneWidget);
  });
}