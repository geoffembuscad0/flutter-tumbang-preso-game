import 'package:flutter/material.dart';

/// Colour tokens for the whole game.
///
/// Every shape on screen is built from these, so when real artwork arrives
/// the look can be changed in one place.
abstract final class AppColors {
  static const skyTop = Color(0xFF2E9BF0);
  static const skyBottom = Color(0xFFBFE7FF);
  static const sun = Color(0xFFFFD23F);
  static const dirt = Color(0xFFD39A5B);
  static const canRed = Color(0xFFD62839);
  static const canRedDark = Color(0xFF9E1B2A);
  static const metal = Color(0xFFE6EAF0);
  static const slipper = Color(0xFF22B573);
  static const slipperDark = Color(0xFF14804F);
  static const strap = Color(0xFFFFD23F);
  static const ink = Color(0xFF14213D);
  static const paper = Color(0xFFFFFFFF);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.canRed).copyWith(
    primary: AppColors.ink,
    onPrimary: AppColors.paper,
    surface: AppColors.paper,
    onSurface: AppColors.ink,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
  );
}
