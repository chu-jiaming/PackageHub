import 'package:packagehub/map/pickup_zone.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';

class StationPickupRule {
  final List<String> prefixes;
  final CourierCompany? courier;
  final PickupZoneId zone;

  const StationPickupRule({
    required this.prefixes,
    required this.courier,
    required this.zone,
  });

  String get prefixLabel => prefixes.join(' / ');
}

class StationCourierRouteRule {
  final CourierCompany courier;
  final PickupZoneId? fixedZone;
  final bool requiresPrefixDisambiguation;

  const StationCourierRouteRule({
    required this.courier,
    required this.fixedZone,
    required this.requiresPrefixDisambiguation,
  });

  String get zoneLabel {
    if (fixedZone != null) return fixedZone!.displayName;
    final prefixes = StationPickupRules.prefixRules
        .where((rule) => rule.courier == courier)
        .map((rule) => rule.prefixLabel)
        .join('、');
    return prefixes.isEmpty ? '根据 prefix 分区' : '按 $prefixes 分区';
  }
}

class StationPickupRules {
  static const List<StationPickupRule> prefixRules = [
    StationPickupRule(
      prefixes: ['C'],
      courier: CourierCompany.zto,
      zone: PickupZoneId.c,
    ),
    StationPickupRule(
      prefixes: ['T', 'Z'],
      courier: CourierCompany.zto,
      zone: PickupZoneId.tz,
    ),
    StationPickupRule(
      prefixes: ['D'],
      courier: CourierCompany.zto,
      zone: PickupZoneId.d,
    ),
    StationPickupRule(
      prefixes: ['S'],
      courier: CourierCompany.jtexpress,
      zone: PickupZoneId.s,
    ),
    StationPickupRule(
      prefixes: ['E', 'R', 'H', 'L'],
      courier: CourierCompany.yto,
      zone: PickupZoneId.erhl,
    ),
    StationPickupRule(
      prefixes: ['F'],
      courier: CourierCompany.ems,
      zone: PickupZoneId.f,
    ),
    StationPickupRule(
      prefixes: ['X'],
      courier: CourierCompany.sto,
      zone: PickupZoneId.x,
    ),
    StationPickupRule(
      prefixes: ['V'],
      courier: CourierCompany.yunda,
      zone: PickupZoneId.v,
    ),
    StationPickupRule(
      prefixes: ['A'],
      courier: null,
      zone: PickupZoneId.largeA,
    ),
  ];

  // Keep this order aligned with the production courier routing behavior.
  static const List<StationCourierRouteRule> courierRouteRules = [
    StationCourierRouteRule(
      courier: CourierCompany.zto,
      fixedZone: null,
      requiresPrefixDisambiguation: true,
    ),
    StationCourierRouteRule(
      courier: CourierCompany.yto,
      fixedZone: PickupZoneId.erhl,
      requiresPrefixDisambiguation: false,
    ),
    StationCourierRouteRule(
      courier: CourierCompany.jtexpress,
      fixedZone: PickupZoneId.s,
      requiresPrefixDisambiguation: false,
    ),
    StationCourierRouteRule(
      courier: CourierCompany.ems,
      fixedZone: PickupZoneId.f,
      requiresPrefixDisambiguation: false,
    ),
    StationCourierRouteRule(
      courier: CourierCompany.chinaPost,
      fixedZone: PickupZoneId.f,
      requiresPrefixDisambiguation: false,
    ),
    StationCourierRouteRule(
      courier: CourierCompany.sto,
      fixedZone: PickupZoneId.x,
      requiresPrefixDisambiguation: false,
    ),
    StationCourierRouteRule(
      courier: CourierCompany.yunda,
      fixedZone: PickupZoneId.v,
      requiresPrefixDisambiguation: false,
    ),
    StationCourierRouteRule(
      courier: CourierCompany.jdLogistics,
      fixedZone: PickupZoneId.jd,
      requiresPrefixDisambiguation: false,
    ),
    StationCourierRouteRule(
      courier: CourierCompany.sfExpress,
      fixedZone: PickupZoneId.sf,
      requiresPrefixDisambiguation: false,
    ),
  ];

  // Backward-compatible alias for callers that used the original name.
  static const List<StationPickupRule> rules = prefixRules;

  static CourierCompany? resolveCourierFromPickupCode(String? pickupCode) {
    return _ruleFor(pickupCode)?.courier;
  }

  static PickupZoneId resolveZoneFromPickupCode(String? pickupCode) {
    return _ruleFor(pickupCode)?.zone ?? PickupZoneId.unmapped;
  }

  static StationPickupRule? _ruleFor(String? pickupCode) {
    final prefix = pickupCode?.trim().toUpperCase();
    if (prefix == null || prefix.isEmpty) return null;
    for (final rule in prefixRules) {
      if (rule.prefixes.contains(prefix[0])) return rule;
    }
    return null;
  }

  static StationCourierRouteRule? routeForCourier(CourierCompany courier) {
    for (final route in courierRouteRules) {
      if (route.courier == courier) return route;
    }
    return null;
  }

  static PickupZoneId? resolveZoneForCourier(
    CourierCompany courier,
    String? prefix,
  ) {
    final route = routeForCourier(courier);
    if (route == null) return null;
    if (route.fixedZone != null) return route.fixedZone;
    if (!route.requiresPrefixDisambiguation || prefix == null) {
      return PickupZoneId.unmapped;
    }
    for (final rule in prefixRules) {
      if (rule.courier == courier && rule.prefixes.contains(prefix)) {
        return rule.zone;
      }
    }
    return PickupZoneId.unmapped;
  }
}
