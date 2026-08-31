import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:packagehub/map/pickup_zone.dart';
import 'package:packagehub/map/station_map_definition.dart';

void main() {
  test('contains every audited map region exactly once', () {
    expect(
      stationMapZones.map((z) => z.id).toSet().length,
      stationMapZones.length,
    );
    expect(
      lockerMapZones.map((z) => z.id).toSet().length,
      lockerMapZones.length,
    );
    expect(
      stationMapStaticRegions.map((r) => r.id).toSet().length,
      stationMapStaticRegions.length,
    );
    expect(
      stationMapZones.map((z) => z.id),
      containsAll([
        PickupZoneId.c,
        PickupZoneId.tz,
        PickupZoneId.d,
        PickupZoneId.s,
        PickupZoneId.erhl,
        PickupZoneId.f,
        PickupZoneId.x,
        PickupZoneId.v,
        PickupZoneId.largeA,
        PickupZoneId.jd,
        PickupZoneId.sf,
      ]),
    );
    expect(
      lockerMapZones.map((z) => z.id),
      containsAll(
        PickupZoneId.values.where((id) => id.name.startsWith('locker')),
      ),
    );
  });

  test('all normalized geometry is valid and pickup badges are off-center', () {
    void checkRect(Rect rect) {
      expect(rect.left, inInclusiveRange(0, 1));
      expect(rect.top, inInclusiveRange(0, 1));
      expect(rect.right, inInclusiveRange(0, 1));
      expect(rect.bottom, inInclusiveRange(0, 1));
      expect(rect.width, greaterThan(0));
      expect(rect.height, greaterThan(0));
    }

    for (final region in [...stationMapZones, ...lockerMapZones]) {
      checkRect(region.normalizedRect);
    }
    for (final region in stationMapStaticRegions) {
      checkRect(region.normalizedRect);
    }
    for (final zone in stationMapZones) {
      expect(zone.badgeAnchor, isNot(equals(Alignment.center)));
    }
  });

  test('京东 and 顺丰 hotspots are distinct with minimal overlap', () {
    final jd = stationMapZones
        .firstWhere((z) => z.id == PickupZoneId.jd)
        .normalizedRect;
    final sf = stationMapZones
        .firstWhere((z) => z.id == PickupZoneId.sf)
        .normalizedRect;
    final intersection = jd.intersect(sf);
    expect(
      intersection.width * intersection.height,
      lessThan(jd.width * jd.height * .25),
    );
  });
}
