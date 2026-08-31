import 'package:flutter/widgets.dart';
import 'package:packagehub/map/pickup_zone.dart';

class StationMapZoneDefinition {
  final PickupZoneId id;
  final String label;
  final String subtitle;
  final Rect normalizedRect;
  final Alignment badgeAnchor;
  const StationMapZoneDefinition({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.normalizedRect,
    this.badgeAnchor = Alignment.topRight,
  });
}

class StationMapRegionDefinition {
  final StationMapStaticRegionId id;
  final String label;
  final Rect normalizedRect;
  final StationMapRegionType type;
  const StationMapRegionDefinition({
    required this.id,
    required this.label,
    required this.normalizedRect,
    required this.type,
  });
}

const stationMapZones = <StationMapZoneDefinition>[
  StationMapZoneDefinition(
    id: PickupZoneId.c,
    label: 'C 区',
    subtitle: '中通',
    normalizedRect: Rect.fromLTRB(.245, .045, .41, .20),
    badgeAnchor: Alignment(.72, -.72),
  ),
  StationMapZoneDefinition(
    id: PickupZoneId.tz,
    label: 'T / Z 区',
    subtitle: '中通',
    normalizedRect: Rect.fromLTRB(.455, .045, .62, .20),
    badgeAnchor: Alignment(.72, -.72),
  ),
  StationMapZoneDefinition(
    id: PickupZoneId.erhl,
    label: 'E / R / H / L 区',
    subtitle: '圆通 / 菜鸟驿站',
    normalizedRect: Rect.fromLTRB(.01, .235, .205, .47),
    badgeAnchor: Alignment(.72, -.72),
  ),
  StationMapZoneDefinition(
    id: PickupZoneId.s,
    label: 'S 区',
    subtitle: '极兔',
    normalizedRect: Rect.fromLTRB(.245, .24, .41, .44),
    badgeAnchor: Alignment(.72, -.72),
  ),
  StationMapZoneDefinition(
    id: PickupZoneId.d,
    label: 'D 区',
    subtitle: '中通',
    normalizedRect: Rect.fromLTRB(.455, .24, .62, .44),
    badgeAnchor: Alignment(.72, -.72),
  ),
  StationMapZoneDefinition(
    id: PickupZoneId.f,
    label: 'F 区',
    subtitle: '邮政',
    normalizedRect: Rect.fromLTRB(.01, .465, .205, .625),
    badgeAnchor: Alignment(.72, -.72),
  ),
  StationMapZoneDefinition(
    id: PickupZoneId.x,
    label: 'X 区',
    subtitle: '申通',
    normalizedRect: Rect.fromLTRB(.01, .75, .205, .985),
    badgeAnchor: Alignment(.72, -.72),
  ),
  StationMapZoneDefinition(
    id: PickupZoneId.v,
    label: 'V 区',
    subtitle: '韵达',
    normalizedRect: Rect.fromLTRB(.215, .75, .425, .985),
    badgeAnchor: Alignment(.72, -.72),
  ),
  StationMapZoneDefinition(
    id: PickupZoneId.largeA,
    label: 'A 区',
    subtitle: '大件区',
    normalizedRect: Rect.fromLTRB(.47, .77, .64, .94),
    badgeAnchor: Alignment(.72, -.72),
  ),
  StationMapZoneDefinition(
    id: PickupZoneId.jd,
    label: '京东',
    subtitle: '京东物流',
    normalizedRect: Rect.fromLTRB(.856, .572, .978, .657),
    badgeAnchor: Alignment(.72, -.72),
  ),
  StationMapZoneDefinition(
    id: PickupZoneId.sf,
    label: '顺丰',
    subtitle: '顺丰速运',
    normalizedRect: Rect.fromLTRB(.884, .680, .981, .744),
    badgeAnchor: Alignment(.72, -.72),
  ),
];

const lockerMapZones = <StationMapZoneDefinition>[
  StationMapZoneDefinition(
    id: PickupZoneId.lockerA,
    label: '智能柜 A 区',
    subtitle: '智能快递柜',
    normalizedRect: Rect.fromLTRB(.70, .62, .78, .75),
  ),
  StationMapZoneDefinition(
    id: PickupZoneId.lockerB,
    label: '智能柜 B 区',
    subtitle: '智能快递柜',
    normalizedRect: Rect.fromLTRB(.70, .50, .78, .62),
  ),
  StationMapZoneDefinition(
    id: PickupZoneId.lockerC,
    label: '智能柜 C 区',
    subtitle: '智能快递柜',
    normalizedRect: Rect.fromLTRB(.35, .62, .43, .75),
  ),
  StationMapZoneDefinition(
    id: PickupZoneId.lockerD,
    label: '智能柜 D 区',
    subtitle: '智能快递柜',
    normalizedRect: Rect.fromLTRB(.35, .50, .43, .62),
  ),
  StationMapZoneDefinition(
    id: PickupZoneId.lockerE,
    label: '智能柜 E 区',
    subtitle: '智能快递柜',
    normalizedRect: Rect.fromLTRB(.02, .62, .10, .75),
  ),
  StationMapZoneDefinition(
    id: PickupZoneId.lockerF,
    label: '智能柜 F 区',
    subtitle: '智能快递柜',
    normalizedRect: Rect.fromLTRB(.02, .50, .10, .62),
  ),
  StationMapZoneDefinition(
    id: PickupZoneId.lockerG,
    label: '智能柜 G 区',
    subtitle: '智能快递柜',
    normalizedRect: Rect.fromLTRB(.70, .37, .78, .49),
  ),
  StationMapZoneDefinition(
    id: PickupZoneId.lockerH,
    label: '智能柜 H 区',
    subtitle: '智能快递柜',
    normalizedRect: Rect.fromLTRB(.70, .25, .78, .37),
  ),
  StationMapZoneDefinition(
    id: PickupZoneId.lockerI,
    label: '智能柜 I 区',
    subtitle: '智能快递柜',
    normalizedRect: Rect.fromLTRB(.35, .37, .43, .49),
  ),
  StationMapZoneDefinition(
    id: PickupZoneId.lockerJ,
    label: '智能柜 J 区',
    subtitle: '智能快递柜',
    normalizedRect: Rect.fromLTRB(.35, .25, .43, .37),
  ),
];

const stationMapStaticRegions = <StationMapRegionDefinition>[
  StationMapRegionDefinition(
    id: StationMapStaticRegionId.smartLockerArea,
    label: '智能快递柜区',
    normalizedRect: Rect.fromLTRB(.22, .48, .63, .78),
    type: StationMapRegionType.locker,
  ),
  StationMapRegionDefinition(
    id: StationMapStaticRegionId.customerService,
    label: '客服部',
    normalizedRect: Rect.fromLTRB(.683, .31, .82, .38),
    type: StationMapRegionType.service,
  ),
  StationMapRegionDefinition(
    id: StationMapStaticRegionId.manualCenter,
    label: '人工中心',
    normalizedRect: Rect.fromLTRB(.683, .395, .82, .55),
    type: StationMapRegionType.service,
  ),
  StationMapRegionDefinition(
    id: StationMapStaticRegionId.shipping,
    label: '寄件',
    normalizedRect: Rect.fromLTRB(.67, .575, .745, .625),
    type: StationMapRegionType.service,
  ),
  StationMapRegionDefinition(
    id: StationMapStaticRegionId.tracking,
    label: '查件',
    normalizedRect: Rect.fromLTRB(.67, .68, .745, .73),
    type: StationMapRegionType.service,
  ),
  StationMapRegionDefinition(
    id: StationMapStaticRegionId.cainiaoGuoguo,
    label: '菜鸟裹裹',
    normalizedRect: Rect.fromLTRB(.745, .68, .85, .73),
    type: StationMapRegionType.service,
  ),
  StationMapRegionDefinition(
    id: StationMapStaticRegionId.cainiaoStation,
    label: '菜鸟驿站',
    normalizedRect: Rect.fromLTRB(.045, .39, .18, .435),
    type: StationMapRegionType.service,
  ),
  StationMapRegionDefinition(
    id: StationMapStaticRegionId.expressLane,
    label: '快递专用通道',
    normalizedRect: Rect.fromLTRB(.01, .06, .99, .22),
    type: StationMapRegionType.functional,
  ),
  StationMapRegionDefinition(
    id: StationMapStaticRegionId.frontSquare,
    label: '前广场',
    normalizedRect: Rect.fromLTRB(.66, .78, .84, .94),
    type: StationMapRegionType.functional,
  ),
  StationMapRegionDefinition(
    id: StationMapStaticRegionId.unpacking,
    label: '拆件区',
    normalizedRect: Rect.fromLTRB(.845, .835, .985, .95),
    type: StationMapRegionType.functional,
  ),
];
