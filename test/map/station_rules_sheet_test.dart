import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:packagehub/core/repository/pickup_credential_repository.dart';
import 'package:packagehub/map/station_map_page.dart';
import 'package:packagehub/models/pickup_credential.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';

class _EmptyRepository implements PickupCredentialRepositoryApi {
  @override
  Future<List<PickupCredential>> getAll() async => [];

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
  testWidgets('map exposes station rules and refresh actions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: StationMapPage(repository: _EmptyRepository())),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('站点规则'), findsOneWidget);
    expect(find.byTooltip('重新加载'), findsOneWidget);

    await tester.tap(find.byTooltip('站点规则'));
    await tester.pumpAndSettle();
    expect(find.text('站点规则'), findsOneWidget);
    expect(find.text('前缀推断'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('中通'), findsWidgets);
    expect(find.text('C 区'), findsOneWidget);
    expect(find.text('T / Z'), findsOneWidget);
    expect(find.text('T/Z 区'), findsOneWidget);

    final sheetScrollView = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(
      find.text('快递区域'),
      300,
      scrollable: sheetScrollView,
    );
    expect(find.text('快递区域'), findsOneWidget);
    expect(find.text('S'), findsOneWidget);
    expect(find.text('极兔'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('不推断快递'),
      300,
      scrollable: sheetScrollView,
    );
    expect(find.text('A'), findsOneWidget);
    expect(find.text('不推断快递'), findsOneWidget);
    expect(find.text('大件区'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('匹配优先级'),
      300,
      scrollable: sheetScrollView,
    );
    expect(find.text('匹配优先级'), findsOneWidget);
    expect(find.text('京东'), findsWidgets);
    expect(find.text('京东区'), findsOneWidget);
    expect(find.text('顺丰'), findsWidgets);
    expect(find.text('顺丰区'), findsOneWidget);

    await tester.tap(find.byKey(const Key('station-rules-done')));
    await tester.pumpAndSettle();
    expect(find.text('匹配优先级'), findsNothing);
  });
}
