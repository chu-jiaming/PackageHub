import 'package:flutter_test/flutter_test.dart';
import 'package:packagehub/features/home/credential_grouping.dart';
import 'package:packagehub/models/pickup_credential.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';

void main() {
  group('groupCredentialsByCourier', () {
    test('groups 3 J&T credentials and 2 SF credentials into 2 groups', () {
      final groups = groupCredentialsByCourier([
        _credential(id: 1, courierCompany: CourierCompany.jtexpress),
        _credential(id: 2, courierCompany: CourierCompany.sfExpress),
        _credential(id: 3, courierCompany: CourierCompany.jtexpress),
        _credential(id: 4, courierCompany: CourierCompany.sfExpress),
        _credential(id: 5, courierCompany: CourierCompany.jtexpress),
      ]);

      expect(groups, hasLength(2));
      expect(groups.map((group) => group.courierCompany), [
        CourierCompany.sfExpress,
        CourierCompany.jtexpress,
      ]);
    });

    test('J&T group size is 3', () {
      final groups = groupCredentialsByCourier([
        _credential(id: 1, courierCompany: CourierCompany.jtexpress),
        _credential(id: 2, courierCompany: CourierCompany.jtexpress),
        _credential(id: 3, courierCompany: CourierCompany.sfExpress),
        _credential(id: 4, courierCompany: CourierCompany.jtexpress),
      ]);

      final jtexpress = groups.singleWhere(
        (group) => group.courierCompany == CourierCompany.jtexpress,
      );

      expect(jtexpress.credentials, hasLength(3));
    });

    test('SF group size is 2', () {
      final groups = groupCredentialsByCourier([
        _credential(id: 1, courierCompany: CourierCompany.sfExpress),
        _credential(id: 2, courierCompany: CourierCompany.jtexpress),
        _credential(id: 3, courierCompany: CourierCompany.sfExpress),
      ]);

      final sfExpress = groups.singleWhere(
        (group) => group.courierCompany == CourierCompany.sfExpress,
      );

      expect(sfExpress.credentials, hasLength(2));
    });

    test('unknown courier remains in its own group', () {
      final groups = groupCredentialsByCourier([
        _credential(id: 1, courierCompany: CourierCompany.unknown),
        _credential(id: 2, courierCompany: CourierCompany.sfExpress),
      ]);

      final unknown = groups.singleWhere(
        (group) => group.courierCompany == CourierCompany.unknown,
      );

      expect(unknown.credentials.single.id, 1);
    });

    test('keeps input order inside each courier group', () {
      final groups = groupCredentialsByCourier([
        _credential(id: 3, courierCompany: CourierCompany.jtexpress),
        _credential(id: 1, courierCompany: CourierCompany.sfExpress),
        _credential(id: 2, courierCompany: CourierCompany.jtexpress),
        _credential(id: 4, courierCompany: CourierCompany.jtexpress),
      ]);

      final jtexpress = groups.singleWhere(
        (group) => group.courierCompany == CourierCompany.jtexpress,
      );

      expect(jtexpress.credentials.map((credential) => credential.id), [
        3,
        2,
        4,
      ]);
    });

    test('sorts unknown courier last', () {
      final groups = groupCredentialsByCourier([
        _credential(id: 1, courierCompany: CourierCompany.unknown),
        _credential(id: 2, courierCompany: CourierCompany.jtexpress),
        _credential(id: 3, courierCompany: CourierCompany.sfExpress),
      ]);

      expect(groups.last.courierCompany, CourierCompany.unknown);
    });
  });
}

PickupCredential _credential({
  required int id,
  required CourierCompany courierCompany,
}) {
  final now = DateTime(2026);
  return PickupCredential(
    id: id,
    courierCompany: courierCompany,
    trackingNumber: 'TRACK-$id',
    pickupCode: 'CODE-$id',
    status: PickupStatus.pending,
    sourcePlatform: PackagePlatform.pinduoduo,
    createdAt: now,
    updatedAt: now,
  );
}
