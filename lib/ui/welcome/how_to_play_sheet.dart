import 'package:flutter/material.dart';
import 'package:game_tumbang_preso/core/app_theme.dart';
import 'package:game_tumbang_preso/ui/widgets/chunky_button.dart';

/// Opens the "How to Play" bottom sheet.
Future<void> showHowToPlay(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.paper,
    constraints: const BoxConstraints(maxWidth: 560),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      side: BorderSide(color: AppColors.ink, width: 3),
    ),
    builder: (context) => const _HowToPlayContent(),
  );
}

class _HowToPlayContent extends StatelessWidget {
  const _HowToPlayContent();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'How to play',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          const _Rule(
            icon: Icons.swap_horiz_rounded,
            title: 'Two roles',
            body:
                'The attacker throws the slipper. The taya guards the can. '
                'Roles swap during the game.',
          ),
          const _Rule(
            icon: Icons.casino_rounded,
            title: 'The throw',
            body: 'Every throw randomly hits or misses the can.',
          ),
          const _Rule(
            icon: Icons.check_circle_rounded,
            title: 'If it hits',
            body:
                'The attacker scores 1 point. The taya then guards the can or '
                'tries to catch the attacker. A catch scores 2 points and '
                'swaps roles.',
          ),
          const _Rule(
            icon: Icons.close_rounded,
            title: 'If it misses',
            body:
                'The taya can try to capture the slipper for 1 point, or let '
                'the attacker throw again. Each turn as taya allows 3 capture '
                'attempts.',
          ),
          const _Rule(
            icon: Icons.phone_android_rounded,
            title: 'Pass the device',
            body:
                'Private choices are made on a pass-the-device screen, so the '
                'other player cannot peek.',
          ),
          const _Rule(
            icon: Icons.emoji_events_rounded,
            title: 'Winning',
            body:
                'First to 10 points wins. If both players reach 10 together, '
                'Jack-en-Poy decides it.',
          ),
          const SizedBox(height: 8),
          ChunkyButton(
            label: 'Got it',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.ink,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.paper, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(body, style: textTheme.bodyMedium?.copyWith(height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
