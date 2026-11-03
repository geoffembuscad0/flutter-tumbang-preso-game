import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_tumbang_preso/core/app_theme.dart';
import 'package:game_tumbang_preso/domain/domain.dart';
import 'package:game_tumbang_preso/state/game_controller.dart';
import 'package:game_tumbang_preso/ui/game/game_screen.dart';

final _players = Players.fromSetup(
  firstName: 'Ana',
  firstChoice: PlayerId.one,
  secondName: 'Ben',
);

GameController _tieBreakerGame() {
  return GameController(
    GameEngine(
      players: _players,
      initialState: GameState(
        players: _players,
        phase: GamePhase.tieBreaker,
        scores: const Scores(10, 10),
        attacker: PlayerId.one,
        captureAttemptsLeft: 3,
        tieBreaker: const TieBreakerState(),
      ),
    ),
  );
}

GameController _finishedGame({
  PlayerId winner = PlayerId.one,
  WinMethod winMethod = WinMethod.reachedTarget,
}) {
  return GameController(
    GameEngine(
      players: _players,
      initialState: GameState(
        players: _players,
        phase: GamePhase.finished,
        scores: const Scores(10, 7),
        attacker: PlayerId.one,
        captureAttemptsLeft: 3,
        winner: winner,
        winMethod: winMethod,
      ),
    ),
  );
}

Future<void> _pumpGame(
  WidgetTester tester,
  GameController controller, {
  VoidCallback? onNewGame,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: GameScreen(controller: controller, onNewGame: onNewGame ?? () {}),
    ),
  );
}

Future<void> _tapAndSettle(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

void main() {
  group('Jack-en-Poy handoff and selection', () {
    testWidgets('starts with Player 1 handoff', (tester) async {
      final controller = _tieBreakerGame();

      await _pumpGame(tester, controller);

      expect(find.text('Jack-en-Poy'), findsOneWidget);
      expect(find.text('Pass the device to Ana'), findsOneWidget);
      expect(
        find.byKey(const Key('confirm-tie-breaker-handoff')),
        findsOneWidget,
      );

      // No hand selection should be available before the handoff.
      expect(find.byKey(const Key('pick-rock')), findsNothing);
      expect(find.byKey(const Key('pick-paper')), findsNothing);
      expect(find.byKey(const Key('pick-scissors')), findsNothing);
    });

    testWidgets('Player 1 can make a private hand selection', (tester) async {
      final controller = _tieBreakerGame();

      await _pumpGame(tester, controller);

      await _tapAndSettle(tester, const Key('confirm-tie-breaker-handoff'));

      expect(find.text('Ana, make your pick!'), findsOneWidget);
      expect(find.byKey(const Key('pick-rock')), findsOneWidget);
      expect(find.byKey(const Key('pick-paper')), findsOneWidget);
      expect(find.byKey(const Key('pick-scissors')), findsOneWidget);

      await _tapAndSettle(tester, const Key('pick-rock'));

      expect(controller.state.tieBreaker!.firstHand, Hand.rock);
      expect(find.text('Pass the device to Ben'), findsOneWidget);

      // Player 1's hand must remain private during Player 2's handoff.
      expect(find.text('Rock'), findsNothing);
      expect(find.byKey(const Key('pick-rock')), findsNothing);
      expect(find.byKey(const Key('pick-paper')), findsNothing);
      expect(find.byKey(const Key('pick-scissors')), findsNothing);
    });

    testWidgets('Player 2 gets a private selection screen', (tester) async {
      final controller = _tieBreakerGame();

      await _pumpGame(tester, controller);

      await _tapAndSettle(tester, const Key('confirm-tie-breaker-handoff'));
      await _tapAndSettle(tester, const Key('pick-rock'));

      await _tapAndSettle(tester, const Key('confirm-tie-breaker-handoff'));

      expect(find.text('Ben, make your pick!'), findsOneWidget);
      expect(find.byKey(const Key('pick-rock')), findsOneWidget);
      expect(find.byKey(const Key('pick-paper')), findsOneWidget);
      expect(find.byKey(const Key('pick-scissors')), findsOneWidget);

      // Player 1's selection is still not visible to Player 2.
      expect(find.text('Rock'), findsNothing);
    });
  });

  group('Jack-en-Poy round results', () {
    testWidgets('reveals both hands after Player 2 submits', (tester) async {
      final controller = _tieBreakerGame();

      await _pumpGame(tester, controller);

      // Player 1 chooses Rock.
      await _tapAndSettle(tester, const Key('confirm-tie-breaker-handoff'));
      await _tapAndSettle(tester, const Key('pick-rock'));

      // Player 2 chooses Paper.
      await _tapAndSettle(tester, const Key('confirm-tie-breaker-handoff'));
      await _tapAndSettle(tester, const Key('pick-paper'));

      expect(find.text('Round 1'), findsOneWidget);
      expect(
        find.byKey(const Key('tie-breaker-result-headline')),
        findsOneWidget,
      );
      expect(find.text('Ben wins this round!'), findsOneWidget);

      // Both hands are now revealed.
      expect(find.text('Rock'), findsOneWidget);
      expect(find.text('Paper'), findsOneWidget);

      // The winner is already determined by the engine.
      expect(controller.state.phase, GamePhase.finished);
      expect(controller.state.winner, PlayerId.two);
      expect(controller.state.winMethod, WinMethod.tieBreaker);
    });

    testWidgets('a draw starts another Jack-en-Poy round', (tester) async {
      final controller = _tieBreakerGame();

      await _pumpGame(tester, controller);

      // Player 1 chooses Rock.
      await _tapAndSettle(tester, const Key('confirm-tie-breaker-handoff'));
      await _tapAndSettle(tester, const Key('pick-rock'));

      // Player 2 also chooses Rock.
      await _tapAndSettle(tester, const Key('confirm-tie-breaker-handoff'));
      await _tapAndSettle(tester, const Key('pick-rock'));

      expect(find.text('Round 1'), findsOneWidget);
      expect(find.text('It’s a draw!'), findsOneWidget);
      expect(
        find.text(
          'Both players selected hands of equal strength. '
          'Another round is needed!',
        ),
        findsOneWidget,
      );

      // Both selections are revealed for the completed round.
      expect(find.text('Rock'), findsNWidgets(2));

      await _tapAndSettle(tester, const Key('continue-tie-breaker-round'));

      expect(controller.state.phase, GamePhase.tieBreaker);
      expect(controller.state.tieBreaker!.round, 2);
      expect(controller.state.tieBreaker!.firstHand, isNull);
      expect(controller.state.tieBreaker!.awaiting, PlayerId.one);

      expect(find.text('Pass the device to Ana'), findsOneWidget);
    });

    testWidgets('shows the final winner after a Jack-en-Poy victory', (
      tester,
    ) async {
      final controller = _tieBreakerGame();

      await _pumpGame(tester, controller);

      // Player 1 chooses Rock.
      await _tapAndSettle(tester, const Key('confirm-tie-breaker-handoff'));
      await _tapAndSettle(tester, const Key('pick-rock'));

      // Player 2 chooses Paper and wins.
      await _tapAndSettle(tester, const Key('confirm-tie-breaker-handoff'));
      await _tapAndSettle(tester, const Key('pick-paper'));

      expect(find.text('Ben wins this round!'), findsOneWidget);

      // Continue from the resolved round to the victory screen.
      await _tapAndSettle(tester, const Key('continue-tie-breaker-round'));

      expect(find.text('Ben wins!'), findsOneWidget);
      expect(find.text('Victory through Jack-en-Poy!'), findsOneWidget);
      expect(find.byKey(const Key('new-game')), findsOneWidget);

      // The final scores remain visible.
      expect(
        tester.widget<Text>(find.byKey(const Key('score-one'))).data,
        '10',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('score-two'))).data,
        '10',
      );
    });
  });

  group('Victory screen', () {
    testWidgets('explains a victory by reaching the target score', (
      tester,
    ) async {
      final controller = _finishedGame();

      await _pumpGame(tester, controller);

      expect(find.text('Ana wins!'), findsOneWidget);
      expect(
        find.text('Victory by reaching the target score.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('new-game')), findsOneWidget);
    });

    testWidgets('New game invokes its callback', (tester) async {
      var newGamePressed = false;

      await _pumpGame(
        tester,
        _finishedGame(),
        onNewGame: () => newGamePressed = true,
      );

      await _tapAndSettle(tester, const Key('new-game'));

      expect(newGamePressed, isTrue);
    });
  });
}
