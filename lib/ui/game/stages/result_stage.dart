import 'package:flutter/material.dart';
import 'package:game_tumbang_preso/domain/domain.dart';
import 'package:game_tumbang_preso/state/game_controller.dart';
import 'package:game_tumbang_preso/state/turn_step.dart';
import 'package:game_tumbang_preso/ui/game/summaries.dart';
import 'package:game_tumbang_preso/ui/game/widgets/scoreboard.dart';
import 'package:game_tumbang_preso/ui/widgets/chunky_button.dart';
import 'package:game_tumbang_preso/ui/widgets/chunky_card.dart';

/// The result of the taya's choice, shown to both players at
/// [TurnStep.responseResult] (spec section 8, steps 6 and 8). The text is built
/// from the response's engine events; the button says what comes next.
class ResultStage extends StatelessWidget {
  const ResultStage({super.key, required this.controller});

  final GameController controller;

  void _continue() {
    if (controller.step != TurnStep.responseResult) return;
    controller.continueFromResponse();
  }

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final summary = summarizeResponse(
      controller.lastEvents,
      state.players,
      controller.config.targetScore,
    );
    final nextLabel = switch (state.phase) {
      GamePhase.awaitingThrow =>
        'Next: ${state.nameOf(state.attacker!)} throws',
      GamePhase.tieBreaker => 'On to Jack-en-Poy',
      GamePhase.finished => 'See the winner',
      _ => 'Continue',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Scoreboard(state: state),
        const SizedBox(height: 16),
        ChunkyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                liveRegion: true,
                child: Text(
                  summary.headline,
                  key: const Key('result-headline'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              for (final detail in summary.details)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    detail,
                    style: const TextStyle(fontSize: 15, height: 1.3),
                  ),
                ),
              const SizedBox(height: 18),
              ChunkyButton(
                key: const Key('continue-result'),
                label: nextLabel,
                icon: Icons.arrow_forward_rounded,
                onPressed: _continue,
              ),
            ],
          ),
        ),
      ],
    );
  }
}