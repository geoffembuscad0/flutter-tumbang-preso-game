import 'package:flutter/material.dart';
import 'package:game_tumbang_preso/core/app_theme.dart';
import 'package:game_tumbang_preso/domain/domain.dart';
import 'package:game_tumbang_preso/ui/widgets/chunky_card.dart';
import 'package:game_tumbang_preso/ui/widgets/player_id_label.dart';
import 'package:game_tumbang_preso/ui/widgets/sky_background.dart';

/// Placeholder until the coin toss is built. It already receives the players
/// from setup and shows who got which number.
class CoinTossScreen extends StatelessWidget {
  const CoinTossScreen({super.key, required this.players});

  final Players players;

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
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: ChunkyCard(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Coin toss',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${PlayerId.one.label}: ${players.one.name}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${PlayerId.two.label}: ${players.two.name}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Player 1 will call heads or tails here next.',
                            ),
                          ],
                        ),
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
