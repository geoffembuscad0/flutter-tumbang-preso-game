import 'package:flutter/material.dart';
import 'package:game_tumbang_preso/core/app_theme.dart';
import 'package:game_tumbang_preso/state/game_controller.dart';
import 'package:game_tumbang_preso/state/turn_step.dart';
import 'package:game_tumbang_preso/ui/widgets/chunky_button.dart';
import 'package:game_tumbang_preso/ui/widgets/chunky_card.dart';

/// The pass-the-device screen (spec section 10), shown at
/// [TurnStep.handoff].
///
/// It deliberately shows nothing about the choice, not even the scoreboard,
/// so it is safe for the attacker to be looking at it. The taya taps the
/// button once they are holding the device; that tap is the only way the
/// controller will accept their private choice.
class HandoffStage extends StatelessWidget {
  const HandoffStage({super.key, required this.controller});

  final GameController controller;

  void _confirm() {
    if (controller.step != TurnStep.handoff) return;
    controller.confirmHandoff();
  }

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final taya = state.nameOf(state.taya!);
    final attacker = state.nameOf(state.attacker!);

    return ChunkyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.ink,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.phone_android_rounded,
                color: AppColors.paper,
                size: 48,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Semantics(
            liveRegion: true,
            child: Text(
              'Pass the device to $taya',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$attacker, hand it over and look away. $taya makes a private '
            'choice next.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, height: 1.3),
          ),
          const SizedBox(height: 22),
          ChunkyButton(
            key: const Key('confirm-handoff'),
            label: 'I’m $taya',
            icon: Icons.lock_open_rounded,
            onPressed: _confirm,
          ),
        ],
      ),
    );
  }
}