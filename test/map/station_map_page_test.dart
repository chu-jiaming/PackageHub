import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:packagehub/core/repository/pickup_credential_repository.dart';
import 'package:packagehub/map/station_map_page.dart';
import 'package:packagehub/models/pickup_credential.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';

class _EmptyRepository implements PickupCredentialRepositoryApi {
  _EmptyRepository([this.items = const []]);

  final List<PickupCredential> items;

  @override
  Future<List<PickupCredential>> getAll() async => items;

  @override
  Future<List<PickupCredential>> getPending() async => [];

  @override
  Future<List<PickupCredential>> getPickedUp() async => [];

  @override
  Future<List<PickupCredential>> findByTrackingNumber(
    String trackingNumber,
  ) async => [];

  @override
  Future<List<PickupCredential>> insertAll(
    List<PickupCredentialDraft> drafts,
  ) async => [];

  @override
  Future<PickupCredential> update(PickupCredential credential) =>
      throw UnimplementedError();

  @override
  Future<PickupCredential> markPickedUp(int id) => throw UnimplementedError();

  @override
  Future<PickupCredential> markPending(int id) => throw UnimplementedError();

  @override
  Future<void> deleteById(int id) => throw UnimplementedError();

  @override
  Future<List<PickupCredential>> markPickedUpAll(Iterable<int> ids) =>
      throw UnimplementedError();

  @override
  Future<List<PickupCredential>> markPendingAll(Iterable<int> ids) =>
      throw UnimplementedError();

  @override
  Future<void> deleteAll(Iterable<int> ids) => throw UnimplementedError();
}

void main() {
  Future<void> pumpMap(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(home: StationMapPage(repository: _EmptyRepository())),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'viewport fills available height without stretching map content',
    (tester) async {
      await pumpMap(tester);

      final viewportSize = tester.getSize(
        find.byKey(const Key('station-map-viewport')),
      );
      final contentSize = tester.getSize(
        find.byKey(const Key('station-map-content')),
      );

      expect(viewportSize.height, greaterThan(contentSize.height + 200));
      expect(
        contentSize.width / contentSize.height,
        closeTo(1448 / 1086, .001),
      );
    },
  );

  testWidgets('map and markers share the InteractiveViewer transform child', (
    tester,
  ) async {
    await pumpMap(tester);

    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    final content = find.byKey(const Key('station-map-content'));

    expect(viewer.constrained, isFalse);
    expect(
      find.descendant(of: find.byType(InteractiveViewer), matching: content),
      findsOneWidget,
    );
    expect(
      find.descendant(of: content, matching: find.byType(Image)),
      findsOneWidget,
    );
  });

  testWidgets('count marker is inside the transformed map content', (
    tester,
  ) async {
    final now = DateTime(2026);
    await tester.pumpWidget(
      MaterialApp(
        home: StationMapPage(
          repository: _EmptyRepository([
            PickupCredential(
              id: 1,
              courierCompany: CourierCompany.zto,
              pickupCode: 'C-1',
              status: PickupStatus.pending,
              sourcePlatform: PackagePlatform.unknown,
              createdAt: now,
              updatedAt: now,
            ),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const Key('station-map-content')),
        matching: find.byKey(const Key('mapBadge_c')),
      ),
      findsOneWidget,
    );
  });
}
