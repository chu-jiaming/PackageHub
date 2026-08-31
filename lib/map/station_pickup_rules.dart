import 'package:packagehub/map/pickup_zone.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';

class StationPickupRule {
  final Set<String> prefixes;
  final CourierCompany? courier;
  final PickupZoneId zone;

  const StationPickupRule({
    required this.prefixes,
    required this.courier,
    required this.zone,
  });
}

class StationPickupRules {
  static const List<StationPickupRule> rules = [
    StationPickupRule(
      prefixes: {'C'},
      courier: CourierCompany.zto,
      zone: PickupZoneId.c,
    ),
    StationPickupRule(
      prefixes: {'T', 'Z'},
      courier: CourierCompany.zto,
      zone: PickupZoneId.tz,
    ),
    StationPickupRule(
      prefixes: {'D'},
      courier: CourierCompany.zto,
      zone: PickupZoneId.d,
    ),
    StationPickupRule(
      prefixes: {'S'},
      courier: CourierCompany.jtexpress,
      zone: PickupZoneId.s,
    ),
    StationPickupRule(
      prefixes: {'E', 'R', 'H', 'L'},
      courier: CourierCompany.yto,
      zone: PickupZoneId.erhl,
    ),
    StationPickupRule(
      prefixes: {'F'},
      courier: CourierCompany.ems,
      zone: PickupZoneId.f,
    ),
    StationPickupRule(
      prefixes: {'X'},
      courier: CourierCompany.sto,
      zone: PickupZoneId.x,
    ),
    StationPickupRule(
      prefixes: {'V'},
      courier: CourierCompany.yunda,
      zone: PickupZoneId.v,
    ),
    StationPickupRule(
      prefixes: {'A'},
      courier: null,
      zone: PickupZoneId.largeA,
    ),
  ];

  static CourierCompany? resolveCourierFromPickupCode(String? pickupCode) {
    return _ruleFor(pickupCode)?.courier;
  }

  static PickupZoneId resolveZoneFromPickupCode(String? pickupCode) {
    return _ruleFor(pickupCode)?.zone ?? PickupZoneId.unmapped;
  }

  static StationPickupRule? _ruleFor(String? pickupCode) {
    final prefix = pickupCode?.trim().toUpperCase();
    if (prefix == null || prefix.isEmpty) return null;
    for (final rule in rules) {
      if (rule.prefixes.contains(prefix[0])) return rule;
    }
    return null;
  }
}
