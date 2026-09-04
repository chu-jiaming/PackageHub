import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:packagehub/core/duplicate/tracking_number_normalizer.dart';
import 'package:packagehub/core/repository/pickup_credential_repository.dart';
import 'package:packagehub/design_system/tokens/ph_sizes.dart';
import 'package:packagehub/main.dart';
import 'package:packagehub/models/pickup_credential.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';

void main() {
  group('HomePage', () {
    testWidgets('shows empty state when repository is empty', (tester) async {
      await _pumpHome(tester, repository: _FakePickupCredentialRepository());

      expect(find.text('暂无取件凭证'), findsOneWidget);
      expect(find.text('添加快递截图后，'), findsOneWidget);
      expect(find.text('PackageHub 会自动识别取件信息。'), findsOneWidget);
      expect(find.text('添加截图'), findsOneWidget);
    });

    testWidgets('keeps normal header actions horizontal at 320 points', (
      tester,
    ) async {
      _setViewport(tester, const Size(320, 800));
      await _pumpHome(
        tester,
        repository: _FakePickupCredentialRepository(
          initialCredentials: [_credential(id: 1)],
        ),
      );

      expect(find.text('批量管理'), findsOneWidget);
      expect(find.text('PackageHub'), findsOneWidget);
      expect(find.byKey(const Key('accountAvatarButton')), findsOneWidget);
      expect(
        find.byKey(const Key('pickupReminderSettingsButton')),
        findsOneWidget,
      );
      _expectSingleLineAction(
        tester,
        button: find.byKey(const Key('enterSelectionModeButton')),
        label: '批量管理',
      );
    });

    testWidgets('keeps selection header actions horizontal at 320 points', (
      tester,
    ) async {
      _setViewport(tester, const Size(320, 800));
      await _pumpHome(
        tester,
        repository: _FakePickupCredentialRepository(
          initialCredentials: [_credential(id: 1), _credential(id: 2)],
        ),
      );
      await _enterSelectionMode(tester);

      expect(find.text('PackageHub'), findsOneWidget);
      _expectSingleLineAction(
        tester,
        button: find.byKey(const Key('selectAllCredentialsButton')),
        label: '全选',
      );
      _expectSingleLineAction(
        tester,
        button: find.byKey(const Key('cancelSelectionModeButton')),
        label: '取消',
      );

      await tester.tap(find.byKey(const Key('selectAllCredentialsButton')));
      await tester.pumpAndSettle();
      _expectSingleLineAction(
        tester,
        button: find.byKey(const Key('selectAllCredentialsButton')),
        label: '取消全选',
      );
    });

    testWidgets('displays 3 real credentials from repository', (tester) async {
      final repository = _FakePickupCredentialRepository(
        initialCredentials: [
          _credential(courierCompany: CourierCompany.jtexpress),
          _credential(courierCompany: CourierCompany.sfExpress),
          _credential(courierCompany: CourierCompany.zto),
        ],
      );

      await _pumpHome(tester, repository: repository);

      expect(find.text('极兔速递 · 1'), findsOneWidget);
      expect(find.text('顺丰速运 · 1'), findsOneWidget);
      expect(find.text('中通快递 · 1'), findsOneWidget);
    });

    testWidgets('displays courier, pickup code, tracking number, and status', (
      tester,
    ) async {
      final repository = _FakePickupCredentialRepository(
        initialCredentials: [
          _credential(
            courierCompany: CourierCompany.jtexpress,
            pickupCode: 'Z5-2-1350',
            trackingNumber: 'JT5519167631350',
            status: PickupStatus.pending,
          ),
        ],
      );

      await _pumpHome(tester, repository: repository);

      expect(find.text('极兔速递 · 1'), findsOneWidget);
      expect(find.text('Z5-2-1350'), findsOneWidget);
      expect(find.text('JT5519167631350'), findsOneWidget);
      expect(find.text('待取件'), findsNothing);
    });

    testWidgets('does not show sourcePlatform as primary home text', (
      tester,
    ) async {
      final repository = _FakePickupCredentialRepository(
        initialCredentials: [
          _credential(sourcePlatform: PackagePlatform.pinduoduo),
        ],
      );

      await _pumpHome(tester, repository: repository);

      expect(find.text('拼多多'), findsNothing);
      expect(find.text('淘宝'), findsNothing);
      expect(find.text('京东'), findsNothing);
    });

    testWidgets('does not show stationName on home after persistence', (
      tester,
    ) async {
      final repository = _FakePickupCredentialRepository();

      await _pumpHome(
        tester,
        repository: repository,
        imagePathPicker: () async => ['one.png'],
        importPageBuilder: (_) =>
            _ReturningImportPage(result: [_draft(stationName: '菜鸟驿站')]),
      );
      await _runImport(tester);

      expect(find.text('菜鸟驿站'), findsNothing);
      expect(find.text('取件点'), findsNothing);
      expect(find.text('极兔速递 · 1'), findsOneWidget);
    });

    testWidgets('user cancel import does not call insertAll', (tester) async {
      final repository = _FakePickupCredentialRepository();

      await _pumpHome(
        tester,
        repository: repository,
        imagePathPicker: () async => ['one.png'],
        importPageBuilder: (_) => const _ReturningImportPage(result: null),
      );
      await _runImport(tester);

      expect(repository.insertAllCallCount, 0);
      expect(find.text('暂无取件凭证'), findsOneWidget);
    });

    testWidgets('empty confirmedDrafts does not call insertAll', (
      tester,
    ) async {
      final repository = _FakePickupCredentialRepository();

      await _pumpHome(
        tester,
        repository: repository,
        imagePathPicker: () async => ['one.png'],
        importPageBuilder: (_) => const _ReturningImportPage(result: []),
      );
      await _runImport(tester);

      expect(repository.insertAllCallCount, 0);
      expect(find.text('暂无取件凭证'), findsOneWidget);
    });

    testWidgets('confirming 3 drafts calls insertAll once with all drafts', (
      tester,
    ) async {
      final repository = _FakePickupCredentialRepository();
      final drafts = [
        _draft(trackingNumber: 'JT100000001', pickupCode: '1-1-1'),
        _draft(trackingNumber: 'JT100000002', pickupCode: '2-2-2'),
        _draft(trackingNumber: 'JT100000003', pickupCode: '3-3-3'),
      ];

      await _pumpHome(
        tester,
        repository: repository,
        imagePathPicker: () async => ['one.png', 'two.png', 'three.png'],
        importPageBuilder: (_) => _ReturningImportPage(result: drafts),
      );
      await _runImport(tester);

      expect(repository.insertAllCallCount, 1);
      expect(repository.lastInsertedDrafts, drafts);
      expect(repository.lastInsertedDrafts, hasLength(3));
    });

    testWidgets('save success reloads home and shows new credentials', (
      tester,
    ) async {
      final repository = _FakePickupCredentialRepository();

      await _pumpHome(
        tester,
        repository: repository,
        imagePathPicker: () async => ['one.png'],
        importPageBuilder: (_) => _ReturningImportPage(
          result: [
            _draft(
              courierCompany: CourierCompany.sfExpress,
              pickupCode: '3-28088',
            ),
          ],
        ),
      );
      await _runImport(tester);

      expect(repository.getAllCallCount, 2);
      expect(find.text('顺丰速运 · 1'), findsOneWidget);
      expect(find.text('3-28088'), findsOneWidget);
      expect(find.text('已添加 1 个取件凭证'), findsOneWidget);
    });

    testWidgets('rapid repeat while saving still calls insertAll once', (
      tester,
    ) async {
      final insertCompleter = Completer<void>();
      final repository = _FakePickupCredentialRepository(
        beforeInsertCompletes: insertCompleter.future,
      );

      await _pumpHome(
        tester,
        repository: repository,
        imagePathPicker: () async => ['one.png'],
        importPageBuilder: (_) => _ReturningImportPage(result: [_draft()]),
      );

      await tester.tap(find.text('添加截图'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('returnImportResultButton')));
      await tester.pump();
      await tester.tap(find.text('添加截图'));
      await tester.pump();

      expect(repository.insertAllCallCount, 1);

      insertCompleter.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('save failure shows retry error', (tester) async {
      final repository = _FakePickupCredentialRepository(failInsertCount: 1);

      await _pumpHome(
        tester,
        repository: repository,
        imagePathPicker: () async => ['one.png'],
        importPageBuilder: (_) => _ReturningImportPage(result: [_draft()]),
      );
      await _runImport(tester);

      expect(find.text('无法保存取件信息'), findsWidgets);
      expect(find.byKey(const Key('retrySaveButton')), findsOneWidget);
      expect(find.text('重试'), findsWidgets);
    });

    testWidgets('retry after save failure reuses confirmed drafts', (
      tester,
    ) async {
      final repository = _FakePickupCredentialRepository(failInsertCount: 1);
      var pickerCallCount = 0;
      var importPageBuildCount = 0;
      final drafts = [_draft(pickupCode: 'R-1-2048')];

      await _pumpHome(
        tester,
        repository: repository,
        imagePathPicker: () async {
          pickerCallCount += 1;
          return ['one.png'];
        },
        importPageBuilder: (_) {
          importPageBuildCount += 1;
          return _ReturningImportPage(result: drafts);
        },
      );
      await _runImport(tester);

      await tester.tap(find.byKey(const Key('retrySaveButton')));
      await tester.pumpAndSettle();

      expect(repository.insertAllCallCount, 2);
      expect(repository.lastInsertedDrafts, drafts);
      expect(pickerCallCount, 1);
      expect(importPageBuildCount, 1);
      expect(find.text('R-1-2048'), findsOneWidget);
      expect(find.text('无法保存取件信息'), findsNothing);
    });

    testWidgets('no duplicate inserts directly without duplicate page', (
      tester,
    ) async {
      final repository = _FakePickupCredentialRepository();
      final drafts = [_draft(trackingNumber: 'JT-NO-DUP')];

      await _pumpHome(
        tester,
        repository: repository,
        imagePathPicker: () async => ['one.png'],
        importPageBuilder: (_) => _ReturningImportPage(result: drafts),
      );
      await _runImport(tester);

      expect(find.text('发现重复取件凭证'), findsNothing);
      expect(repository.insertAllCallCount, 1);
      expect(repository.lastInsertedDrafts, drafts);
    });

    testWidgets('existing duplicate opens duplicate review', (tester) async {
      final repository = _FakePickupCredentialRepository(
        initialCredentials: [_credential(trackingNumber: 'JT-DUP')],
      );

      await _pumpHome(
        tester,
        repository: repository,
        imagePathPicker: () async => ['one.png'],
        importPageBuilder: (_) =>
            _ReturningImportPage(result: [_draft(trackingNumber: 'JT-DUP')]),
      );
      await _runImport(tester);

      expect(find.text('发现重复取件凭证'), findsOneWidget);
      expect(find.text('已存在于 PackageHub'), findsOneWidget);
      expect(repository.insertAllCallCount, 0);
    });

    testWidgets('default skip inserts nothing when every draft is duplicate', (
      tester,
    ) async {
      final repository = _FakePickupCredentialRepository(
        initialCredentials: [_credential(trackingNumber: 'JT-DUP')],
      );

      await _pumpHome(
        tester,
        repository: repository,
        imagePathPicker: () async => ['one.png'],
        importPageBuilder: (_) =>
            _ReturningImportPage(result: [_draft(trackingNumber: 'JT-DUP')]),
      );
      await _runImport(tester);
      await tester.tap(find.byKey(const Key('continueDuplicateReviewButton')));
      await tester.pumpAndSettle();

      expect(repository.insertAllCallCount, 0);
      expect(find.text('已跳过重复凭证'), findsOneWidget);
    });

    testWidgets('choosing keep inserts duplicate draft', (tester) async {
      final repository = _FakePickupCredentialRepository(
        initialCredentials: [_credential(trackingNumber: 'JT-DUP')],
      );
      final duplicate = _draft(trackingNumber: 'JT-DUP');

      await _pumpHome(
        tester,
        repository: repository,
        imagePathPicker: () async => ['one.png'],
        importPageBuilder: (_) => _ReturningImportPage(result: [duplicate]),
      );
      await _runImport(tester);
      await tester.tap(_duplicateDecisionText(0, '仍然保留'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('continueDuplicateReviewButton')));
      await tester.pumpAndSettle();

      expect(repository.insertAllCallCount, 1);
      expect(repository.lastInsertedDrafts, [duplicate]);
    });

    testWidgets('within-batch duplicate opens duplicate review', (
      tester,
    ) async {
      final repository = _FakePickupCredentialRepository();

      await _pumpHome(
        tester,
        repository: repository,
        imagePathPicker: () async => ['one.png', 'two.png'],
        importPageBuilder: (_) => _ReturningImportPage(
          result: [
            _draft(trackingNumber: 'JT-BATCH', pickupCode: 'A'),
            _draft(trackingNumber: ' jt-batch ', pickupCode: 'B'),
          ],
        ),
      );
      await _runImport(tester);

      expect(find.text('发现重复取件凭证'), findsOneWidget);
      expect(find.text('本次导入中重复'), findsOneWidget);
      expect(repository.insertAllCallCount, 0);
    });

    testWidgets('multiple duplicate conflicts can be kept separately', (
      tester,
    ) async {
      final repository = _FakePickupCredentialRepository(
        initialCredentials: [_credential(trackingNumber: 'JT-EXISTING')],
      );
      final unique = _draft(trackingNumber: 'JT-UNIQUE', pickupCode: 'UNIQUE');
      final existingDuplicate = _draft(
        trackingNumber: 'JT-EXISTING',
        pickupCode: 'EXISTING',
      );
      final batchDuplicate = _draft(
        trackingNumber: 'jt-unique',
        pickupCode: 'BATCH',
      );

      await _pumpHome(
        tester,
        repository: repository,
        imagePathPicker: () async => ['one.png', 'two.png', 'three.png'],
        importPageBuilder: (_) => _ReturningImportPage(
          result: [unique, existingDuplicate, batchDuplicate],
        ),
      );
      await _runImport(tester);
      await tester.tap(_duplicateDecisionText(2, '仍然保留'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('continueDuplicateReviewButton')));
      await tester.pumpAndSettle();

      expect(repository.insertAllCallCount, 1);
      expect(repository.lastInsertedDrafts, [unique, batchDuplicate]);
    });

    testWidgets('user backs out of duplicate review without saving', (
      tester,
    ) async {
      final repository = _FakePickupCredentialRepository(
        initialCredentials: [_credential(trackingNumber: 'JT-DUP')],
      );

      await _pumpHome(
        tester,
        repository: repository,
        imagePathPicker: () async => ['one.png'],
        importPageBuilder: (_) =>
            _ReturningImportPage(result: [_draft(trackingNumber: 'JT-DUP')]),
      );
      await _runImport(tester);
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(repository.insertAllCallCount, 0);
      expect(find.text('暂无取件凭证'), findsNothing);
      expect(find.text('发现重复取件凭证'), findsNothing);
    });

    testWidgets(
      'retry after duplicate review save failure reuses draftsToInsert',
      (tester) async {
        final repository = _FakePickupCredentialRepository(
          failInsertCount: 1,
          initialCredentials: [_credential(trackingNumber: 'JT-DUP')],
        );
        var pickerCallCount = 0;
        var importPageBuildCount = 0;
        final unique = _draft(trackingNumber: 'JT-UNIQUE');
        final duplicate = _draft(trackingNumber: 'JT-DUP');

        await _pumpHome(
          tester,
          repository: repository,
          imagePathPicker: () async {
            pickerCallCount += 1;
            return ['one.png', 'two.png'];
          },
          importPageBuilder: (_) {
            importPageBuildCount += 1;
            return _ReturningImportPage(result: [unique, duplicate]);
          },
        );
        await _runImport(tester);
        await tester.tap(_duplicateDecisionText(1, '仍然保留'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('continueDuplicateReviewButton')),
        );
        await tester.pumpAndSettle();

        final duplicateQueryCountAfterReview =
            repository.findByTrackingNumberCallCount;
        expect(repository.insertAllCallCount, 1);
        expect(find.text('无法保存取件信息'), findsWidgets);

        await tester.tap(find.byKey(const Key('retrySaveButton')));
        await tester.pumpAndSettle();

        expect(repository.insertAllCallCount, 2);
        expect(repository.lastInsertedDrafts, [unique, duplicate]);
        expect(
          repository.findByTrackingNumberCallCount,
          duplicateQueryCountAfterReview,
        );
        expect(pickerCallCount, 1);
        expect(importPageBuildCount, 1);
        expect(find.text('发现重复取件凭证'), findsNothing);
      },
    );

    testWidgets('repository load failure shows error state', (tester) async {
      final repository = _FakePickupCredentialRepository(failGetAllCount: 1);

      await _pumpHome(tester, repository: repository);

      expect(find.text('无法加载取件凭证'), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);
    });

    testWidgets('load retry queries repository again', (tester) async {
      final repository = _FakePickupCredentialRepository(
        failGetAllCount: 1,
        initialCredentials: [
          _credential(
            courierCompany: CourierCompany.yto,
            pickupCode: '6-2-8-1',
          ),
        ],
      );

      await _pumpHome(tester, repository: repository);
      await tester.tap(find.text('重试'));
      await tester.pumpAndSettle();

      expect(repository.getAllCallCount, 2);
      expect(find.text('圆通速递 · 1'), findsOneWidget);
      expect(find.text('6-2-8-1'), findsOneWidget);
    });

    testWidgets('unknown courier displays Chinese fallback', (tester) async {
      final repository = _FakePickupCredentialRepository(
        initialCredentials: [
          _credential(courierCompany: CourierCompany.unknown),
        ],
      );

      await _pumpHome(tester, repository: repository);

      expect(find.text('未识别快递公司 · 1'), findsOneWidget);
      expect(find.text('CourierCompany.unknown'), findsNothing);
    });

    testWidgets('unknown status displays Chinese fallback', (tester) async {
      final repository = _FakePickupCredentialRepository(
        initialCredentials: [_credential(status: PickupStatus.unknown)],
      );

      await _pumpHome(tester, repository: repository);

      expect(find.text('未判断'), findsWidgets);
      expect(find.text('PickupStatus.unknown'), findsNothing);
    });

    testWidgets('pending credential appears in pending section', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        repository: _FakePickupCredentialRepository(
          initialCredentials: [
            _credential(id: 1, pickupCode: 'P-1', status: PickupStatus.pending),
          ],
        ),
      );

      expect(
        find.descendant(
          of: find.byKey(const Key('credentialSection-待取件')),
          matching: find.text('P-1'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('pickedUp credential appears in pickedUp section', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        repository: _FakePickupCredentialRepository(
          initialCredentials: [
            _credential(
              id: 1,
              pickupCode: 'DONE-1',
              status: PickupStatus.pickedUp,
            ),
          ],
        ),
      );

      expect(
        find.descendant(
          of: find.byKey(const Key('credentialSection-已取件')),
          matching: find.text('DONE-1'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('unknown credential appears in unknown section', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        repository: _FakePickupCredentialRepository(
          initialCredentials: [
            _credential(id: 1, pickupCode: 'U-1', status: PickupStatus.unknown),
          ],
        ),
      );

      expect(
        find.descendant(
          of: find.byKey(const Key('credentialSection-未判断')),
          matching: find.text('U-1'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('pending lifecycle button calls markPickedUp once', (
      tester,
    ) async {
      final repository = _FakePickupCredentialRepository(
        initialCredentials: [_credential(id: 7, status: PickupStatus.pending)],
      );
      await _pumpHome(tester, repository: repository);

      await tester.tap(find.byKey(const Key('credentialLifecycleButton-7')));
      await tester.pumpAndSettle();

      expect(repository.markPickedUpCallCount, 1);
      expect(repository.markPickedUpIds, [7]);
    });

    testWidgets('pending card uses compact check action without text label', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        repository: _FakePickupCredentialRepository(
          initialCredentials: [
            _credential(id: 7, status: PickupStatus.pending),
          ],
        ),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(
        find.byKey(const Key('credentialLifecycleButton-7')),
        findsOneWidget,
      );
      expect(find.text('已取件'), findsNothing);
    });

    testWidgets('markPickedUp success reloads and moves item to pickedUp', (
      tester,
    ) async {
      final repository = _FakePickupCredentialRepository(
        initialCredentials: [
          _credential(
            id: 1,
            pickupCode: 'MOVE-1',
            status: PickupStatus.pending,
          ),
        ],
      );
      await _pumpHome(tester, repository: repository);

      await _tapVisible(tester, const Key('credentialLifecycleButton-1'));
      await tester.pumpAndSettle();

      expect(repository.getAllCallCount, 2);
      expect(
        find.descendant(
          of: find.byKey(const Key('credentialSection-已取件')),
          matching: find.text('MOVE-1'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('credentialSection-待取件')), findsNothing);
      expect(find.text('已标记为已取件'), findsOneWidget);
    });

    testWidgets('pickedUp lifecycle button calls markPending once', (
      tester,
    ) async {
      final repository = _FakePickupCredentialRepository(
        initialCredentials: [_credential(id: 8, status: PickupStatus.pickedUp)],
      );
      await _pumpHome(tester, repository: repository);

      await tester.tap(find.byKey(const Key('credentialLifecycleButton-8')));
      await tester.pumpAndSettle();

      expect(repository.markPendingCallCount, 1);
      expect(repository.markPendingIds, [8]);
    });

    testWidgets('markPending success reloads and moves item to pending', (
      tester,
    ) async {
      final repository = _FakePickupCredentialRepository(
        initialCredentials: [
          _credential(
            id: 1,
            pickupCode: 'BACK-1',
            status: PickupStatus.pickedUp,
          ),
        ],
      );
      await _pumpHome(tester, repository: repository);

      await _tapVisible(tester, const Key('credentialLifecycleButton-1'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('credentialSection-待取件')),
          matching: find.text('BACK-1'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('credentialSection-已取件')), findsNothing);
    });

    testWidgets('status update failure shows error and keeps original state', (
      tester,
    ) async {
      final repository = _FakePickupCredentialRepository(
        failMarkPickedUpCount: 1,
        initialCredentials: [
          _credential(
            id: 1,
            pickupCode: 'FAIL-1',
            status: PickupStatus.pending,
          ),
        ],
      );
      await _pumpHome(tester, repository: repository);

      await _tapVisible(tester, const Key('credentialLifecycleButton-1'));
      await tester.pumpAndSettle();

      expect(find.text('无法更新取件状态'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('credentialSection-待取件')),
          matching: find.text('FAIL-1'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('credentialSection-已取件')), findsNothing);
    });

    testWidgets('markPending failure shows error and keeps pickedUp state', (
      tester,
    ) async {
      final repository = _FakePickupCredentialRepository(
        initialCredentials: [
          _credential(
            id: 1,
            pickupCode: 'RESTORE-FAIL',
            status: PickupStatus.pickedUp,
          ),
        ],
      )..failMarkPendingCount = 1;
      await _pumpHome(tester, repository: repository);

      await _tapVisible(tester, const Key('credentialLifecycleButton-1'));
      await tester.pumpAndSettle();

      expect(find.text('无法更新取件状态'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('credentialSection-已取件')),
          matching: find.text('RESTORE-FAIL'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('credentialSection-待取件')), findsNothing);
    });

    testWidgets('tapping credential opens detail page', (tester) async {
      await _pumpHome(
        tester,
        repository: _FakePickupCredentialRepository(
          initialCredentials: [_credential(id: 1)],
        ),
      );

      await _openDetail(tester, 1);

      expect(find.text('取件凭证详情'), findsOneWidget);
    });

    testWidgets('detail page displays persisted credential fields', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        repository: _FakePickupCredentialRepository(
          initialCredentials: [
            _credential(
              id: 1,
              courierCompany: CourierCompany.sfExpress,
              pickupCode: 'D-1',
              trackingNumber: 'SF1234567890',
              status: PickupStatus.pending,
            ),
          ],
        ),
      );

      await _openDetail(tester, 1);

      expect(find.text('顺丰速运'), findsOneWidget);
      expect(find.text('D-1'), findsOneWidget);
      expect(find.text('SF1234567890'), findsOneWidget);
      expect(find.text('待取件'), findsOneWidget);
      expect(find.text('raw OCR text'), findsNothing);
      expect(find.text('兔喜快递超市'), findsNothing);
    });

    testWidgets('detail edit action opens edit page', (tester) async {
      await _pumpHome(
        tester,
        repository: _FakePickupCredentialRepository(
          initialCredentials: [_credential(id: 1)],
        ),
      );
      await _openDetail(tester, 1);

      await _openEdit(tester);

      expect(find.text('编辑取件凭证'), findsOneWidget);
    });

    testWidgets('saving edited pickupCode calls repository.update', (
      tester,
    ) async {
      final repository = _FakePickupCredentialRepository(
        initialCredentials: [_credential(id: 1)],
      );
      await _pumpHome(tester, repository: repository);
      await _openDetail(tester, 1);
      await _openEdit(tester);

      await tester.enterText(
        find.byKey(const Key('editPickupCodeField')),
        ' Z5 - 2 - 1358 ',
      );
      await tester.tap(find.byKey(const Key('saveCredentialEditButton')));
      await tester.pumpAndSettle();

      expect(repository.updateCallCount, 1);
      expect(repository.lastUpdatedCredential!.pickupCode, 'Z5-2-1358');
      expect(find.text('Z5-2-1358'), findsOneWidget);
    });

    testWidgets('saving edited courier calls update with new courier', (
      tester,
    ) async {
      final repository = _FakePickupCredentialRepository(
        initialCredentials: [
          _credential(id: 1, courierCompany: CourierCompany.jtexpress),
        ],
      );
      await _pumpHome(tester, repository: repository);
      await _openDetail(tester, 1);
      await _openEdit(tester);

      await _selectDropdownOption(
        tester,
        fieldKey: const Key('editCourierCompanyField'),
        optionText: '顺丰速运',
      );
      await tester.tap(find.byKey(const Key('saveCredentialEditButton')));
      await tester.pumpAndSettle();

      expect(
        repository.lastUpdatedCredential!.courierCompany,
        CourierCompany.sfExpress,
      );
      expect(find.text('顺丰速运'), findsOneWidget);
    });

    testWidgets('saving edited trackingNumber calls update with new value', (
      tester,
    ) async {
      final repository = _FakePickupCredentialRepository(
        initialCredentials: [_credential(id: 1)],
      );
      await _pumpHome(tester, repository: repository);
      await _openDetail(tester, 1);
      await _openEdit(tester);

      await tester.enterText(
        find.byKey(const Key('editTrackingNumberField')),
        ' SF1234567890 ',
      );
      await tester.tap(find.byKey(const Key('saveCredentialEditButton')));
      await tester.pumpAndSettle();

      expect(repository.lastUpdatedCredential!.trackingNumber, 'SF1234567890');
      expect(find.text('SF1234567890'), findsOneWidget);
    });

    testWidgets('saving edited status calls update with new status', (
      tester,
    ) async {
      final repository = _FakePickupCredentialRepository(
        initialCredentials: [_credential(id: 1, status: PickupStatus.unknown)],
      );
      await _pumpHome(tester, repository: repository);
      await _openDetail(tester, 1);
      await _openEdit(tester);

      await _selectDropdownOption(
        tester,
        fieldKey: const Key('editStatusField'),
        optionText: '已取件',
      );
      await tester.tap(find.byKey(const Key('saveCredentialEditButton')));
      await tester.pumpAndSettle();

      expect(repository.lastUpdatedCredential!.status, PickupStatus.pickedUp);
      expect(find.text('已取件'), findsOneWidget);
    });

    testWidgets('canceling edit does not call repository.update', (
      tester,
    ) async {
      final repository = _FakePickupCredentialRepository(
        initialCredentials: [_credential(id: 1)],
      );
      await _pumpHome(tester, repository: repository);
      await _openDetail(tester, 1);
      await _openEdit(tester);

      await tester.enterText(
        find.byKey(const Key('editPickupCodeField')),
        'UNSAVED',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(repository.updateCallCount, 0);
      expect(find.text('取件凭证详情'), findsOneWidget);
      expect(find.text('UNSAVED'), findsNothing);
    });

    testWidgets('saving edit preserves createdAt in update payload', (
      tester,
    ) async {
      final createdAt = DateTime(2024, 1, 2);
      final repository = _FakePickupCredentialRepository(
        initialCredentials: [
          _credential(id: 1, pickupCode: 'OLD', createdAt: createdAt),
        ],
      );
      await _pumpHome(tester, repository: repository);
      await _openDetail(tester, 1);
      await _openEdit(tester);

      await tester.enterText(
        find.byKey(const Key('editPickupCodeField')),
        'NEW',
      );
      await tester.tap(find.byKey(const Key('saveCredentialEditButton')));
      await tester.pumpAndSettle();

      expect(repository.lastUpdatedCredential!.createdAt, createdAt);
    });

    testWidgets('detail markPickedUp updates detail status immediately', (
      tester,
    ) async {
      final repository = _FakePickupCredentialRepository(
        initialCredentials: [_credential(id: 1, status: PickupStatus.pending)],
      );
      await _pumpHome(tester, repository: repository);
      await _openDetail(tester, 1);

      await tester.tap(find.byKey(const Key('detailMarkPickedUpButton')));
      await tester.pumpAndSettle();

      expect(find.text('已取件'), findsOneWidget);
      expect(find.byKey(const Key('detailMarkPendingButton')), findsOneWidget);
    });

    testWidgets('detail markPending updates detail status immediately', (
      tester,
    ) async {
      final repository = _FakePickupCredentialRepository(
        initialCredentials: [_credential(id: 1, status: PickupStatus.pickedUp)],
      );
      await _pumpHome(tester, repository: repository);
      await _openDetail(tester, 1);

      await tester.tap(find.byKey(const Key('detailMarkPendingButton')));
      await tester.pumpAndSettle();

      expect(find.text('待取件'), findsOneWidget);
      expect(find.byKey(const Key('detailMarkPickedUpButton')), findsOneWidget);
    });

    testWidgets('delete action first shows confirmation dialog', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        repository: _FakePickupCredentialRepository(
          initialCredentials: [_credential(id: 1)],
        ),
      );
      await _openDetail(tester, 1);

      await tester.tap(find.byKey(const Key('deleteCredentialButton')));
      await tester.pumpAndSettle();

      expect(find.text('删除取件凭证？'), findsOneWidget);
      expect(find.text('删除后无法恢复。'), findsOneWidget);
      expect(
        find.byKey(const Key('cancelDeleteCredentialButton')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('confirmDeleteCredentialButton')),
        findsOneWidget,
      );
    });

    testWidgets('canceling delete does not call deleteById', (tester) async {
      final repository = _FakePickupCredentialRepository(
        initialCredentials: [_credential(id: 1)],
      );
      await _pumpHome(tester, repository: repository);
      await _openDetail(tester, 1);

      await tester.tap(find.byKey(const Key('deleteCredentialButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cancelDeleteCredentialButton')));
      await tester.pumpAndSettle();

      expect(repository.deleteByIdCallCount, 0);
      expect(find.text('取件凭证详情'), findsOneWidget);
    });

    testWidgets('confirming delete calls deleteById once', (tester) async {
      final repository = _FakePickupCredentialRepository(
        initialCredentials: [_credential(id: 1)],
      );
      await _pumpHome(tester, repository: repository);
      await _openDetail(tester, 1);

      await tester.tap(find.byKey(const Key('deleteCredentialButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmDeleteCredentialButton')));
      await tester.pumpAndSettle();

      expect(repository.deleteByIdCallCount, 1);
      expect(repository.deletedIds, [1]);
    });

    testWidgets('delete success returns home and removes item', (tester) async {
      final repository = _FakePickupCredentialRepository(
        initialCredentials: [_credential(id: 1, pickupCode: 'DELETE-ME')],
      );
      await _pumpHome(tester, repository: repository);
      await _openDetail(tester, 1);

      await tester.tap(find.byKey(const Key('deleteCredentialButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmDeleteCredentialButton')));
      await tester.pumpAndSettle();

      expect(find.text('取件凭证详情'), findsNothing);
      expect(find.text('DELETE-ME'), findsNothing);
      expect(find.text('暂无取件凭证'), findsOneWidget);
    });

    testWidgets('delete failure stays on detail and shows error', (
      tester,
    ) async {
      final repository = _FakePickupCredentialRepository(
        failDeleteByIdCount: 1,
        initialCredentials: [_credential(id: 1)],
      );
      await _pumpHome(tester, repository: repository);
      await _openDetail(tester, 1);

      await tester.tap(find.byKey(const Key('deleteCredentialButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmDeleteCredentialButton')));
      await tester.pumpAndSettle();

      expect(find.text('取件凭证详情'), findsOneWidget);
      expect(find.text('无法删除取件凭证'), findsOneWidget);
    });

    testWidgets('repeated lifecycle taps call repository only once at a time', (
      tester,
    ) async {
      final completer = Completer<void>();
      final repository = _FakePickupCredentialRepository(
        beforeMarkPickedUpCompletes: completer.future,
        initialCredentials: [_credential(id: 1, status: PickupStatus.pending)],
      );
      await _pumpHome(tester, repository: repository);

      await tester.tap(find.byKey(const Key('credentialLifecycleButton-1')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('credentialLifecycleButton-1')));
      await tester.pump();

      expect(repository.markPickedUpCallCount, 1);

      completer.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('tapping batch operation enters selection mode', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        repository: _FakePickupCredentialRepository(
          initialCredentials: [_credential(id: 1)],
        ),
      );

      await _enterSelectionMode(tester);

      expect(
        find.byKey(const Key('cancelSelectionModeButton')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('selectedCredentialCount')), findsOneWidget);
      expect(find.text('已选择 0 个'), findsWidgets);
    });

    testWidgets('selection mode card tap selects without opening detail', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        repository: _FakePickupCredentialRepository(
          initialCredentials: [_credential(id: 1)],
        ),
      );
      await _enterSelectionMode(tester);

      await tester.tap(find.byKey(const Key('credentialCard-1')));
      await tester.pumpAndSettle();

      expect(find.text('取件凭证详情'), findsNothing);
      expect(find.text('已选择 1 个'), findsWidgets);
      final checkbox = tester.widget<Checkbox>(
        find.byKey(const Key('credentialSelectionCheckbox-1')),
      );
      expect(checkbox.value, isTrue);
    });

    testWidgets('selected count updates correctly', (tester) async {
      await _pumpHome(
        tester,
        repository: _FakePickupCredentialRepository(
          initialCredentials: [
            _credential(id: 1, pickupCode: 'ONE'),
            _credential(id: 2, pickupCode: 'TWO'),
          ],
        ),
      );
      await _enterSelectionMode(tester);

      await _tapVisible(tester, const Key('credentialCard-1'));
      await tester.pumpAndSettle();
      await _tapVisible(tester, const Key('credentialCard-2'));
      await tester.pumpAndSettle();

      expect(find.text('已选择 2 个'), findsWidgets);
    });

    testWidgets('tapping same card twice deselects it', (tester) async {
      await _pumpHome(
        tester,
        repository: _FakePickupCredentialRepository(
          initialCredentials: [_credential(id: 1)],
        ),
      );
      await _enterSelectionMode(tester);

      await tester.tap(find.byKey(const Key('credentialCard-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('credentialCard-1')));
      await tester.pumpAndSettle();

      expect(find.text('已选择 0 个'), findsWidgets);
      final checkbox = tester.widget<Checkbox>(
        find.byKey(const Key('credentialSelectionCheckbox-1')),
      );
      expect(checkbox.value, isFalse);
    });

    testWidgets('select all selects all loaded credentials', (tester) async {
      await _pumpHome(
        tester,
        repository: _FakePickupCredentialRepository(
          initialCredentials: [
            _credential(id: 1, status: PickupStatus.pending),
            _credential(id: 2, status: PickupStatus.unknown),
            _credential(id: 3, status: PickupStatus.pickedUp),
          ],
        ),
      );
      await _enterSelectionMode(tester);

      await tester.tap(find.byKey(const Key('selectAllCredentialsButton')));
      await tester.pumpAndSettle();

      expect(find.text('已选择 3 个'), findsWidgets);
      expect(find.text('取消全选'), findsOneWidget);
    });

    testWidgets('cancel select all clears selected ids', (tester) async {
      await _pumpHome(
        tester,
        repository: _FakePickupCredentialRepository(
          initialCredentials: [_credential(id: 1), _credential(id: 2)],
        ),
      );
      await _enterSelectionMode(tester);

      await tester.tap(find.byKey(const Key('selectAllCredentialsButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('selectAllCredentialsButton')));
      await tester.pumpAndSettle();

      expect(find.text('已选择 0 个'), findsWidgets);
      expect(find.text('全选'), findsOneWidget);
    });

    testWidgets('cancel exits selection mode and clears selection', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        repository: _FakePickupCredentialRepository(
          initialCredentials: [_credential(id: 1)],
        ),
      );
      await _enterSelectionMode(tester);
      await tester.tap(find.byKey(const Key('credentialCard-1')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cancelSelectionModeButton')));
      await tester.pumpAndSettle();
      await _enterSelectionMode(tester);

      expect(find.text('已选择 0 个'), findsWidgets);
    });

    testWidgets('batch buttons are disabled with no selection', (tester) async {
      await _pumpHome(
        tester,
        repository: _FakePickupCredentialRepository(
          initialCredentials: [_credential(id: 1)],
        ),
      );
      await _enterSelectionMode(tester);

      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('batchMarkPickedUpButton')),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('batchMarkPendingButton')),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('batchDeleteButton')))
            .onPressed,
        isNull,
      );
    });

    testWidgets('batch mark picked up calls repository once with 3 ids', (
      tester,
    ) async {
      final repository = _FakePickupCredentialRepository(
        initialCredentials: [
          _credential(id: 1, status: PickupStatus.pending),
          _credential(id: 2, status: PickupStatus.unknown),
          _credential(id: 3, status: PickupStatus.pickedUp),
        ],
      );
      await _pumpHome(tester, repository: repository);
      await _enterSelectionMode(tester);
      await tester.tap(find.byKey(const Key('selectAllCredentialsButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('batchMarkPickedUpButton')));
      await tester.pumpAndSettle();

      expect(repository.markPickedUpAllCallCount, 1);
      expect(repository.markPickedUpAllIds.single, [1, 2, 3]);
      expect(find.text('已标记 3 个凭证为已取件'), findsOneWidget);
    });

    testWidgets('batch success reloads and exits selection mode', (
      tester,
    ) async {
      final repository = _FakePickupCredentialRepository(
        initialCredentials: [_credential(id: 1, status: PickupStatus.pending)],
      );
      await _pumpHome(tester, repository: repository);
      await _enterSelectionMode(tester);
      await tester.tap(find.byKey(const Key('credentialCard-1')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('batchMarkPickedUpButton')));
      await tester.pumpAndSettle();

      expect(repository.getAllCallCount, 2);
      expect(find.byKey(const Key('cancelSelectionModeButton')), findsNothing);
      expect(find.byKey(const Key('batchMarkPickedUpButton')), findsNothing);
    });

    testWidgets('batch failure keeps selection mode and selected ids', (
      tester,
    ) async {
      final repository = _FakePickupCredentialRepository(
        initialCredentials: [_credential(id: 1), _credential(id: 2)],
      )..failMarkPickedUpAllCount = 1;
      await _pumpHome(tester, repository: repository);
      await _enterSelectionMode(tester);
      await tester.tap(find.byKey(const Key('selectAllCredentialsButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('batchMarkPickedUpButton')));
      await tester.pumpAndSettle();

      expect(find.text('无法更新取件状态'), findsOneWidget);
      expect(
        find.byKey(const Key('cancelSelectionModeButton')),
        findsOneWidget,
      );
      expect(find.text('已选择 2 个'), findsWidgets);
    });

    testWidgets('batch restore pending calls markPendingAll once', (
      tester,
    ) async {
      final repository = _FakePickupCredentialRepository(
        initialCredentials: [
          _credential(id: 1, status: PickupStatus.pickedUp),
          _credential(id: 2, status: PickupStatus.unknown),
        ],
      );
      await _pumpHome(tester, repository: repository);
      await _enterSelectionMode(tester);
      await tester.tap(find.byKey(const Key('selectAllCredentialsButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('batchMarkPendingButton')));
      await tester.pumpAndSettle();

      expect(repository.markPendingAllCallCount, 1);
      expect(repository.markPendingAllIds.single, [1, 2]);
      expect(find.text('已恢复 2 个凭证为待取件'), findsOneWidget);
    });

    testWidgets('batch delete first shows confirmation dialog', (tester) async {
      await _pumpHome(
        tester,
        repository: _FakePickupCredentialRepository(
          initialCredentials: [_credential(id: 1), _credential(id: 2)],
        ),
      );
      await _enterSelectionMode(tester);
      await tester.tap(find.byKey(const Key('selectAllCredentialsButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('batchDeleteButton')));
      await tester.pumpAndSettle();

      expect(find.text('删除 2 个取件凭证？'), findsOneWidget);
      expect(find.text('删除后无法恢复。'), findsOneWidget);
      expect(find.byKey(const Key('cancelBatchDeleteButton')), findsOneWidget);
      expect(find.byKey(const Key('confirmBatchDeleteButton')), findsOneWidget);
    });

    testWidgets(
      'cancel batch delete does not call deleteAll and keeps selection',
      (tester) async {
        final repository = _FakePickupCredentialRepository(
          initialCredentials: [_credential(id: 1), _credential(id: 2)],
        );
        await _pumpHome(tester, repository: repository);
        await _enterSelectionMode(tester);
        await tester.tap(find.byKey(const Key('selectAllCredentialsButton')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('batchDeleteButton')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('cancelBatchDeleteButton')));
        await tester.pumpAndSettle();

        expect(repository.deleteAllCallCount, 0);
        expect(
          find.byKey(const Key('cancelSelectionModeButton')),
          findsOneWidget,
        );
        expect(find.text('已选择 2 个'), findsWidgets);
      },
    );

    testWidgets('confirm batch delete calls deleteAll once', (tester) async {
      final repository = _FakePickupCredentialRepository(
        initialCredentials: [_credential(id: 1), _credential(id: 2)],
      );
      await _pumpHome(tester, repository: repository);
      await _enterSelectionMode(tester);
      await tester.tap(find.byKey(const Key('selectAllCredentialsButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('batchDeleteButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmBatchDeleteButton')));
      await tester.pumpAndSettle();

      expect(repository.deleteAllCallCount, 1);
      expect(repository.deleteAllIds.single, [1, 2]);
      expect(find.text('已删除 2 个取件凭证'), findsOneWidget);
    });

    testWidgets('repeated batch action only runs one repository operation', (
      tester,
    ) async {
      final completer = Completer<void>();
      final repository = _FakePickupCredentialRepository(
        beforeMarkPickedUpAllCompletes: completer.future,
        initialCredentials: [_credential(id: 1), _credential(id: 2)],
      );
      await _pumpHome(tester, repository: repository);
      await _enterSelectionMode(tester);
      await tester.tap(find.byKey(const Key('selectAllCredentialsButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('batchMarkPickedUpButton')));
      await tester.tap(find.byKey(const Key('batchMarkPickedUpButton')));
      await tester.pump();

      expect(repository.markPickedUpAllCallCount, 1);

      completer.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('normal mode card contains trailing delete action', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        repository: _FakePickupCredentialRepository(
          initialCredentials: [_credential(id: 1)],
        ),
      );

      await _openSlidableActionPane(tester, 1);

      expect(find.byType(Slidable), findsOneWidget);
      expect(
        find.byKey(const Key('credentialDeleteAction-1'), skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('selection mode does not enable swipe action', (tester) async {
      await _pumpHome(
        tester,
        repository: _FakePickupCredentialRepository(
          initialCredentials: [_credential(id: 1)],
        ),
      );
      await _enterSelectionMode(tester);

      expect(find.byType(Slidable), findsNothing);
      expect(
        find.byKey(const Key('credentialDeleteAction-1'), skipOffstage: false),
        findsNothing,
      );
    });

    testWidgets('pending section groups credentials by courier', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        repository: _FakePickupCredentialRepository(
          initialCredentials: [
            _credential(
              id: 1,
              courierCompany: CourierCompany.jtexpress,
              pickupCode: 'JT-1',
            ),
            _credential(
              id: 2,
              courierCompany: CourierCompany.sfExpress,
              pickupCode: 'SF-1',
            ),
            _credential(
              id: 3,
              courierCompany: CourierCompany.jtexpress,
              pickupCode: 'JT-2',
            ),
          ],
        ),
      );

      expect(_findInSection('待取件', '待取件 · 3'), findsOneWidget);
      expect(_findInSection('待取件', '极兔速递 · 2'), findsOneWidget);
      expect(_findInSection('待取件', '顺丰速运 · 1'), findsOneWidget);
      expect(_findInSection('待取件', 'JT-1'), findsOneWidget);
      expect(_findInSection('待取件', 'JT-2'), findsOneWidget);
      expect(_findInSection('待取件', 'SF-1'), findsOneWidget);
    });

    testWidgets('home card hides repeated courier text inside courier group', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        repository: _FakePickupCredentialRepository(
          initialCredentials: [
            _credential(id: 1, courierCompany: CourierCompany.jtexpress),
            _credential(id: 2, courierCompany: CourierCompany.jtexpress),
          ],
        ),
      );

      expect(find.text('极兔速递 · 2'), findsOneWidget);
      expect(find.text('极兔速递'), findsNothing);
    });

    testWidgets('pickedUp section also groups by courier', (tester) async {
      await _pumpHome(
        tester,
        repository: _FakePickupCredentialRepository(
          initialCredentials: [
            _credential(
              id: 1,
              courierCompany: CourierCompany.jtexpress,
              status: PickupStatus.pickedUp,
              pickupCode: 'DONE-JT',
            ),
            _credential(
              id: 2,
              courierCompany: CourierCompany.sfExpress,
              status: PickupStatus.pickedUp,
              pickupCode: 'DONE-SF',
            ),
            _credential(
              id: 3,
              courierCompany: CourierCompany.sfExpress,
              status: PickupStatus.pickedUp,
              pickupCode: 'DONE-SF-2',
            ),
          ],
        ),
      );

      expect(_findInSection('已取件', '已取件 · 3'), findsOneWidget);
      expect(_findInSection('已取件', '顺丰速运 · 2'), findsOneWidget);
      expect(_findInSection('已取件', '极兔速递 · 1'), findsOneWidget);
      expect(_findInSection('已取件', 'DONE-SF'), findsOneWidget);
      expect(_findInSection('已取件', 'DONE-JT'), findsOneWidget);
    });

    testWidgets('unknown section groups unknown courier', (tester) async {
      await _pumpHome(
        tester,
        repository: _FakePickupCredentialRepository(
          initialCredentials: [
            _credential(
              id: 1,
              courierCompany: CourierCompany.unknown,
              status: PickupStatus.unknown,
              pickupCode: 'UNKNOWN-1',
            ),
            _credential(
              id: 2,
              courierCompany: CourierCompany.sfExpress,
              status: PickupStatus.unknown,
              pickupCode: 'UNKNOWN-SF',
            ),
          ],
        ),
      );

      expect(_findInSection('未判断', '未判断 · 2'), findsOneWidget);
      expect(_findInSection('未判断', '顺丰速运 · 1'), findsOneWidget);
      expect(_findInSection('未判断', '未识别快递公司 · 1'), findsOneWidget);
      expect(_findInSection('未判断', 'UNKNOWN-1'), findsOneWidget);
    });

    testWidgets('missing pickupCode renders fallback inside courier group', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        repository: _FakePickupCredentialRepository(
          initialCredentials: [
            _credential(
              id: 1,
              courierCompany: CourierCompany.sfExpress,
              pickupCode: null,
            ),
          ],
        ),
      );

      expect(find.text('顺丰速运 · 1'), findsOneWidget);
      expect(find.text('未识别取件码'), findsOneWidget);
    });

    testWidgets('markPickedUp moves item between courier groups', (
      tester,
    ) async {
      final repository = _FakePickupCredentialRepository(
        initialCredentials: [
          _credential(
            id: 1,
            courierCompany: CourierCompany.jtexpress,
            pickupCode: 'MOVE-JT',
            status: PickupStatus.pending,
          ),
        ],
      );
      await _pumpHome(tester, repository: repository);

      await tester.tap(find.byKey(const Key('credentialLifecycleButton-1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('credentialSection-待取件')), findsNothing);
      expect(_findInSection('已取件', '极兔速递 · 1'), findsOneWidget);
      expect(_findInSection('已取件', 'MOVE-JT'), findsOneWidget);
    });

    testWidgets('markPending moves item back into pending courier group', (
      tester,
    ) async {
      final repository = _FakePickupCredentialRepository(
        initialCredentials: [
          _credential(
            id: 1,
            courierCompany: CourierCompany.jtexpress,
            pickupCode: 'BACK-JT',
            status: PickupStatus.pickedUp,
          ),
        ],
      );
      await _pumpHome(tester, repository: repository);

      await tester.tap(find.byKey(const Key('credentialLifecycleButton-1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('credentialSection-已取件')), findsNothing);
      expect(_findInSection('待取件', '极兔速递 · 1'), findsOneWidget);
      expect(_findInSection('待取件', 'BACK-JT'), findsOneWidget);
    });

    testWidgets('selection mode supports selecting across courier groups', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        repository: _FakePickupCredentialRepository(
          initialCredentials: [
            _credential(id: 1, courierCompany: CourierCompany.jtexpress),
            _credential(id: 2, courierCompany: CourierCompany.sfExpress),
            _credential(id: 3, courierCompany: CourierCompany.zto),
          ],
        ),
      );
      await _enterSelectionMode(tester);

      await _tapVisible(tester, const Key('credentialCard-1'));
      await tester.pumpAndSettle();
      await _tapVisible(tester, const Key('credentialCard-2'));
      await tester.pumpAndSettle();

      expect(find.text('已选择 2 个'), findsWidgets);
      expect(
        tester
            .widget<Checkbox>(
              find.byKey(const Key('credentialSelectionCheckbox-1')),
            )
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<Checkbox>(
              find.byKey(const Key('credentialSelectionCheckbox-2')),
            )
            .value,
        isTrue,
      );
    });

    testWidgets('select all still selects all credentials across groups', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        repository: _FakePickupCredentialRepository(
          initialCredentials: [
            _credential(id: 1, courierCompany: CourierCompany.jtexpress),
            _credential(id: 2, courierCompany: CourierCompany.sfExpress),
            _credential(
              id: 3,
              courierCompany: CourierCompany.zto,
              status: PickupStatus.pickedUp,
            ),
          ],
        ),
      );
      await _enterSelectionMode(tester);

      await tester.tap(find.byKey(const Key('selectAllCredentialsButton')));
      await tester.pumpAndSettle();

      expect(find.text('已选择 3 个'), findsWidgets);
      expect(find.text('取消全选'), findsOneWidget);
    });

    testWidgets('cancel select all clears credentials across groups', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        repository: _FakePickupCredentialRepository(
          initialCredentials: [
            _credential(id: 1, courierCompany: CourierCompany.jtexpress),
            _credential(id: 2, courierCompany: CourierCompany.sfExpress),
          ],
        ),
      );
      await _enterSelectionMode(tester);

      await tester.tap(find.byKey(const Key('selectAllCredentialsButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('selectAllCredentialsButton')));
      await tester.pumpAndSettle();

      expect(find.text('已选择 0 个'), findsWidgets);
      expect(find.text('全选'), findsOneWidget);
    });

    testWidgets('batch mark picked up refreshes courier grouping', (
      tester,
    ) async {
      final repository = _FakePickupCredentialRepository(
        initialCredentials: [
          _credential(
            id: 1,
            courierCompany: CourierCompany.jtexpress,
            pickupCode: 'JT-BATCH',
          ),
          _credential(
            id: 2,
            courierCompany: CourierCompany.sfExpress,
            pickupCode: 'SF-BATCH',
          ),
          _credential(
            id: 3,
            courierCompany: CourierCompany.zto,
            pickupCode: 'ZTO-STAY',
          ),
        ],
      );
      await _pumpHome(tester, repository: repository);
      await _enterSelectionMode(tester);
      await _tapVisible(tester, const Key('credentialCard-1'));
      await tester.pumpAndSettle();
      await _tapVisible(tester, const Key('credentialCard-2'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('batchMarkPickedUpButton')));
      await tester.pumpAndSettle();

      expect(_findInSection('待取件', '中通快递 · 1'), findsOneWidget);
      expect(_findInSection('待取件', '极兔速递 · 1'), findsNothing);
      expect(_findInSection('待取件', '顺丰速运 · 1'), findsNothing);
      expect(_findInSection('已取件', '极兔速递 · 1'), findsOneWidget);
      expect(_findInSection('已取件', '顺丰速运 · 1'), findsOneWidget);
      expect(_findInSection('已取件', 'JT-BATCH'), findsOneWidget);
      expect(_findInSection('已取件', 'SF-BATCH'), findsOneWidget);
    });

    testWidgets('single delete removes empty courier group', (tester) async {
      final repository = _FakePickupCredentialRepository(
        initialCredentials: [
          _credential(
            id: 1,
            courierCompany: CourierCompany.jtexpress,
            pickupCode: 'DELETE-JT',
          ),
          _credential(
            id: 2,
            courierCompany: CourierCompany.sfExpress,
            pickupCode: 'KEEP-SF',
          ),
        ],
      );
      await _pumpHome(tester, repository: repository);

      await _triggerSlidableDelete(tester, 1);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmDeleteCredentialButton')));
      await tester.pumpAndSettle();

      expect(_findInSection('待取件', '极兔速递 · 1'), findsNothing);
      expect(_findInSection('待取件', '顺丰速运 · 1'), findsOneWidget);
      expect(find.text('DELETE-JT'), findsNothing);
      expect(find.text('KEEP-SF'), findsOneWidget);
    });

    testWidgets('normal mode supports slidable inside courier group', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        repository: _FakePickupCredentialRepository(
          initialCredentials: [
            _credential(id: 1, courierCompany: CourierCompany.jtexpress),
            _credential(id: 2, courierCompany: CourierCompany.sfExpress),
          ],
        ),
      );

      await _openSlidableActionPane(tester, 2);

      expect(find.byType(Slidable), findsNWidgets(2));
      expect(
        find.byKey(const Key('credentialDeleteAction-2'), skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('selection mode disables slidable inside courier group', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        repository: _FakePickupCredentialRepository(
          initialCredentials: [
            _credential(id: 1, courierCompany: CourierCompany.jtexpress),
            _credential(id: 2, courierCompany: CourierCompany.sfExpress),
          ],
        ),
      );
      await _enterSelectionMode(tester);

      expect(find.byType(Slidable), findsNothing);
      expect(
        find.byKey(const Key('credentialDeleteAction-2'), skipOffstage: false),
        findsNothing,
      );
    });

    testWidgets('single delete action shows confirmation dialog', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        repository: _FakePickupCredentialRepository(
          initialCredentials: [_credential(id: 1)],
        ),
      );

      await _triggerSlidableDelete(tester, 1);
      await tester.pumpAndSettle();

      expect(find.text('删除取件凭证？'), findsOneWidget);
      expect(find.text('删除后无法恢复。'), findsOneWidget);
    });

    testWidgets('confirming single delete calls deleteById once', (
      tester,
    ) async {
      final repository = _FakePickupCredentialRepository(
        initialCredentials: [_credential(id: 1)],
      );
      await _pumpHome(tester, repository: repository);

      await _triggerSlidableDelete(tester, 1);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmDeleteCredentialButton')));
      await tester.pumpAndSettle();

      expect(repository.deleteByIdCallCount, 1);
      expect(repository.deletedIds, [1]);
    });

    testWidgets('canceling single delete action does not delete', (
      tester,
    ) async {
      final repository = _FakePickupCredentialRepository(
        initialCredentials: [_credential(id: 1)],
      );
      await _pumpHome(tester, repository: repository);

      await _triggerSlidableDelete(tester, 1);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cancelDeleteCredentialButton')));
      await tester.pumpAndSettle();

      expect(repository.deleteByIdCallCount, 0);
      expect(find.byKey(const Key('credentialCard-1')), findsOneWidget);
    });

    testWidgets('clearing pickupCode saves null', (tester) async {
      final repository = _FakePickupCredentialRepository(
        initialCredentials: [_credential(id: 1, pickupCode: 'OLD')],
      );
      await _pumpHome(tester, repository: repository);
      await _openDetail(tester, 1);
      await _openEdit(tester);

      await tester.enterText(
        find.byKey(const Key('editPickupCodeField')),
        '   ',
      );
      await tester.tap(find.byKey(const Key('saveCredentialEditButton')));
      await tester.pumpAndSettle();

      expect(repository.lastUpdatedCredential!.pickupCode, isNull);
      expect(find.text('未填写'), findsOneWidget);
    });

    testWidgets('clearing trackingNumber saves null', (tester) async {
      final repository = _FakePickupCredentialRepository(
        initialCredentials: [_credential(id: 1, trackingNumber: 'OLDTRACK')],
      );
      await _pumpHome(tester, repository: repository);
      await _openDetail(tester, 1);
      await _openEdit(tester);

      await tester.enterText(
        find.byKey(const Key('editTrackingNumberField')),
        '   ',
      );
      await tester.tap(find.byKey(const Key('saveCredentialEditButton')));
      await tester.pumpAndSettle();

      expect(repository.lastUpdatedCredential!.trackingNumber, isNull);
      expect(find.text('未填写'), findsOneWidget);
    });
  });
}

Future<void> _pumpHome(
  WidgetTester tester, {
  required _FakePickupCredentialRepository repository,
  ImagePathPicker? imagePathPicker,
  ImportPageBuilder? importPageBuilder,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: HomePage(
        repository: repository,
        imagePathPicker: imagePathPicker,
        importPageBuilder: importPageBuilder,
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void _expectSingleLineAction(
  WidgetTester tester, {
  required Finder button,
  required String label,
}) {
  final textFinder = find.descendant(of: button, matching: find.text(label));
  expect(textFinder, findsOneWidget);
  final text = tester.widget<Text>(textFinder);
  expect(text.maxLines, 1);
  expect(text.softWrap, isFalse);
  expect(
    tester.getSize(button).width,
    greaterThanOrEqualTo(PHSizes.minInteractive),
  );
  if (label.length > 2) {
    expect(tester.getSize(button).width, greaterThan(PHSizes.minInteractive));
  }
  expect(
    tester.getSize(button).height,
    greaterThanOrEqualTo(PHSizes.minInteractive),
  );
}

Future<void> _runImport(WidgetTester tester) async {
  await tester.tap(find.text('添加截图'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('returnImportResultButton')));
  await tester.pumpAndSettle();
}

Future<void> _enterSelectionMode(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('enterSelectionModeButton')));
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

Future<void> _openSlidableActionPane(WidgetTester tester, int id) async {
  await tester.drag(
    find.byKey(Key('credentialCard-$id')),
    const Offset(-300, 0),
  );
  await tester.pumpAndSettle();
}

Future<void> _triggerSlidableDelete(WidgetTester tester, int id) async {
  await _openSlidableActionPane(tester, id);
  await tester.tap(
    find.byKey(Key('credentialDeleteAction-$id'), skipOffstage: false),
  );
}

Finder _duplicateDecisionText(int incomingIndex, String text) {
  return find.descendant(
    of: find.byKey(Key('duplicateDecision_$incomingIndex')),
    matching: find.text(text),
  );
}

Future<void> _openDetail(WidgetTester tester, int id) async {
  await tester.tap(find.byKey(Key('credentialCard-$id')));
  await tester.pumpAndSettle();
}

Future<void> _openEdit(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('editCredentialButton')));
  await tester.pumpAndSettle();
}

Future<void> _selectDropdownOption(
  WidgetTester tester, {
  required Key fieldKey,
  required String optionText,
}) async {
  await tester.tap(find.byKey(fieldKey));
  await tester.pumpAndSettle();
  await tester.drag(find.byType(Scrollable).last, const Offset(0, 260));
  await tester.pumpAndSettle();
  await tester.tap(find.text(optionText).last);
  await tester.pumpAndSettle();
}

Finder _findInSection(String sectionTitle, String text) {
  return find.descendant(
    of: find.byKey(Key('credentialSection-$sectionTitle')),
    matching: find.text(text),
  );
}

PickupCredentialDraft _draft({
  CourierCompany courierCompany = CourierCompany.jtexpress,
  String? trackingNumber = 'JT5519167631350',
  String? pickupCode = 'Z5-2-1350',
  String? stationName = '兔喜快递超市',
  PickupStatus status = PickupStatus.pending,
  PackagePlatform sourcePlatform = PackagePlatform.pinduoduo,
}) {
  return PickupCredentialDraft(
    courierCompany: courierCompany,
    trackingNumber: trackingNumber,
    pickupCode: pickupCode,
    stationName: stationName,
    status: status,
    sourcePlatform: sourcePlatform,
    rawText: 'raw OCR text',
  );
}

PickupCredential _credential({
  int id = 1,
  CourierCompany courierCompany = CourierCompany.jtexpress,
  String? trackingNumber = 'JT5519167631350',
  String? pickupCode = 'Z5-2-1350',
  PickupStatus status = PickupStatus.pending,
  PackagePlatform sourcePlatform = PackagePlatform.pinduoduo,
  DateTime? createdAt,
}) {
  final now = createdAt ?? DateTime(2026);
  return PickupCredential(
    id: id,
    courierCompany: courierCompany,
    trackingNumber: trackingNumber,
    pickupCode: pickupCode,
    status: status,
    sourcePlatform: sourcePlatform,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakePickupCredentialRepository implements PickupCredentialRepositoryApi {
  final List<PickupCredential> _credentials;
  final Future<void>? beforeInsertCompletes;
  int failInsertCount;
  int failGetAllCount;
  int failMarkPickedUpCount;
  int failMarkPendingCount = 0;
  int failMarkPickedUpAllCount = 0;
  int failMarkPendingAllCount = 0;
  int failUpdateCount = 0;
  int failDeleteByIdCount;
  int failDeleteAllCount = 0;

  int getAllCallCount = 0;
  int findByTrackingNumberCallCount = 0;
  int insertAllCallCount = 0;
  int markPickedUpCallCount = 0;
  int markPendingCallCount = 0;
  int markPickedUpAllCallCount = 0;
  int markPendingAllCallCount = 0;
  int updateCallCount = 0;
  int deleteByIdCallCount = 0;
  int deleteAllCallCount = 0;
  final List<int> markPickedUpIds = [];
  final List<int> markPendingIds = [];
  final List<int> deletedIds = [];
  final List<String> findByTrackingNumberValues = [];
  final List<List<int>> markPickedUpAllIds = [];
  final List<List<int>> markPendingAllIds = [];
  final List<List<int>> deleteAllIds = [];
  List<PickupCredentialDraft>? lastInsertedDrafts;
  PickupCredential? lastUpdatedCredential;
  Future<void>? beforeMarkPickedUpCompletes;
  Future<void>? beforeMarkPendingCompletes;
  Future<void>? beforeMarkPickedUpAllCompletes;
  Future<void>? beforeMarkPendingAllCompletes;
  Future<void>? beforeUpdateCompletes;
  Future<void>? beforeDeleteCompletes;
  Future<void>? beforeDeleteAllCompletes;

  _FakePickupCredentialRepository({
    List<PickupCredential>? initialCredentials,
    this.beforeInsertCompletes,
    this.failInsertCount = 0,
    this.failGetAllCount = 0,
    this.failMarkPickedUpCount = 0,
    this.failDeleteByIdCount = 0,
    this.beforeMarkPickedUpCompletes,
    this.beforeMarkPickedUpAllCompletes,
  }) : _credentials = List.of(initialCredentials ?? const []);

  @override
  Future<List<PickupCredential>> getAll() async {
    getAllCallCount += 1;
    if (failGetAllCount > 0) {
      failGetAllCount -= 1;
      throw Exception('load failed');
    }

    return List.of(_credentials);
  }

  @override
  Future<List<PickupCredential>> getPending() async {
    return _credentials
        .where((credential) => credential.status == PickupStatus.pending)
        .toList();
  }

  @override
  Future<List<PickupCredential>> getPickedUp() async {
    return _credentials
        .where((credential) => credential.status == PickupStatus.pickedUp)
        .toList();
  }

  @override
  Future<List<PickupCredential>> findByTrackingNumber(
    String trackingNumber,
  ) async {
    findByTrackingNumberCallCount += 1;
    findByTrackingNumberValues.add(trackingNumber);
    final normalizedTrackingNumber = normalizeTrackingNumber(trackingNumber);
    if (normalizedTrackingNumber == null) {
      return [];
    }

    return _credentials
        .where(
          (credential) =>
              normalizeTrackingNumber(credential.trackingNumber) ==
              normalizedTrackingNumber,
        )
        .toList();
  }

  @override
  Future<List<PickupCredential>> insertAll(
    List<PickupCredentialDraft> drafts,
  ) async {
    insertAllCallCount += 1;
    lastInsertedDrafts = List.of(drafts);

    await beforeInsertCompletes;

    if (failInsertCount > 0) {
      failInsertCount -= 1;
      throw Exception('save failed');
    }

    final insertedCredentials = drafts.map((draft) {
      final credential = PickupCredential.fromDraft(
        draft,
        id: _credentials.length + 1,
        now: DateTime(2026),
      );
      _credentials.add(credential);
      return credential;
    }).toList();

    return insertedCredentials;
  }

  @override
  Future<PickupCredential> update(PickupCredential credential) async {
    updateCallCount += 1;
    lastUpdatedCredential = credential;
    await beforeUpdateCompletes;

    if (failUpdateCount > 0) {
      failUpdateCount -= 1;
      throw Exception('update failed');
    }

    final id = credential.id;
    if (id == null) {
      throw ArgumentError.value(id, 'credential.id');
    }

    final index = _credentials.indexWhere((candidate) => candidate.id == id);
    if (index == -1) {
      throw StateError('No pickup credential exists for id $id.');
    }

    final updated = _credentials[index].copyWith(
      courierCompany: credential.courierCompany,
      trackingNumber: credential.trackingNumber,
      pickupCode: credential.pickupCode,
      status: credential.status,
      sourcePlatform: credential.sourcePlatform,
      updatedAt: DateTime(2026, 1, 2),
    );
    _credentials[index] = updated;
    return updated;
  }

  @override
  Future<PickupCredential> markPickedUp(int id) async {
    markPickedUpCallCount += 1;
    markPickedUpIds.add(id);
    await beforeMarkPickedUpCompletes;

    if (failMarkPickedUpCount > 0) {
      failMarkPickedUpCount -= 1;
      throw Exception('mark picked up failed');
    }

    final credential = _credentials.firstWhere(
      (credential) => credential.id == id,
      orElse: () => throw StateError('No pickup credential exists for id $id.'),
    );
    final updated = credential.copyWith(
      status: PickupStatus.pickedUp,
      updatedAt: DateTime(2026, 1, 2),
    );
    final index = _credentials.indexWhere((candidate) => candidate.id == id);
    _credentials[index] = updated;
    return updated;
  }

  @override
  Future<PickupCredential> markPending(int id) async {
    markPendingCallCount += 1;
    markPendingIds.add(id);
    await beforeMarkPendingCompletes;

    if (failMarkPendingCount > 0) {
      failMarkPendingCount -= 1;
      throw Exception('mark pending failed');
    }

    final credential = _credentials.firstWhere(
      (credential) => credential.id == id,
      orElse: () => throw StateError('No pickup credential exists for id $id.'),
    );
    final updated = credential.copyWith(
      status: PickupStatus.pending,
      updatedAt: DateTime(2026, 1, 2),
    );
    final index = _credentials.indexWhere((candidate) => candidate.id == id);
    _credentials[index] = updated;
    return updated;
  }

  @override
  Future<List<PickupCredential>> markPickedUpAll(Iterable<int> ids) async {
    markPickedUpAllCallCount += 1;
    final requestedIds = ids.toSet().toList();
    markPickedUpAllIds.add(requestedIds);
    await beforeMarkPickedUpAllCompletes;

    if (failMarkPickedUpAllCount > 0) {
      failMarkPickedUpAllCount -= 1;
      throw Exception('batch mark picked up failed');
    }

    return _markAll(requestedIds, PickupStatus.pickedUp);
  }

  @override
  Future<List<PickupCredential>> markPendingAll(Iterable<int> ids) async {
    markPendingAllCallCount += 1;
    final requestedIds = ids.toSet().toList();
    markPendingAllIds.add(requestedIds);
    await beforeMarkPendingAllCompletes;

    if (failMarkPendingAllCount > 0) {
      failMarkPendingAllCount -= 1;
      throw Exception('batch mark pending failed');
    }

    return _markAll(requestedIds, PickupStatus.pending);
  }

  List<PickupCredential> _markAll(List<int> ids, PickupStatus status) {
    final updatedCredentials = <PickupCredential>[];
    for (final id in ids) {
      final credential = _credentials.firstWhere(
        (credential) => credential.id == id,
        orElse: () =>
            throw StateError('No pickup credential exists for id $id.'),
      );
      final updated = credential.copyWith(
        status: status,
        updatedAt: DateTime(2026, 1, 2),
      );
      final index = _credentials.indexWhere((candidate) => candidate.id == id);
      _credentials[index] = updated;
      updatedCredentials.add(updated);
    }
    return updatedCredentials;
  }

  @override
  Future<void> deleteById(int id) async {
    deleteByIdCallCount += 1;
    deletedIds.add(id);
    await beforeDeleteCompletes;

    if (failDeleteByIdCount > 0) {
      failDeleteByIdCount -= 1;
      throw Exception('delete failed');
    }

    _credentials.removeWhere((credential) => credential.id == id);
  }

  @override
  Future<void> deleteAll(Iterable<int> ids) async {
    deleteAllCallCount += 1;
    final requestedIds = ids.toSet().toList();
    deleteAllIds.add(requestedIds);
    await beforeDeleteAllCompletes;

    if (failDeleteAllCount > 0) {
      failDeleteAllCount -= 1;
      throw Exception('batch delete failed');
    }

    for (final id in requestedIds) {
      if (!_credentials.any((credential) => credential.id == id)) {
        throw StateError('No pickup credential exists for id $id.');
      }
    }

    _credentials.removeWhere(
      (credential) => requestedIds.contains(credential.id),
    );
  }
}

class _ReturningImportPage extends StatelessWidget {
  final List<PickupCredentialDraft>? result;

  const _ReturningImportPage({required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          key: const Key('returnImportResultButton'),
          onPressed: () {
            Navigator.of(context).pop<List<PickupCredentialDraft>>(result);
          },
          child: const Text('完成导入'),
        ),
      ),
    );
  }
}
