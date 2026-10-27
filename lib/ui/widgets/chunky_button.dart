import 'package:flutter/material.dart';
import 'package:game_tumbang_preso/core/app_theme.dart';

/// A thick, outlined button with a hard shadow that presses down when tapped.
///
/// Reusable across every screen. [filled] is the primary (red) style,
/// otherwise the button is white.
class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.filled = true,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool filled;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  static const _depth = 6.0;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final background = widget.filled ? AppColors.canRed : AppColors.paper;
    final foreground = widget.filled ? AppColors.paper : AppColors.ink;
    final radius = BorderRadius.circular(20);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, _pressed ? _depth : 0, 0),
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.ink,
            offset: Offset(0, _pressed ? 0 : _depth),
          ),
        ],
      ),
      child: Material(
        color: background,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: const BorderSide(color: AppColors.ink, width: 3),
        ),
        child: InkWell(
          onTap: widget.onPressed,
          onHighlightChanged: (value) => setState(() => _pressed = value),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: foreground, size: 26),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
