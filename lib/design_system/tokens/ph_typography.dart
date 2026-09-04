import 'package:flutter/material.dart';

abstract final class PHTypography {
  static const largeTitle = TextStyle(
    fontSize: 34,
    height: 41 / 34,
    letterSpacing: -0.4,
    fontWeight: FontWeight.w700,
  );

  static const title1 = TextStyle(
    fontSize: 28,
    height: 34 / 28,
    letterSpacing: -0.4,
    fontWeight: FontWeight.w700,
  );

  static const title2 = TextStyle(
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w600,
  );

  static const title3 = TextStyle(
    fontSize: 20,
    height: 25 / 20,
    fontWeight: FontWeight.w600,
  );

  static const body = TextStyle(fontSize: 17, height: 22 / 17);

  static const bodyEmphasis = TextStyle(
    fontSize: 17,
    height: 22 / 17,
    fontWeight: FontWeight.w600,
  );

  static const subheadline = TextStyle(fontSize: 15, height: 20 / 15);

  static const subheadlineEmphasis = TextStyle(
    fontSize: 15,
    height: 20 / 15,
    fontWeight: FontWeight.w600,
  );

  static const footnote = TextStyle(fontSize: 13, height: 18 / 13);

  static const caption1 = TextStyle(fontSize: 12, height: 16 / 12);

  static const caption2 = TextStyle(fontSize: 11, height: 13 / 11);

  static const pickupCode = TextStyle(
    fontSize: 32,
    height: 38 / 32,
    fontWeight: FontWeight.w700,
  );

  static const controlLabel = TextStyle(
    fontSize: 15,
    height: 20 / 15,
    fontWeight: FontWeight.w500,
  );
}
