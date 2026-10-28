import 'package:flutter/material.dart';
import 'package:game_tumbang_preso/core/app_theme.dart';
import 'package:game_tumbang_preso/domain/domain.dart';
import 'package:game_tumbang_preso/state/game_controller.dart';
import 'package:game_tumbang_preso/ui/widgets/chunky_card.dart';
import 'package:game_tumbang_preso/ui/widgets/player_id_label.dart';
import 'package:game_tumbang_preso/ui/widgets/sky_background.dart';

/// Placeholder main game screen. It already rebuilds from the
/// [GameController], so it shows the coin toss result (who attacks) and will
/// pick up scores and roles as the throw screens are built.
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

  String _status(GameState state) {
    final attacker = state.attacker == null
        ? ''
        : state.nameOf(state.attacker!);
    final taya = state.taya == null ? '' : state.nameOf(state.taya!);
    return switch (state.phase) {
      GamePhase.coinToss => 'Waiting for the coin toss.',
      GamePhase.awaitingThrow => '$attacker throws next.',
      GamePhase.awaitingMissResponse ||
      GamePhase.awaitingHitResponse => '$taya responds next.',
      GamePhase.tieBreaker => 'Jack-en-Poy decides it.',
      GamePhase.finished => '${state.nameOf(state.winner!)} wins!',
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final taya = state.taya;

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
        _PlayerCard(state: state, id: PlayerId.one),
        const SizedBox(height: 16),
        _PlayerCard(state: state, id: PlayerId.two),
        const SizedBox(height: 20),
        ChunkyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _status(state),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (taya != null) ...[
                const SizedBox(height: 6),
                Text(
                  '${state.nameOf(taya)}’s capture attempts left: '
                  '${state.captureAttemptsLeft}',
                  style: const TextStyle(fontSize: 15),
                ),
              ],
              const SizedBox(height: 10),
              const Text(
                'Throwing and the taya’s choices come next.',
                style: TextStyle(fontSize: 14, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({required this.state, required this.id});

  final GameState state;
  final PlayerId id;

  @override
  Widget build(BuildContext context) {
    final attacker = state.attacker;
    final role = attacker == null
        ? null
        : (attacker == id ? 'Attacker' : 'Taya');
    final key = Key(id == PlayerId.one ? 'score-one' : 'score-two');

    return ChunkyCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.nameOf(id),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(id.label, style: const TextStyle(fontSize: 14)),
                if (role != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: role == 'Attacker'
                          ? AppColors.canRed
                          : AppColors.ink,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.ink, width: 2),
                    ),
                    child: Text(
                      role,
                      style: const TextStyle(
                        color: AppColors.paper,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '${state.scores.of(id)}',
            key: key,
            style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}