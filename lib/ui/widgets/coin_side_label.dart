import 'package:game_tumbang_preso/domain/domain.dart';

extension CoinSideLabel on CoinSide {
  /// "Heads" or "Tails", for display.
  String get label => this == CoinSide.heads ? 'Heads' : 'Tails';
}