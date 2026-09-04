import 'package:flutter/material.dart';
import 'package:packagehub/design_system/tokens/ph_colors.dart';

abstract final class PHTypography {
  static const title1 = TextStyle(
    fontSize: 28,
    height: 34 / 28,
    letterSpacing: -0.4,
    color: PHColors.textPrimary,
  );

  static const footnote = TextStyle(
    fontSize: 13,
    height: 18 / 13,
    color: PHColors.textSecondary,
  );

  static const caption2 = TextStyle(
    fontSize: 11,
    height: 13 / 11,
    color: PHColors.textTertiary,
  );
}
