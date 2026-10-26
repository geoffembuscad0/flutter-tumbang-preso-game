import 'dart:math';

import 'package:game_tumbang_preso/domain/enums.dart';

/// The only way the engine gets randomness (spec 9).
///
/// Tests pass a scripted implementation so every outcome is deterministic.
abstract interface class RandomSource {
  /// Returns true with probability [chance] (0.0 to 1.0).
  bool roll(double chance);

  CoinSide flipCoin();
}

class DartRandomSource implements RandomSource {
  DartRandomSource([Random? random]) : _random = random ?? Random();

  final Random _random;

  @override
  bool roll(double chance) {
    if (chance <= 0) return false;
    if (chance >= 1) return true;
    return _random.nextDouble() < chance;
  }

  @override
  CoinSide flipCoin() => _random.nextBool() ? CoinSide.heads : CoinSide.tails;
}
