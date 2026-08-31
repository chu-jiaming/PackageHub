import 'package:flutter_test/flutter_test.dart';
import 'package:packagehub/map/pickup_zone.dart';
import 'package:packagehub/map/pickup_zone_resolver.dart';
import 'package:packagehub/map/station_pickup_rules.dart';
import 'package:packagehub/models/pickup_credential.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';

void main() {
  final resolver = const PickupZoneResolver();
  PickupCredential credential(
    String? code, [
    CourierCompany courier = CourierCompany.unknown,
  ]) => PickupCredential(
    courierCompany: courier,
    pickupCode: code,
    status: PickupStatus.unknown,
    sourcePlatform: PackagePlatform.unknown,
    createdAt: DateTime(2020),
    updatedAt: DateTime(2020),
  );
  final cases = <String?, PickupZoneId>{
    'C1-2-3': PickupZoneId.c,
    'c1-2-3': PickupZoneId.c,
    'T1-2-3': PickupZoneId.tz,
    'Z5-2-1350': PickupZoneId.tz,
    't1-2-3': PickupZoneId.tz,
    'z1-2-3': PickupZoneId.tz,
    'TZ1-2-3': PickupZoneId.tz,
    'D1-2-3': PickupZoneId.d,
    'S1-2-3': PickupZoneId.s,
    'E1-2-3': PickupZoneId.erhl,
    'R1-2-3': PickupZoneId.erhl,
    'H1-2-3': PickupZoneId.erhl,
    'L1-2-3': PickupZoneId.erhl,
    'F1-2-3': PickupZoneId.f,
    'X1-2-3': PickupZoneId.x,
    'V1-2-3': PickupZoneId.v,
    'A1-2-3': PickupZoneId.largeA,
    'K1-2-3': PickupZoneId.unmapped,
    'Q1-2-3': PickupZoneId.unmapped,
    null: PickupZoneId.unmapped,
    '': PickupZoneId.unmapped,
    '   ': PickupZoneId.unmapped,
  };
  for (final entry in cases.entries) {
    test(
      'resolves ${entry.key}',
      () => expect(resolver.resolve(credential(entry.key)), entry.value),
    );
  }
  test('A, C and D never resolve to locker zones', () {
    expect(resolver.resolve(credential('A1')), isNot(PickupZoneId.lockerA));
    expect(resolver.resolve(credential('C1')), isNot(PickupZoneId.lockerC));
    expect(resolver.resolve(credential('D1')), isNot(PickupZoneId.lockerD));
  });

  test('single-zone couriers win over conflicting prefixes', () {
    expect(
      resolver.resolve(credential('316-5-5597', CourierCompany.sto)),
      PickupZoneId.x,
    );
    expect(
      resolver.resolve(credential(null, CourierCompany.sto)),
      PickupZoneId.x,
    );
    expect(
      resolver.resolve(credential('', CourierCompany.sto)),
      PickupZoneId.x,
    );
    expect(
      resolver.resolve(credential('Z5-2-1350', CourierCompany.sto)),
      PickupZoneId.x,
    );
    expect(
      resolver.resolve(credential('Z5-2-1350', CourierCompany.jtexpress)),
      PickupZoneId.s,
    );
    expect(
      resolver.resolve(credential('C1', CourierCompany.yunda)),
      PickupZoneId.v,
    );
    expect(
      resolver.resolve(credential('123', CourierCompany.yto)),
      PickupZoneId.erhl,
    );
    expect(
      resolver.resolve(credential('X1', CourierCompany.sfExpress)),
      PickupZoneId.sf,
    );
    for (final code in ['123-4-5678', null, 'X1-123']) {
      expect(
        resolver.resolve(credential(code, CourierCompany.jdLogistics)),
        PickupZoneId.jd,
      );
    }
  });

  test('ZTO requires a known zone prefix', () {
    expect(
      resolver.resolve(credential('C1', CourierCompany.zto)),
      PickupZoneId.c,
    );
    expect(
      resolver.resolve(credential('T1', CourierCompany.zto)),
      PickupZoneId.tz,
    );
    expect(
      resolver.resolve(credential('Z5-2-1350', CourierCompany.zto)),
      PickupZoneId.tz,
    );
    expect(
      resolver.resolve(credential('D1', CourierCompany.zto)),
      PickupZoneId.d,
    );
    expect(
      resolver.resolve(credential('316-5-5597', CourierCompany.zto)),
      PickupZoneId.unmapped,
    );
    expect(
      resolver.resolve(credential(null, CourierCompany.zto)),
      PickupZoneId.unmapped,
    );
  });

  test('shared station rules expose courier and zone mappings', () {
    expect(
      StationPickupRules.resolveCourierFromPickupCode('D1-4-2586'),
      CourierCompany.zto,
    );
    expect(
      StationPickupRules.resolveCourierFromPickupCode('A1-2-3456'),
      isNull,
    );
    expect(
      StationPickupRules.resolveZoneFromPickupCode('D1-4-2586'),
      PickupZoneId.d,
    );
  });
}
