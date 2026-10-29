import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:game_tumbang_preso/core/app_theme.dart';
import 'package:game_tumbang_preso/domain/domain.dart';
import 'package:game_tumbang_preso/ui/welcome/widgets/can_graphic.dart';
import 'package:game_tumbang_preso/ui/welcome/widgets/slipper_graphic.dart';

/// The can on its patch of dirt and the slipper being thrown at it.
///
/// This only *draws* an outcome the engine already decided: [outcome] says
/// whether the throw hits or misses, and [progress] (0 to 1) says how far the
/// throw has got. A null [outcome] shows the scene before the throw. Animation
/// timing never decides the result.
///
/// A hit sends the slipper into the can, which tips over onto its side. A miss
/// sends the slipper high, past the back of the can, to land beyond it.
class ThrowScene extends StatelessWidget {
  const ThrowScene({super.key, required this.progress, required this.outcome});

  final Animation<double> progress;
  final ThrowOutcome? outcome;

  static const double _width = 360;
  static const double _height = 200;
  static const double _canLeft = 190;
  static const double _canWidth = 70;
  static const double _canHeight = 96;
  static const double _slipperWidth = 76;

  /// The can stands on the dirt patch, which is 44 tall.
  static const double _canBottom = 20;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: _width,
          height: _height,
          child: AnimatedBuilder(
            animation: progress,
            builder: (context, _) => _frame(progress.value),
          ),
        ),
      ),
    );
  }

  Widget _frame(double t) {
    final thrown = outcome != null;
    final hit = outcome == ThrowOutcome.hit;
    final flight = thrown ? Curves.easeInOut.transform(t) : 0.0;

    // The slipper flies left to right on an arc, spinning twice.
    const startX = 12.0;
    final endX = hit ? _canLeft - _slipperWidth - 6 : 276.0;
    final peak = hit ? 56.0 : 170.0;
    final slipperX = startX + (endX - startX) * flight;
    final slipperBottom = 12 + math.sin(math.pi * flight) * peak;
    final slipperAngle = -flight * 4 * math.pi;

    // A hit tips the can over at the end of the flight; a miss only makes it
    // wobble as the slipper passes behind it.
    var canAngle = 0.0;
    if (hit) {
      final k = math.max(0.0, math.min(1.0, (t - 0.78) / 0.22));
      canAngle = Curves.easeIn.transform(k) * (math.pi / 2);
    } else if (thrown && t > 0.55) {
      canAngle = math.sin((t - 0.55) * math.pi * 10) * 0.07 * (1 - t);
    }

    final slipper = Positioned(
      left: slipperX,
      bottom: slipperBottom,
      child: Transform.rotate(
        angle: slipperAngle,
        child: const SlipperGraphic(width: _slipperWidth),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.dirt,
              border: Border.all(color: AppColors.ink, width: 3),
              borderRadius: const BorderRadius.all(Radius.elliptical(180, 22)),
            ),
          ),
        ),
        if (thrown && !hit) slipper,
        Positioned(
          left: _canLeft,
          bottom: _canBottom,
          child: Transform.rotate(
            angle: canAngle,
            alignment: Alignment.bottomRight,
            child: const CanGraphic(width: _canWidth, height: _canHeight),
          ),
        ),
        if (!thrown || hit) slipper,
      ],
    );
  }
}