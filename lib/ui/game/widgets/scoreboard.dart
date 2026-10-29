import 'package:flutter/material.dart';
import 'package:game_tumbang_preso/core/app_theme.dart';
import 'package:game_tumbang_preso/domain/domain.dart';
import 'package:game_tumbang_preso/ui/widgets/chunky_card.dart';
import 'package:game_tumbang_preso/ui/widgets/player_id_label.dart';

/// Both players' names, numbers, roles and scores, plus the taya's remaining
/// capture attempts (spec sections 2 and 5.2).
///
/// It draws whatever [state] it is given, so a stage can show an earlier
/// snapshot while a result is still being revealed.
class Scoreboard extends StatelessWidget {
  const Scoreboard({super.key, required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final taya = state.taya;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PlayerCard(state: state, id: PlayerId.one),
        const SizedBox(height: 12),
        _PlayerCard(state: state, id: PlayerId.two),
        if (taya != null) ...[
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.ink, width: 2),
              ),
              child: Text(
                '${state.nameOf(taya)}’s capture attempts left: '
                '${state.captureAttemptsLeft}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
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