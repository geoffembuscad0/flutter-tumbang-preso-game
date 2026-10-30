import 'package:flutter/material.dart';
import 'package:game_tumbang_preso/domain/domain.dart';
import 'package:game_tumbang_preso/ui/game/widgets/scoreboard.dart';
import 'package:game_tumbang_preso/ui/widgets/chunky_card.dart';

// Placeholder until the victory screen is built (spec section 8, step 11).
class FinishedStage extends StatelessWidget {
  const FinishedStage({super.key, required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Scoreboard(state: state, showRoles: false),
        const SizedBox(height: 16),
        ChunkyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${state.nameOf(state.winner!)} wins!',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'The victory screen and a way to start a new game come next.',
                style: TextStyle(fontSize: 15, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}