import 'package:flutter/material.dart';
import 'package:game_tumbang_preso/core/app_theme.dart';

/// The can, built from plain styled boxes: metal rims, a red body and a
/// white label band. No image assets needed.
class CanGraphic extends StatelessWidget {
  const CanGraphic({super.key, this.width = 96, this.height = 132});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final rimHeight = height * 0.07;

    return SizedBox(
      width: width,
      height: height,
      child: Column(
        children: [
          _Rim(height: rimHeight, isTop: true),
          Expanded(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.canRedDark,
                    AppColors.canRed,
                    AppColors.canRed,
                    AppColors.canRedDark,
                  ],
                  stops: [0, 0.3, 0.7, 1],
                ),
                border: Border.symmetric(
                  vertical: BorderSide(color: AppColors.ink, width: 3),
                ),
              ),
              child: Center(
                child: Container(
                  width: double.infinity,
                  height: height * 0.38,
                  decoration: const BoxDecoration(
                    color: AppColors.paper,
                    border: Border.symmetric(
                      horizontal: BorderSide(color: AppColors.ink, width: 3),
                    ),
                  ),
                  child: Icon(
                    Icons.star_rounded,
                    color: AppColors.canRed,
                    size: width * 0.32,
                  ),
                ),
              ),
            ),
          ),
          _Rim(height: rimHeight, isTop: false),
        ],
      ),
    );
  }
}

class _Rim extends StatelessWidget {
  const _Rim({required this.height, required this.isTop});

  final double height;
  final bool isTop;

  @override
  Widget build(BuildContext context) {
    const corner = Radius.circular(10);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.metal,
        border: Border.all(color: AppColors.ink, width: 3),
        borderRadius: isTop
            ? const BorderRadius.vertical(top: corner)
            : const BorderRadius.vertical(bottom: corner),
      ),
    );
  }
}
