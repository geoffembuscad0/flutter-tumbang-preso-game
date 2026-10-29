import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_tumbang_preso/core/app_theme.dart';
import 'package:game_tumbang_preso/domain/domain.dart';
import 'package:game_tumbang_preso/state/game_controller.dart';
import 'package:game_tumbang_preso/ui/coin_toss/coin_toss_screen.dart';

import 'support/scripted_random_source.dart';

const _callHeads = Key('call-heads');
const _callTails = Key('call-tails');
const _startGame = Key('start-game');
const _attackerRow = Key('attacker-row');
const _tayaRow = Key('taya-row');

final _players = Players.fromSetup(
  firstName: 'Ana',
  firstChoice: PlayerId.one,
  secondName: 'Ben',
);

/// A controller whose coin will land on [flip].
GameController _controller(CoinSide flip) => GameController.newGame(
  players: _players,
  random: ScriptedRandomSource(coins: [flip]),
);

Future<void> _pumpToss(
  WidgetTester tester,
  GameController controller, {
  bool reduceMotion = false,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      builder: reduceMotion
          ? (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            )
          : null,
      home: CoinTossScreen(controller: controller),
    ),
  );
}

Future<void> _call(WidgetTester tester, Key button) async {
  await tester.ensureVisible(find.byKey(button));
  await tester.tap(find.byKey(button));
  await tester.pump();
}

/// Moves past the 1.8 second flip.
Future<void> _finishFlip(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pump();
}

Finder _inRow(Key row, String text) =>
    find.descendant(of: find.byKey(row), matching: find.text(text));

void main() {
  group('before the toss', () {
    testWidgets('asks Player 1 to call and lists both players', (tester) async {
      await _pumpToss(tester, _controller(CoinSide.heads));

      expect(find.text('Coin toss'), findsOneWidget);
      expect(find.text('Player 1: Ana'), findsOneWidget);
      expect(find.text('Player 2: Ben'), findsOneWidget);
      expect(find.text('Ana, call it!'), findsOneWidget);
      expect(find.byKey(_callHeads), findsOneWidget);
      expect(find.byKey(_callTails), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('does not touch the engine until a call is made', (
      tester,
    ) async {
      final controller = _controller(CoinSide.heads);
      await _pumpToss(tester, controller);

      expect(controller.state.phase, GamePhase.coinToss);
      expect(controller.state.attacker, isNull);
    });
  });

  group('the toss', () {
    testWidgets('holds the result back while the coin is flipping', (
      tester,
    ) async {
      final controller = _controller(CoinSide.heads);
      await _pumpToss(tester, controller);

      await _call(tester, _callHeads);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Flipping the coin…'), findsOneWidget);
      expect(find.text('It’s Heads!'), findsNothing);
      expect(find.byKey(_startGame), findsNothing);
      // The engine has already decided, but the screen has not shown it yet.
      expect(controller.state.attacker, PlayerId.one);
    });

    testWidgets('a matching call makes Player 1 the attacker', (tester) async {
      final controller = _controller(CoinSide.heads);
      await _pumpToss(tester, controller);

      await _call(tester, _callHeads);
      await _finishFlip(tester);

      expect(find.text('It’s Heads!'), findsOneWidget);
      expect(find.textContaining('Ana called Heads'), findsOneWidget);
      expect(_inRow(_attackerRow, 'Ana (Player 1)'), findsOneWidget);
      expect(_inRow(_tayaRow, 'Ben (Player 2)'), findsOneWidget);
      expect(controller.state.attacker, PlayerId.one);
      expect(controller.state.taya, PlayerId.two);
    });

    testWidgets('a call that does not match makes Player 2 the attacker', (
      tester,
    ) async {
      final controller = _controller(CoinSide.tails);
      await _pumpToss(tester, controller);

      await _call(tester, _callHeads);
      await _finishFlip(tester);

      expect(find.text('It’s Tails!'), findsOneWidget);
      expect(find.textContaining('so Ben throws first'), findsOneWidget);
      expect(_inRow(_attackerRow, 'Ben (Player 2)'), findsOneWidget);
      expect(_inRow(_tayaRow, 'Ana (Player 1)'), findsOneWidget);
      expect(controller.state.attacker, PlayerId.two);
    });

    testWidgets('calling Tails against a Tails coin makes Player 1 attack', (
      tester,
    ) async {
      final controller = _controller(CoinSide.tails);
      await _pumpToss(tester, controller);

      await _call(tester, _callTails);
      await _finishFlip(tester);

      expect(find.text('It’s Tails!'), findsOneWidget);
      expect(_inRow(_attackerRow, 'Ana (Player 1)'), findsOneWidget);
    });

    testWidgets('the toss can only happen once and Back is hidden after it', (
      tester,
    ) async {
      final controller = _controller(CoinSide.heads);
      await _pumpToss(tester, controller);

      await _call(tester, _callHeads);

      expect(find.byKey(_callHeads), findsNothing);
      expect(find.byKey(_callTails), findsNothing);
      expect(find.byType(BackButton), findsNothing);
      expect(controller.state.coinCall, CoinSide.heads);
    });

    testWidgets('reduced motion shows the result straight away', (
      tester,
    ) async {
      await _pumpToss(tester, _controller(CoinSide.heads), reduceMotion: true);

      await _call(tester, _callHeads);

      expect(find.text('It’s Heads!'), findsOneWidget);
      expect(find.text('Flipping the coin…'), findsNothing);
    });
  });

  group('starting the game', () {
    testWidgets('Start game opens the game screen with the toss result', (
      tester,
    ) async {
      final controller = _controller(CoinSide.tails);
      await _pumpToss(tester, controller);
      await _call(tester, _callHeads);
      await _finishFlip(tester);

      await tester.ensureVisible(find.byKey(_startGame));
      await tester.tap(find.byKey(_startGame));
      await tester.pumpAndSettle();

      expect(find.text('Game on'), findsOneWidget);
      expect(find.text('Coin toss'), findsNothing);
      expect(find.text('Ben’s throw'), findsOneWidget);
    });
  });

  group('layout', () {
    testWidgets('fits a small phone through the whole toss', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpToss(tester, _controller(CoinSide.heads));
      expect(tester.takeException(), isNull);

      await _call(tester, _callHeads);
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);

      await _finishFlip(tester);
      expect(tester.takeException(), isNull);
      expect(find.byKey(_startGame), findsOneWidget);
    });
  });
}