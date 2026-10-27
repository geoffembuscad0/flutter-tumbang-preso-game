import 'package:flutter/material.dart';
import 'package:game_tumbang_preso/core/app_theme.dart';

/// A white panel with the same thick outline and hard shadow as
/// [ChunkyButton], for grouping content on a screen.
class ChunkyCard extends StatelessWidget {
  const ChunkyCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.ink, width: 3),
        boxShadow: const [
          BoxShadow(color: AppColors.ink, offset: Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }
}
