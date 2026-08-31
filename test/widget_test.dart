import 'package:flutter_test/flutter_test.dart';
import 'package:packagehub/core/repository/pickup_credential_repository.dart';
import 'package:packagehub/main.dart';
import 'package:packagehub/models/pickup_credential.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';

void main() {
  testWidgets('PackageHub app shows import screenshot action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      PackageHubApp(repository: _EmptyPickupCredentialRepository()),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('PackageHub'), findsOneWidget);
    expect(find.text('添加截图'), findsOneWidget);
  });
}

class _EmptyPickupCredentialRepository
    implements PickupCredentialRepositoryApi {
  @override
  Future<List<PickupCredential>> getAll() async => [];

  @override
  Future<List<PickupCredential>> getPending() async => [];

  @override
  Future<List<PickupCredential>> getPickedUp() async => [];

  @override
  Future<List<PickupCredential>> findByTrackingNumber(
    String trackingNumber,
  ) async {
    return [];
  }

  @override
  Future<List<PickupCredential>> insertAll(
    List<PickupCredentialDraft> drafts,
  ) async {
    return [];
  }

  @override
  Future<PickupCredential> update(PickupCredential credential) async {
    throw UnimplementedError();
  }

  @override
  Future<PickupCredential> markPickedUp(int id) async {
    throw UnimplementedError();
  }

  @override
  Future<PickupCredential> markPending(int id) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteById(int id) async {}

  @override
  Future<List<PickupCredential>> markPickedUpAll(Iterable<int> ids) async {
    return [];
  }

  @override
  Future<List<PickupCredential>> markPendingAll(Iterable<int> ids) async {
    return [];
  }

  @override
  Future<void> deleteAll(Iterable<int> ids) async {}
}
