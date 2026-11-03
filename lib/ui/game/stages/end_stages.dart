import 'package:flutter/material.dart';
import 'package:game_tumbang_preso/domain/domain.dart';
import 'package:game_tumbang_preso/ui/game/widgets/scoreboard.dart';
import 'package:game_tumbang_preso/ui/widgets/chunky_button.dart';
import 'package:game_tumbang_preso/ui/widgets/chunky_card.dart';

class FinishedStage extends StatelessWidget {
  const FinishedStage({
    super.key,
    required this.state,
    required this.onNewGame,
  });

  final GameState state;
  final VoidCallback onNewGame;

  String get _winMethodMessage {
    return switch (state.winMethod) {
      WinMethod.reachedTarget => 'Victory by reaching the target score.',
      WinMethod.tieBreaker => 'Victory through Jack-en-Poy!',
      null => 'The game has ended.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final winnerName = state.nameOf(state.winner!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Scoreboard(state: state, showRoles: false),
        const SizedBox(height: 20),
        ChunkyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.emoji_events_rounded, size: 76),
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(
                  '$winnerName wins!',
                  key: const Key('victory-headline'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _winMethodMessage,
                key: const Key('victory-win-method'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              ChunkyButton(
                key: const Key('new-game'),
                label: 'New game',
                icon: Icons.refresh_rounded,
                onPressed: onNewGame,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
