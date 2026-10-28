import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:game_tumbang_preso/core/app_theme.dart';
import 'package:game_tumbang_preso/domain/domain.dart';

const _coinInner = Color(0xFFFFE680);
/*
One side of the coin, drawn with styled circles. A null [side] shows a
question mark, for before the toss.
*/
class CoinFace extends StatelessWidget {
  const CoinFace({super.key, this.side, this.size = 150});

  final CoinSide? side;
  final double size;

  @override
  Widget build(BuildContext context) {
    final symbol = switch (side) {
      CoinSide.heads => 'H',
      CoinSide.tails => 'T',
      null => '?',
    };

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.09),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.sun,
        border: Border.all(color: AppColors.ink, width: 4),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _coinInner,
          border: Border.all(color: AppColors.ink, width: 2),
        ),
        child: Center(
          child: Text(
            symbol,
            style: TextStyle(
              fontSize: size * 0.42,
              height: 1,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
/*
A coin turning end over end.

[angle] is the rotation in radians around the horizontal axis: a multiple
of 2π shows heads and an odd multiple of π shows tails. [lift] raises the
coin off the ground, in logical pixels, to sell the toss.
*/
class CoinFlip extends StatelessWidget {
  const CoinFlip({
    super.key,
    required this.angle,
    this.lift = 0,
    this.size = 150,
  });

  final double angle;
  final double lift;
  final double size;

  @override
  Widget build(BuildContext context) {
    final showingHeads = math.cos(angle) >= 0;

    return Transform.translate(
      offset: Offset(0, -lift),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.002)
          ..rotateX(angle),
        child: showingHeads
            ? CoinFace(side: CoinSide.heads, size: size)
            // Past the edge-on point the back is showing, and it would
            // appear upside down, so turn it back over.
            : Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationX(math.pi),
                child: CoinFace(side: CoinSide.tails, size: size),
              ),
      ),
    );
  }
}