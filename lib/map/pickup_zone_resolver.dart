import 'package:packagehub/map/pickup_zone.dart';
import 'package:packagehub/models/pickup_credential.dart';
import 'package:packagehub/map/station_pickup_rules.dart';

class PickupZoneResolver {
  const PickupZoneResolver();

  PickupZoneId resolve(PickupCredential credential) {
    final prefix = _normalizePrefix(credential.pickupCode);
    final courierResult = StationPickupRules.resolveZoneForCourier(
      credential.courierCompany,
      prefix,
    );
    if (courierResult != null) return courierResult;
    return StationPickupRules.resolveZoneFromPickupCode(credential.pickupCode);
  }

  String? _normalizePrefix(String? pickupCode) {
    final normalized = pickupCode?.trim().toUpperCase();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized[0];
  }
}
