import 'package:flutter/material.dart';
import 'package:game_tumbang_preso/core/app_theme.dart';
import 'package:game_tumbang_preso/ui/welcome/widgets/can_graphic.dart';
import 'package:game_tumbang_preso/ui/welcome/widgets/slipper_graphic.dart';

/// The landing-page illustration: a can wobbling on a patch of dirt with a
/// slipper lying next to it. The wobble is the only moving element, and it
/// stays still when the system asks to reduce motion.
class HeroScene extends StatefulWidget {
  const HeroScene({super.key});

  @override
  State<HeroScene> createState() => _HeroSceneState();
}

class _HeroSceneState extends State<HeroScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  late final Animation<double> _tilt = Tween<double>(begin: -0.05, end: 0.05)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 0.5; // upright
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 300,
          height: 190,
          child: Stack(
            alignment: Alignment.bottomCenter,
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
                    borderRadius: const BorderRadius.all(
                      Radius.elliptical(150, 22),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                child: AnimatedBuilder(
                  animation: _tilt,
                  builder: (context, child) => Transform.rotate(
                    angle: _tilt.value,
                    alignment: Alignment.bottomCenter,
                    child: child,
                  ),
                  child: const CanGraphic(),
                ),
              ),
              Positioned(
                left: 12,
                bottom: 8,
                child: Transform.rotate(
                  angle: -0.25,
                  child: const SlipperGraphic(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
