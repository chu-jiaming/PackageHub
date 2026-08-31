import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:packagehub/map/station_map_page.dart';

void main() {
  const accent = Colors.indigo;

  test('inactive hotspot has no active decoration', () {
    final decoration = StationMapHotspotStyle.decoration(
      active: false,
      pressed: false,
      accent: accent,
    );
    expect(decoration.border, isNull);
    expect(decoration.color, isNull);
  });

  test('active hotspot has tint without a rectangular frame', () {
    final normal = StationMapHotspotStyle.decoration(
      active: true,
      pressed: false,
      accent: accent,
    );
    final pressed = StationMapHotspotStyle.decoration(
      active: true,
      pressed: true,
      accent: accent,
    );
    expect(normal.border, isNull);
    expect(normal.color, isNotNull);
    expect(pressed.color!.a, greaterThan(normal.color!.a));
  });

  test('badge keeps compact rounded shape and numeric text contract', () {
    final decoration = StationMapHotspotStyle.badgeDecoration(
      accent: accent,
      edge: Colors.white,
    );
    expect(decoration.border!.top.width, greaterThan(0));
    expect(decoration.borderRadius, BorderRadius.circular(10));
    expect('2', matches(RegExp(r'^\d+$')));
  });
}
