import 'package:flutter/material.dart';
import 'package:game_tumbang_preso/core/app_theme.dart';
import 'package:game_tumbang_preso/domain/domain.dart';
import 'package:game_tumbang_preso/state/game_controller.dart';
import 'package:game_tumbang_preso/state/turn_step.dart';
import 'package:game_tumbang_preso/ui/game/widgets/scoreboard.dart';
import 'package:game_tumbang_preso/ui/widgets/chunky_button.dart';
import 'package:game_tumbang_preso/ui/widgets/chunky_card.dart';

/// The taya's private choice (spec 5.1 and 5.3), shown at
/// [TurnStep.privateChoice]. Which choices appear comes from the engine
/// phase: after a miss the taya picks a capture attempt or the next throw,
/// after a hit the taya picks Guard Can or Catch Player.
///
/// Every button checks that the controller really is at the private-choice
/// step before it does anything, so a double tap or a late tap during a
/// transition cannot submit a second choice.
class ChoiceStage extends StatelessWidget {
  const ChoiceStage({super.key, required this.controller});

  final GameController controller;

  bool get _ready => controller.step == TurnStep.privateChoice;

  void _miss(MissResponse response) {
    if (!_ready) return;
    controller.respondToMiss(response);
  }

  void _hit(HitResponse response) {
    if (!_ready) return;
    controller.respondToHit(response);
  }

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final config = controller.config;
    final taya = state.nameOf(state.taya!);
    final attacker = state.nameOf(state.attacker!);
    final isMiss = state.phase == GamePhase.awaitingMissResponse;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Scoreboard(state: state),
        const SizedBox(height: 16),
        ChunkyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.lock_rounded, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Private choice',
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Semantics(
                liveRegion: true,
                child: Text(
                  '$taya, your move',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isMiss
                    ? 'The throw missed the can. Try to grab the slipper, or '
                          'let $attacker throw again?'
                    : 'The can is down! Guard it, or go after $attacker?',
                style: const TextStyle(fontSize: 16, height: 1.3),
              ),
              const SizedBox(height: 18),
              if (isMiss) ...[
                _Option(
                  button: ChunkyButton(
                    key: const Key('attempt-capture'),
                    label: 'Attempt to Capture Slipper',
                    onPressed: () => _miss(MissResponse.attemptCapture),
                  ),
                  caption:
                      'Uses one capture attempt, win or lose '
                      '(${state.captureAttemptsLeft} of '
                      '${config.captureAttemptsPerStint} left). Success '
                      'scores ${config.capturePoints} point'
                      '${config.capturePoints == 1 ? '' : 's'}.',
                ),
                const SizedBox(height: 18),
                _Option(
                  button: ChunkyButton(
                    key: const Key('allow-next-throw'),
                    label: 'Allow Next Throw',
                    filled: false,
                    onPressed: () => _miss(MissResponse.allowNextThrow),
                  ),
                  caption: 'Keeps your capture attempts.',
                ),
              ] else ...[
                _Option(
                  button: ChunkyButton(
                    key: const Key('guard-can'),
                    label: 'Guard Can',
                    onPressed: () => _hit(HitResponse.guardCan),
                  ),
                  caption: 'Stands the can back up. No extra points.',
                ),
                const SizedBox(height: 18),
                _Option(
                  button: ChunkyButton(
                    key: const Key('catch-player'),
                    label: 'Catch Player',
                    filled: false,
                    onPressed: () => _hit(HitResponse.catchPlayer),
                  ),
                  caption:
                      'Success scores ${config.catchPoints} points and '
                      'swaps roles. If it fails, nothing changes.',
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({required this.button, required this.caption});

  final Widget button;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        button,
        const SizedBox(height: 10),
        Text(
          caption,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            height: 1.3,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}