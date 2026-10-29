import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_tumbang_preso/core/app_theme.dart';
import 'package:game_tumbang_preso/domain/domain.dart';
import 'package:game_tumbang_preso/state/game_controller.dart';
import 'package:game_tumbang_preso/state/turn_step.dart';
import 'package:game_tumbang_preso/ui/game/game_screen.dart';

import 'support/scripted_random_source.dart';

final _players = Players.fromSetup(
  firstName: 'Ana',
  firstChoice: PlayerId.one,
  secondName: 'Ben',
);

/// A game past the coin toss with Ana (Player 1) attacking and Ben as taya.
/// [rolls] script the engine's random outcomes in order.
GameController _game({List<bool> rolls = const []}) {
  final controller = GameController.newGame(
    players: _players,
    random: ScriptedRandomSource(coins: [CoinSide.heads], rolls: rolls),
  );
  controller.callCoinToss(CoinSide.heads);
  return controller;
}

Future<void> _pump(
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
      home: GameScreen(controller: controller),
    ),
  );
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
}

/// Moves past the throw animation and any stage transition.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pump(const Duration(milliseconds: 500));
}

String _score(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(Key(key))).data!;

Finder _key(String key) => find.byKey(Key(key));

void main() {
  group('throwing', () {
    testWidgets('asks the attacker to throw', (tester) async {
      await _pump(tester, _game());

      expect(find.text('Ana’s throw'), findsOneWidget);
      expect(_key('throw-button'), findsOneWidget);
    });

    testWidgets('holds the outcome back until the throw animation ends', (
      tester,
    ) async {
      final controller = _game(rolls: [true]);
      await _pump(tester, controller);

      await _tapKey(tester, 'throw-button');
      await tester.pump(const Duration(milliseconds: 300));

      // The engine has decided, but nothing is revealed yet.
      expect(controller.state.phase, GamePhase.awaitingHitResponse);
      expect(find.text('Throwing…'), findsOneWidget);
      expect(find.text('Hit!'), findsNothing);
      expect(_key('pass-device'), findsNothing);
      expect(_score(tester, 'score-one'), '0');

      await _settle(tester);

      expect(find.text('Hit!'), findsOneWidget);
      expect(_score(tester, 'score-one'), '1');
      expect(_key('pass-device'), findsOneWidget);
    });

    testWidgets('a miss is revealed as a miss', (tester) async {
      await _pump(tester, _game(rolls: [false]));

      await _tapKey(tester, 'throw-button');
      await _settle(tester);

      expect(find.text('Missed!'), findsOneWidget);
      expect(_score(tester, 'score-one'), '0');
      expect(_key('pass-device'), findsOneWidget);
    });

    testWidgets('reduced motion reveals the outcome straight away', (
      tester,
    ) async {
      await _pump(tester, _game(rolls: [true]), reduceMotion: true);

      await _tapKey(tester, 'throw-button');

      expect(find.text('Hit!'), findsOneWidget);
    });

    testWidgets('the throw button cannot be used twice', (tester) async {
      final controller = _game(rolls: [true]);
      await _pump(tester, controller);

      await _tapKey(tester, 'throw-button');

      expect(_key('throw-button'), findsNothing);
      expect(controller.step, TurnStep.throwResult);
    });
  });

  group('the private handoff', () {
    testWidgets('a hit hands the device to the taya before any choice shows', (
      tester,
    ) async {
      final controller = _game(rolls: [true]);
      await _pump(tester, controller);
      await _tapKey(tester, 'throw-button');
      await _settle(tester);

      await _tapKey(tester, 'pass-device');
      await _settle(tester);

      // Handoff: the screen names the taya and reveals nothing else.
      expect(controller.step, TurnStep.handoff);
      expect(find.text('Pass the device to Ben'), findsOneWidget);
      expect(_key('confirm-handoff'), findsOneWidget);
      expect(_key('guard-can'), findsNothing);
      expect(_key('catch-player'), findsNothing);
      expect(_key('score-one'), findsNothing);

      await _tapKey(tester, 'confirm-handoff');
      await _settle(tester);

      // Only now do the private choices exist.
      expect(controller.step, TurnStep.privateChoice);
      expect(find.text('Ben, your move'), findsOneWidget);
      expect(_key('guard-can'), findsOneWidget);
      expect(_key('catch-player'), findsOneWidget);
      expect(_key('confirm-handoff'), findsNothing);
    });

    testWidgets('a miss offers a capture attempt or the next throw', (
      tester,
    ) async {
      final controller = _game(rolls: [false]);
      await _pump(tester, controller);
      await _tapKey(tester, 'throw-button');
      await _settle(tester);
      await _tapKey(tester, 'pass-device');
      await _settle(tester);

      expect(_key('attempt-capture'), findsNothing);
      expect(_key('allow-next-throw'), findsNothing);

      await _tapKey(tester, 'confirm-handoff');
      await _settle(tester);

      expect(_key('attempt-capture'), findsOneWidget);
      expect(_key('allow-next-throw'), findsOneWidget);
      expect(find.text('Ben’s capture attempts left: 3'), findsOneWidget);
    });

    testWidgets('the engine does not move until the taya chooses', (
      tester,
    ) async {
      final controller = _game(rolls: [true]);
      await _pump(tester, controller);
      await _tapKey(tester, 'throw-button');
      await _settle(tester);
      await _tapKey(tester, 'pass-device');
      await _settle(tester);

      expect(controller.state.phase, GamePhase.awaitingHitResponse);
      expect(
        () => controller.respondToHit(HitResponse.catchPlayer),
        throwsA(isA<InvalidGameActionException>()),
      );
      expect(controller.state.scores, const Scores(1, 0));
    });
  });

  group('the taya responds', () {
    testWidgets('Guard Can returns the throw to the attacker', (tester) async {
      final controller = _game(rolls: [true]);
      await _pump(tester, controller);
      await _tapKey(tester, 'throw-button');
      await _settle(tester);
      await _tapKey(tester, 'pass-device');
      await _settle(tester);
      await _tapKey(tester, 'confirm-handoff');
      await _settle(tester);

      await _tapKey(tester, 'guard-can');
      await _settle(tester);

      expect(controller.step, TurnStep.responseResult);
      expect(find.text('Can guarded.'), findsOneWidget);
      expect(find.text('Next: Ana throws'), findsOneWidget);

      await _tapKey(tester, 'continue-result');
      await _settle(tester);

      expect(controller.step, TurnStep.throwing);
      expect(find.text('Ana’s throw'), findsOneWidget);
      expect(_key('throw-button'), findsOneWidget);
    });

    testWidgets('a successful capture scores for the taya', (tester) async {
      final controller = _game(rolls: [false, true]);
      await _pump(tester, controller);
      await _tapKey(tester, 'throw-button');
      await _settle(tester);
      await _tapKey(tester, 'pass-device');
      await _settle(tester);
      await _tapKey(tester, 'confirm-handoff');
      await _settle(tester);

      await _tapKey(tester, 'attempt-capture');
      await _settle(tester);

      expect(find.text('Slipper captured!'), findsOneWidget);
      expect(_score(tester, 'score-two'), '1');
      expect(find.text('Ben’s capture attempts left: 2'), findsOneWidget);
    });

    testWidgets('Allow Next Throw keeps the capture attempts', (tester) async {
      final controller = _game(rolls: [false]);
      await _pump(tester, controller);
      await _tapKey(tester, 'throw-button');
      await _settle(tester);
      await _tapKey(tester, 'pass-device');
      await _settle(tester);
      await _tapKey(tester, 'confirm-handoff');
      await _settle(tester);

      await _tapKey(tester, 'allow-next-throw');
      await _settle(tester);

      expect(find.text('Next throw'), findsOneWidget);
      expect(find.text('Ben lets Ana throw again.'), findsOneWidget);
      expect(find.text('Ben’s capture attempts left: 3'), findsOneWidget);
    });

    testWidgets('a successful catch swaps the roles for the next throw', (
      tester,
    ) async {
      final controller = _game(rolls: [true, true]);
      await _pump(tester, controller);
      await _tapKey(tester, 'throw-button');
      await _settle(tester);
      await _tapKey(tester, 'pass-device');
      await _settle(tester);
      await _tapKey(tester, 'confirm-handoff');
      await _settle(tester);

      await _tapKey(tester, 'catch-player');
      await _settle(tester);

      expect(find.text('Caught!'), findsOneWidget);
      expect(_score(tester, 'score-one'), '1');
      expect(_score(tester, 'score-two'), '2');
      expect(find.text('Next: Ben throws'), findsOneWidget);

      await _tapKey(tester, 'continue-result');
      await _settle(tester);

      expect(find.text('Ben’s throw'), findsOneWidget);
      expect(controller.state.attacker, PlayerId.two);
    });

    testWidgets('a choice cannot be submitted twice', (tester) async {
      final controller = _game(rolls: [true]);
      await _pump(tester, controller);
      await _tapKey(tester, 'throw-button');
      await _settle(tester);
      await _tapKey(tester, 'pass-device');
      await _settle(tester);
      await _tapKey(tester, 'confirm-handoff');
      await _settle(tester);

      await _tapKey(tester, 'guard-can');
      // The old buttons may still be fading out; a second tap is ignored.
      final lateTap = find.byKey(const Key('guard-can'));
      if (lateTap.evaluate().isNotEmpty) {
        await tester.tap(lateTap, warnIfMissed: false);
      }
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(controller.step, TurnStep.responseResult);
    });
  });

  group('no capture attempts left', () {
    testWidgets('a miss skips the handoff and the attacker throws again', (
      tester,
    ) async {
      final controller = GameController(
        GameEngine(
          players: _players,
          random: ScriptedRandomSource(rolls: [false]),
          initialState: GameState(
            players: _players,
            phase: GamePhase.awaitingThrow,
            scores: const Scores(),
            attacker: PlayerId.one,
            captureAttemptsLeft: 0,
          ),
        ),
      );
      await _pump(tester, controller);

      await _tapKey(tester, 'throw-button');
      await _settle(tester);

      expect(find.text('Missed!'), findsOneWidget);
      expect(
        find.text('Ben has no capture attempts left, so Ana throws again.'),
        findsOneWidget,
      );
      expect(_key('pass-device'), findsNothing);

      await _tapKey(tester, 'continue-throw');
      await tester.pump(const Duration(milliseconds: 500));

      expect(controller.step, TurnStep.throwing);
      expect(find.text('Missed!'), findsNothing);
      expect(_key('throw-button'), findsOneWidget);
    });
  });

  group('layout', () {
    testWidgets('every stage fits a small phone', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pump(tester, _game(rolls: [true]));
      expect(tester.takeException(), isNull);

      await _tapKey(tester, 'throw-button');
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);

      await _settle(tester);
      expect(tester.takeException(), isNull);

      await _tapKey(tester, 'pass-device');
      await _settle(tester);
      expect(tester.takeException(), isNull);

      await _tapKey(tester, 'confirm-handoff');
      await _settle(tester);
      expect(tester.takeException(), isNull);

      await _tapKey(tester, 'catch-player');
      await _settle(tester);
      expect(tester.takeException(), isNull);
      expect(_key('continue-result'), findsOneWidget);
    });
  });
}