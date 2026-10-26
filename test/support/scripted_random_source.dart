import 'package:game_tumbang_preso/domain/enums.dart';
import 'package:game_tumbang_preso/domain/random_source.dart';

/// A [RandomSource] that replays a fixed script, so tests decide every
/// outcome. It records the chances the engine asked for, and fails loudly if
/// the engine asks for more randomness than the test scripted.
class ScriptedRandomSource implements RandomSource {
  ScriptedRandomSource({
    List<bool> rolls = const [],
    List<CoinSide> coins = const [],
  }) : _rolls = [...rolls],
       _coins = [...coins];

  final List<bool> _rolls;
  final List<CoinSide> _coins;

  /// Every `chance` value passed to [roll], in order.
  final List<double> requestedChances = [];

  int get rollsLeft => _rolls.length;

  @override
  bool roll(double chance) {
    requestedChances.add(chance);
    if (_rolls.isEmpty) throw StateError('No scripted roll left.');
    return _rolls.removeAt(0);
  }

  @override
  CoinSide flipCoin() {
    if (_coins.isEmpty) throw StateError('No scripted coin flip left.');
    return _coins.removeAt(0);
  }
}
