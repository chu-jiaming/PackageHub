import 'package:flutter_test/flutter_test.dart';
import 'package:packagehub/map/pickup_zone.dart';
import 'package:packagehub/map/station_pickup_rules.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';

void main() {
  test('public prefix definitions are ordered and complete', () {
    expect(StationPickupRules.prefixRules.map((rule) => rule.prefixes), [
      ['C'],
      ['T', 'Z'],
      ['D'],
      ['S'],
      ['E', 'R', 'H', 'L'],
      ['F'],
      ['X'],
      ['V'],
      ['A'],
    ]);
    expect(StationPickupRules.prefixRules[0].courier, CourierCompany.zto);
    expect(StationPickupRules.prefixRules[0].zone, PickupZoneId.c);
    expect(StationPickupRules.prefixRules[1].zone, PickupZoneId.tz);
    expect(StationPickupRules.prefixRules[4].courier, CourierCompany.yto);
    expect(StationPickupRules.prefixRules[4].zone, PickupZoneId.erhl);
    expect(StationPickupRules.prefixRules[8].courier, isNull);
    expect(StationPickupRules.prefixRules[8].zone, PickupZoneId.largeA);
  });

  test('inference consumes the same public prefix definitions', () {
    final expected = <String, CourierCompany>{
      'C': CourierCompany.zto,
      'T': CourierCompany.zto,
      'Z': CourierCompany.zto,
      'D': CourierCompany.zto,
      'S': CourierCompany.jtexpress,
      'E': CourierCompany.yto,
      'R': CourierCompany.yto,
      'H': CourierCompany.yto,
      'L': CourierCompany.yto,
      'F': CourierCompany.ems,
      'X': CourierCompany.sto,
      'V': CourierCompany.yunda,
    };
    for (final entry in expected.entries) {
      expect(
        StationPickupRules.resolveCourierFromPickupCode('${entry.key}1-2-3'),
        entry.value,
      );
    }
    expect(
      StationPickupRules.resolveCourierFromPickupCode('A1-2-3456'),
      isNull,
    );
  });

  test('courier route definitions preserve explicit courier priority', () {
    expect(
      StationPickupRules.resolveZoneForCourier(CourierCompany.jtexpress, 'Z'),
      PickupZoneId.s,
    );
    expect(
      StationPickupRules.resolveZoneForCourier(
        CourierCompany.jdLogistics,
        null,
      ),
      PickupZoneId.jd,
    );
    expect(
      StationPickupRules.resolveZoneForCourier(CourierCompany.sfExpress, null),
      PickupZoneId.sf,
    );
  });
}
