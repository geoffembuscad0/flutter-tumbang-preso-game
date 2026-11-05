import 'package:flutter_test/flutter_test.dart';
import 'package:game_tumbang_preso/domain/domain.dart';

final _players = Players.fromSetup(
  firstName: 'Ana',
  firstChoice: PlayerId.one,
  secondName: 'Ben',
);

void main() {
  group('Jack-en-Poy matchup matrix', () {
    for (final player1Hand in Hand.values) {
      for (final player2Hand in Hand.values) {
        test('Player 1: ${player1Hand.name} vs '
            'Player 2: ${player2Hand.name}', () {
          final engine = GameEngine(
            players: _players,
            initialState: GameState(
              players: _players,
              phase: GamePhase.tieBreaker,
              scores: const Scores(10, 10),
              attacker: PlayerId.one,
              captureAttemptsLeft: 3,
              tieBreaker: const TieBreakerState(),
            ),
          );

          engine.submitTieBreakerHand(PlayerId.one, player1Hand);

          final events = engine.submitTieBreakerHand(PlayerId.two, player2Hand);

          final expectedWinner = player1Hand.beats(player2Hand)
              ? PlayerId.one
              : player2Hand.beats(player1Hand)
              ? PlayerId.two
              : null;

          final round = events.whereType<TieBreakerRoundResolved>().single;

          expect(round.player1Hand, player1Hand);
          expect(round.player2Hand, player2Hand);
          expect(round.winner, expectedWinner);

          if (expectedWinner == null) {
            expect(engine.state.phase, GamePhase.tieBreaker);
            expect(engine.state.winner, isNull);
            expect(engine.state.tieBreaker!.round, 2);
            expect(engine.state.tieBreaker!.awaiting, PlayerId.one);
            expect(engine.state.tieBreaker!.firstHand, isNull);
          } else {
            expect(engine.state.phase, GamePhase.finished);
            expect(engine.state.winner, expectedWinner);
            expect(engine.state.winMethod, WinMethod.tieBreaker);
          }
        });
      }
    }
  });
}
