import 'package:flutter_test/flutter_test.dart';
import 'package:game_tumbang_preso/domain/domain.dart';

void main() {
  group('Hand', () {
    test('rock beats scissors, scissors beats paper, paper beats rock', () {
      expect(Hand.rock.beats(Hand.scissors), isTrue);
      expect(Hand.scissors.beats(Hand.paper), isTrue);
      expect(Hand.paper.beats(Hand.rock), isTrue);
    });

    test('the reverse never wins and a hand never beats itself', () {
      expect(Hand.scissors.beats(Hand.rock), isFalse);
      expect(Hand.paper.beats(Hand.scissors), isFalse);
      expect(Hand.rock.beats(Hand.paper), isFalse);
      for (final hand in Hand.values) {
        expect(hand.beats(hand), isFalse);
      }
    });
  });

  group('PlayerId', () {
    test('other flips between the two players', () {
      expect(PlayerId.one.other, PlayerId.two);
      expect(PlayerId.two.other, PlayerId.one);
    });
  });

  group('Scores', () {
    test('add only changes the chosen player and returns a new object', () {
      const start = Scores();
      final next = start.add(PlayerId.two, 2);
      expect(start, const Scores(0, 0));
      expect(next, const Scores(0, 2));
      expect(next.of(PlayerId.two), 2);
      expect(next.of(PlayerId.one), 0);
    });

    test('verdict keeps playing below the target', () {
      expect(const Scores(9, 9).verdict(10), ScoreVerdict.keepPlaying);
    });

    test('verdict names the single player at or above the target', () {
      expect(const Scores(10, 3).verdict(10), ScoreVerdict.player1Wins);
      expect(const Scores(4, 12).verdict(10), ScoreVerdict.player2Wins);
    });

    test('verdict sends both-at-or-above to the tie-breaker, equal or not', () {
      expect(const Scores(10, 10).verdict(10), ScoreVerdict.tieBreaker);
      expect(const Scores(10, 11).verdict(10), ScoreVerdict.tieBreaker);
    });
  });

  group('player names', () {
    test('accepts two different names', () {
      expect(checkPlayerNames('Ana', 'Ben'), isNull);
    });

    test('rejects blank names, including whitespace only', () {
      expect(checkPlayerNames('', 'Ben'), NameProblem.firstEmpty);
      expect(checkPlayerNames('Ana', '   '), NameProblem.secondEmpty);
    });

    test('rejects duplicates ignoring case and extra spaces', () {
      expect(checkPlayerNames('Ana', ' ana '), NameProblem.duplicate);
      expect(checkPlayerNames('Ana  Cruz', 'ana cruz'), NameProblem.duplicate);
    });

    test('normalizeName trims and collapses spaces', () {
      expect(normalizeName('  Ana   Cruz '), 'Ana Cruz');
    });
  });

  group('Players.fromSetup', () {
    test('first participant choosing Player 1 keeps that identity', () {
      final players = Players.fromSetup(
        firstName: 'Ana',
        firstChoice: PlayerId.one,
        secondName: 'Ben',
      );
      expect(players.one.name, 'Ana');
      expect(players.two.name, 'Ben');
    });

    test(
      'first participant choosing Player 2 leaves Player 1 to the other',
      () {
        final players = Players.fromSetup(
          firstName: 'Ana',
          firstChoice: PlayerId.two,
          secondName: 'Ben',
        );
        expect(players.one.name, 'Ben');
        expect(players.two.name, 'Ana');
        expect(players.of(PlayerId.two).id, PlayerId.two);
      },
    );

    test('trims names and rejects invalid ones', () {
      final players = Players.fromSetup(
        firstName: '  Ana ',
        firstChoice: PlayerId.one,
        secondName: 'Ben',
      );
      expect(players.one.name, 'Ana');
      expect(
        () => Players.fromSetup(
          firstName: 'Ana',
          firstChoice: PlayerId.one,
          secondName: 'ANA',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
