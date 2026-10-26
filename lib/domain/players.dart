import 'package:game_tumbang_preso/domain/enums.dart';

class Player {
  const Player({required this.id, required this.name});

  final PlayerId id;
  final String name;
}

/// Why a pair of names was rejected. PROVISIONAL: spec open question 5.
enum NameProblem { firstEmpty, secondEmpty, duplicate }

/// Trims the name and collapses repeated spaces.
String normalizeName(String raw) => raw.trim().replaceAll(RegExp(r'\s+'), ' ');

/// Returns the first problem with the two names, or null when both are fine.
/// Duplicates are compared ignoring case and extra spaces.
NameProblem? checkPlayerNames(String first, String second) {
  final a = normalizeName(first);
  final b = normalizeName(second);
  if (a.isEmpty) return NameProblem.firstEmpty;
  if (b.isEmpty) return NameProblem.secondEmpty;
  if (a.toLowerCase() == b.toLowerCase()) return NameProblem.duplicate;
  return null;
}

/// The two fixed players of a game (spec 2 and 3).
class Players {
  const Players({required this.one, required this.two});

  /// Builds players from the setup screen: the first participant picks an
  /// identity and the second gets the other one (spec 3).
  ///
  /// Throws [ArgumentError] when the names fail [checkPlayerNames], so the
  /// UI should validate first.
  factory Players.fromSetup({
    required String firstName,
    required PlayerId firstChoice,
    required String secondName,
  }) {
    final problem = checkPlayerNames(firstName, secondName);
    if (problem != null) {
      throw ArgumentError('Invalid player names: ${problem.name}.');
    }
    final first = normalizeName(firstName);
    final second = normalizeName(secondName);
    return firstChoice == PlayerId.one
        ? Players(
            one: Player(id: PlayerId.one, name: first),
            two: Player(id: PlayerId.two, name: second),
          )
        : Players(
            one: Player(id: PlayerId.one, name: second),
            two: Player(id: PlayerId.two, name: first),
          );
  }

  final Player one;
  final Player two;

  Player of(PlayerId id) => id == PlayerId.one ? one : two;
}
