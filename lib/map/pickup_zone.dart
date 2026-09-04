enum PickupZoneId {
  c,
  tz,
  d,
  s,
  erhl,
  f,
  x,
  v,
  largeA,
  jd,
  sf,
  lockerA,
  lockerB,
  lockerC,
  lockerD,
  lockerE,
  lockerF,
  lockerG,
  lockerH,
  lockerI,
  lockerJ,
  unmapped,
}

extension PickupZoneDisplayName on PickupZoneId {
  String get displayName {
    return switch (this) {
      PickupZoneId.c => 'C 区',
      PickupZoneId.tz => 'T/Z 区',
      PickupZoneId.d => 'D 区',
      PickupZoneId.s => 'S 区',
      PickupZoneId.erhl => 'ERHL 区',
      PickupZoneId.f => 'F 区',
      PickupZoneId.x => 'X 区',
      PickupZoneId.v => 'V 区',
      PickupZoneId.largeA => '大件区',
      PickupZoneId.jd => '京东区',
      PickupZoneId.sf => '顺丰区',
      _ => name,
    };
  }
}

enum StationMapRegionType { pickupZone, locker, service, functional }

enum StationMapStaticRegionId {
  smartLockerArea,
  customerService,
  manualCenter,
  shipping,
  tracking,
  cainiaoGuoguo,
  cainiaoStation,
  frontSquare,
  unpacking,
  expressLane,
}
