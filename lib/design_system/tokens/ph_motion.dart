import 'package:flutter/material.dart';

abstract final class PHMotion {
  static const fast = Duration(milliseconds: 160);
  static const standard = Duration(milliseconds: 220);
  static const standardCurve = Curves.easeOutCubic;
  static const reverseCurve = Curves.easeInCubic;

  static Duration duration(BuildContext context, [Duration value = standard]) {
    return MediaQuery.disableAnimationsOf(context) ? Duration.zero : value;
  }
}
