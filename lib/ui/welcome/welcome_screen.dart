import 'package:flutter/material.dart';
import 'package:game_tumbang_preso/core/app_theme.dart';
import 'package:game_tumbang_preso/ui/setup/player_setup_screen.dart';
import 'package:game_tumbang_preso/ui/welcome/how_to_play_sheet.dart';
import 'package:game_tumbang_preso/ui/welcome/widgets/hero_scene.dart';
import 'package:game_tumbang_preso/ui/widgets/chunky_button.dart';

/// Landing page: title, hero illustration, and the two entry points.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _play(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PlayerSetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.skyTop, AppColors.skyBottom],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(top: 40, right: 20, child: _Sun()),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 48 < 0
                          ? 0
                          : constraints.maxHeight - 48,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _Title(),
                            const SizedBox(height: 12),
                            const Text(
                              'A Filipino street game for two players on one '
                              'device.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.ink,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const HeroScene(),
                            const SizedBox(height: 32),
                            ChunkyButton(
                              label: 'Play Game',
                              icon: Icons.play_arrow_rounded,
                              onPressed: () => _play(context),
                            ),
                            const SizedBox(height: 18),
                            ChunkyButton(
                              label: 'How to Play',
                              icon: Icons.help_outline_rounded,
                              filled: false,
                              onPressed: () => showHowToPlay(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Big outlined title: a stroked copy underneath a white fill.
class _Title extends StatelessWidget {
  const _Title();

  static const _text = 'Tumbang\nPreso';

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(
      fontSize: 72,
      height: 0.95,
      fontWeight: FontWeight.w900,
      letterSpacing: -1,
    );
    final outline = base.copyWith(
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.ink,
    );

    return Semantics(
      header: true,
      label: 'Tumbang Preso',
      child: ExcludeSemantics(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Stack(
            children: [
              Text(_text, textAlign: TextAlign.center, style: outline),
              Text(
                _text,
                textAlign: TextAlign.center,
                style: base.copyWith(color: AppColors.paper),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Sun extends StatelessWidget {
  const _Sun();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.sun,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.ink, width: 3),
      ),
    );
  }
}
