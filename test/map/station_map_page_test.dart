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
    expect(viewer.boundaryMargin.vertical, greaterThan(0));
    expect(
      viewer.transformationController!.value.getMaxScaleOnAxis(),
      closeTo(1, .001),
    );
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

  testWidgets('pinch zoom can return to the fit-width scale', (tester) async {
    await pumpMap(tester);

    final viewerFinder = find.byType(InteractiveViewer);
    final viewer = tester.widget<InteractiveViewer>(viewerFinder);
    final firstFinger = await tester.startGesture(
      const Offset(150, 400),
      pointer: 1,
    );
    final secondFinger = await tester.startGesture(
      const Offset(240, 400),
      pointer: 2,
    );
    await tester.pump();
    await firstFinger.moveTo(const Offset(110, 400));
    await secondFinger.moveTo(const Offset(280, 400));
    await tester.pump();
    await firstFinger.up();
    await secondFinger.up();
    await tester.pumpAndSettle();

    expect(
      viewer.transformationController!.value.getMaxScaleOnAxis(),
      greaterThan(1),
    );

    final thirdFinger = await tester.startGesture(
      const Offset(110, 400),
      pointer: 3,
    );
    final fourthFinger = await tester.startGesture(
      const Offset(280, 400),
      pointer: 4,
    );
    await tester.pump();
    await thirdFinger.moveTo(const Offset(150, 400));
    await fourthFinger.moveTo(const Offset(240, 400));
    await tester.pump();
    await thirdFinger.up();
    await fourthFinger.up();
    await tester.pumpAndSettle();

    expect(
      viewer.transformationController!.value.getMaxScaleOnAxis(),
      closeTo(1, .001),
    );
  });

  testWidgets('minimum scale settles at center before the pinch ends', (
    tester,
  ) async {
    await pumpMap(tester);

    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    final controller = viewer.transformationController!;
    final centeredMatrix = controller.value.clone();
    final viewportSize = tester.getSize(
      find.byKey(const Key('station-map-viewport')),
    );
    final contentSize = tester.getSize(
      find.byKey(const Key('station-map-content')),
    );
    final expectedCenteredTranslation = Offset(
      (viewportSize.width - contentSize.width) / 2,
      (viewportSize.height - contentSize.height) / 2,
    );
    expect(
      centeredMatrix.entry(0, 3),
      closeTo(expectedCenteredTranslation.dx, .01),
    );
    expect(
      centeredMatrix.entry(1, 3),
      closeTo(expectedCenteredTranslation.dy, .01),
    );

    final zoomFirstFinger = await tester.startGesture(
      const Offset(150, 400),
      pointer: 11,
    );
    final zoomSecondFinger = await tester.startGesture(
      const Offset(240, 400),
      pointer: 12,
    );
    await tester.pump();
    await zoomFirstFinger.moveTo(const Offset(110, 400));
    await zoomSecondFinger.moveTo(const Offset(280, 400));
    await tester.pump();
    await zoomFirstFinger.up();
    await zoomSecondFinger.up();
    await tester.pumpAndSettle();

    expect(controller.value.getMaxScaleOnAxis(), greaterThan(1));

    // Zoom back out around an off-center focal point. The map must already be
    // centered when it reaches its minimum scale, rather than snapping there
    // after the fingers are released.
    final shrinkFirstFinger = await tester.startGesture(
      const Offset(210, 420),
      pointer: 13,
    );
    final shrinkSecondFinger = await tester.startGesture(
      const Offset(350, 420),
      pointer: 14,
    );
    await tester.pump();
    await shrinkFirstFinger.moveTo(const Offset(270, 420));
    await shrinkSecondFinger.moveTo(const Offset(290, 420));
    await tester.pump();

    final minimumMatrixBeforeRelease = controller.value.clone();
    expect(minimumMatrixBeforeRelease.getMaxScaleOnAxis(), closeTo(1, .001));
    expect(
      minimumMatrixBeforeRelease.entry(0, 3),
      closeTo(centeredMatrix.entry(0, 3), .01),
    );
    expect(
      minimumMatrixBeforeRelease.entry(1, 3),
      closeTo(centeredMatrix.entry(1, 3), .01),
    );

    await shrinkFirstFinger.up();
    await shrinkSecondFinger.up();
    await tester.pumpAndSettle();

    expect(
      controller.value.entry(0, 3),
      closeTo(minimumMatrixBeforeRelease.entry(0, 3), .01),
    );
    expect(
      controller.value.entry(1, 3),
      closeTo(minimumMatrixBeforeRelease.entry(1, 3), .01),
    );
  });

  testWidgets('pinch keeps the initial two-finger center as the zoom anchor', (
    tester,
  ) async {
    await pumpMap(tester);

    final viewerFinder = find.byType(InteractiveViewer);
    final viewer = tester.widget<InteractiveViewer>(viewerFinder);
    final controller = viewer.transformationController!;
    final viewerTopLeft = tester.getTopLeft(viewerFinder);
    final contentFinder = find.byKey(const Key('station-map-content'));
    const globalFocalPoint = Offset(195, 400);
    final initialFocalPoint = globalFocalPoint - viewerTopLeft;
    final initialSceneOffset =
        globalFocalPoint - tester.getTopLeft(contentFinder);
    final firstFinger = await tester.startGesture(
      globalFocalPoint - const Offset(45, 0),
      pointer: 5,
    );
    final secondFinger = await tester.startGesture(
      globalFocalPoint + const Offset(45, 0),
      pointer: 6,
    );
    await tester.pump();
    final initialScenePoint = controller.toScene(initialFocalPoint);
    await firstFinger.moveTo(globalFocalPoint + const Offset(-95, -20));
    await secondFinger.moveTo(globalFocalPoint + const Offset(55, 20));
    await tester.pump();
    await firstFinger.up();
    await secondFinger.up();
    await tester.pumpAndSettle();

    final scale = controller.value.getMaxScaleOnAxis();
    final renderedScenePoint =
        tester.getTopLeft(contentFinder) + initialSceneOffset * scale;

    expect(
      controller.toScene(initialFocalPoint),
      isA<Offset>().having(
        (point) => point.dx,
        'dx',
        closeTo(initialScenePoint.dx, .01),
      ),
    );
    expect(
      controller.toScene(initialFocalPoint).dy,
      closeTo(initialScenePoint.dy, .01),
    );
    expect(renderedScenePoint.dx, closeTo(globalFocalPoint.dx, .01));
    expect(renderedScenePoint.dy, closeTo(globalFocalPoint.dy, .01));
  });
}
