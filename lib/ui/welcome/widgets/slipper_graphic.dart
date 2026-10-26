import 'package:flutter/material.dart';
import 'package:game_tumbang_preso/core/app_theme.dart';

/// A flip-flop drawn with a [CustomPaint]: a green sole with a visible
/// thickness and a yellow V-strap.
class SlipperGraphic extends StatelessWidget {
  const SlipperGraphic({super.key, this.width = 124});

  final double width;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, width * 0.5),
      painter: const _SlipperPainter(),
    );
  }
}

class _SlipperPainter extends CustomPainter {
  const _SlipperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final thickness = size.height * 0.16;
    final h = size.height - thickness;

    final sole = Path()
      ..moveTo(w * 0.05, h * 0.5)
      ..cubicTo(w * 0.05, h * 0.12, w * 0.30, h * 0.10, w * 0.50, h * 0.08)
      ..cubicTo(w * 0.80, h * 0.02, w * 1.00, h * 0.20, w * 1.00, h * 0.50)
      ..cubicTo(w * 1.00, h * 0.80, w * 0.80, h * 0.98, w * 0.50, h * 0.92)
      ..cubicTo(w * 0.30, h * 0.90, w * 0.05, h * 0.88, w * 0.05, h * 0.50)
      ..close();

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round
      ..color = AppColors.ink;

    // Underside first, so the sole appears to have thickness.
    final underside = sole.shift(Offset(0, thickness));
    canvas.drawPath(underside, Paint()..color = AppColors.slipperDark);
    canvas.drawPath(underside, outline);

    canvas.drawPath(sole, Paint()..color = AppColors.slipper);
    canvas.drawPath(sole, outline);

    final strap = Path()
      ..moveTo(w * 0.42, h * 0.22)
      ..lineTo(w * 0.68, h * 0.50)
      ..lineTo(w * 0.42, h * 0.78);
    final strapWidth = h * 0.17;

    canvas.drawPath(
      strap,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = strapWidth + 6
        ..color = AppColors.ink,
    );
    canvas.drawPath(
      strap,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = strapWidth
        ..color = AppColors.strap,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
