import 'package:packagehub/models/pickup_credential.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';

class CourierCredentialGroup {
  final CourierCompany courierCompany;
  final List<PickupCredential> credentials;

  const CourierCredentialGroup({
    required this.courierCompany,
    required this.credentials,
  });
}

List<CourierCredentialGroup> groupCredentialsByCourier(
  Iterable<PickupCredential> credentials,
) {
  final grouped = <CourierCompany, List<PickupCredential>>{};

  for (final credential in credentials) {
    grouped
        .putIfAbsent(credential.courierCompany, () => <PickupCredential>[])
        .add(credential);
  }

  final groups = grouped.entries.map((entry) {
    return CourierCredentialGroup(
      courierCompany: entry.key,
      credentials: entry.value,
    );
  }).toList();

  groups.sort((a, b) {
    return a.courierCompany.sortOrder.compareTo(b.courierCompany.sortOrder);
  });

  return groups;
}

extension CourierCompanyUi on CourierCompany {
  int get sortOrder {
    return switch (this) {
      CourierCompany.sfExpress => 0,
      CourierCompany.jdLogistics => 1,
      CourierCompany.zto => 2,
      CourierCompany.yto => 3,
      CourierCompany.sto => 4,
      CourierCompany.yunda => 5,
      CourierCompany.jtexpress => 6,
      CourierCompany.ems => 7,
      CourierCompany.chinaPost => 8,
      CourierCompany.deppon => 9,
      CourierCompany.cainiaoExpress => 10,
      CourierCompany.bestExpress => 11,
      CourierCompany.other => 12,
      CourierCompany.unknown => 13,
    };
  }
}
