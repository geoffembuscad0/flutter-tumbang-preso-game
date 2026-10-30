import 'package:flutter/material.dart';
import 'package:game_tumbang_preso/core/app_theme.dart';
import 'package:game_tumbang_preso/domain/domain.dart';
import 'package:game_tumbang_preso/state/game_controller.dart';
import 'package:game_tumbang_preso/state/tie_breaker_step.dart';
import 'package:game_tumbang_preso/state/turn_step.dart';
import 'package:game_tumbang_preso/ui/game/stages/choice_stage.dart';
import 'package:game_tumbang_preso/ui/game/stages/end_stages.dart';
import 'package:game_tumbang_preso/ui/game/stages/handoff_stage.dart';
import 'package:game_tumbang_preso/ui/game/stages/result_stage.dart';
import 'package:game_tumbang_preso/ui/game/stages/tie_breaker_stages.dart';
import 'package:game_tumbang_preso/ui/game/stages/throw_stage.dart';
import 'package:game_tumbang_preso/ui/widgets/sky_background.dart';

/// The main game screen. It shows no navigation between the steps of an
/// exchange: it rebuilds from the [GameController] and picks one stage from
/// the engine phase (what the rules wait for) and the turn step (what the
/// shared device waits for). The pass-the-device handoff is therefore a state
/// the controller enforces, not a route the UI happens to push.
class GameScreen extends StatelessWidget {
  const GameScreen({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SkyBackground(
        child: SafeArea(
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: BackButton(color: AppColors.ink),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: ListenableBuilder(
                        listenable: controller,
                        builder: (context, _) => _GameBody(controller),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameBody extends StatelessWidget {
  const _GameBody(this.controller);

  final GameController controller;

  /// The stage to show, with an id that stays the same while a stage only
  /// changes internally (so its animation is not restarted).
  ({String id, Widget child}) _stage() {
    final state = controller.state;
    final step = controller.step;

    // The result of the last response is shown first, even when it ended the
    // game or started the tie-breaker; the screens for those follow it.
    if (step != TurnStep.responseResult) {
      // The last round of a decided tie-breaker is still on screen until the
      // players continue, even though the engine is already finished.
      final showingLastRound =
          state.phase == GamePhase.finished &&
          state.winMethod == WinMethod.tieBreaker &&
          controller.tieBreakerStep == TieBreakerStep.roundResult;

      if (state.phase == GamePhase.tieBreaker || showingLastRound) {
        return switch (controller.tieBreakerStep) {
          TieBreakerStep.handoffFirst => (
            id: 'tb-handoff-first',
            child: TieBreakerHandoffStage(controller: controller),
          ),
          TieBreakerStep.firstPick => (
            id: 'tb-pick-first',
            child: HandPickStage(controller: controller),
          ),
          TieBreakerStep.handoffSecond => (
            id: 'tb-handoff-second',
            child: TieBreakerHandoffStage(controller: controller),
          ),
          TieBreakerStep.secondPick => (
            id: 'tb-pick-second',
            child: HandPickStage(controller: controller),
          ),
          TieBreakerStep.roundResult => (
            id: 'tb-result',
            child: RoundResultStage(controller: controller),
          ),
        };
      }
      if (state.phase == GamePhase.finished) {
        return (id: 'finished', child: FinishedStage(state: state));
      }
    }

    return switch (step) {
      TurnStep.throwing || TurnStep.throwResult => (
        id: 'throw',
        child: ThrowStage(controller: controller),
      ),
      TurnStep.handoff => (
        id: 'handoff',
        child: HandoffStage(controller: controller),
      ),
      TurnStep.privateChoice => (
        id: 'choice',
        child: ChoiceStage(controller: controller),
      ),
      TurnStep.responseResult => (
        id: 'result',
        child: ResultStage(controller: controller),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final stage = _stage();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Game on',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'First to ${controller.config.targetScore} points wins.',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 250),
          child: KeyedSubtree(
            key: ValueKey<String>(stage.id),
            child: stage.child,
          ),
        ),
      ],
    );
  }
}