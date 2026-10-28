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
    expect(find.text('Ana throws next.'), findsOneWidget);
    expect(find.text('Ben’s capture attempts left: 3'), findsOneWidget);
  });

  testWidgets('rebuilds when the controller notifies', (tester) async {
    final controller = _startedGame(rolls: [true]);
    await _pumpGame(tester, controller);
    expect(_score(tester, 'score-one'), '0');

    controller.throwSlipper(); // a hit: +1 for the attacker
    await tester.pump();

    expect(_score(tester, 'score-one'), '1');
    expect(find.text('Ben responds next.'), findsOneWidget);
  });
}