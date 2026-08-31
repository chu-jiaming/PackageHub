import 'package:packagehub/map/pickup_zone.dart';
import 'package:packagehub/models/pickup_credential.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';
import 'package:packagehub/map/station_pickup_rules.dart';

class PickupZoneResolver {
  const PickupZoneResolver();

  PickupZoneId resolve(PickupCredential credential) {
    final prefix = _normalizePrefix(credential.pickupCode);
    final courierResult = _resolveByCourier(credential.courierCompany, prefix);
    if (courierResult != null) return courierResult;
    return StationPickupRules.resolveZoneFromPickupCode(credential.pickupCode);
  }

  String? _normalizePrefix(String? pickupCode) {
    final normalized = pickupCode?.trim().toUpperCase();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized[0];
  }

  PickupZoneId? _resolveByCourier(CourierCompany courier, String? prefix) {
    switch (courier) {
      case CourierCompany.sfExpress:
        return PickupZoneId.sf;
      case CourierCompany.jdLogistics:
        return PickupZoneId.jd;
      case CourierCompany.sto:
        return PickupZoneId.x;
      case CourierCompany.yunda:
        return PickupZoneId.v;
      case CourierCompany.jtexpress:
        return PickupZoneId.s;
      case CourierCompany.chinaPost:
      case CourierCompany.ems:
        return PickupZoneId.f;
      case CourierCompany.yto:
        return PickupZoneId.erhl;
      case CourierCompany.zto:
        return switch (prefix) {
          'C' => PickupZoneId.c,
          'T' || 'Z' => PickupZoneId.tz,
          'D' => PickupZoneId.d,
          _ => PickupZoneId.unmapped,
        };
      case CourierCompany.unknown:
        return null;
      default:
        return null;
    }
  }
}
