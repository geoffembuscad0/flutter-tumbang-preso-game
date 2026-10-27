import 'package:game_tumbang_preso/domain/domain.dart';

extension PlayerIdLabel on PlayerId {
  /// "Player 1" or "Player 2", for display.
  String get label => 'Player $number';
}
