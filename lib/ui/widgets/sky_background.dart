import 'package:flutter/material.dart';
import 'package:game_tumbang_preso/core/app_theme.dart';

/// The blue sky gradient shared by the game screens.
class SkyBackground extends StatelessWidget {
  const SkyBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.skyTop, AppColors.skyBottom],
          ),
        ),
        child: child,
      ),
    );
  }
}
