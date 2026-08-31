import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:packagehub/core/ocr/ocr_service.dart';
import 'package:packagehub/features/import/batch_import_page.dart';
import 'package:packagehub/features/import/batch_review_page.dart';
import 'package:packagehub/features/import/pickup_review_page.dart';

void main() {
  testWidgets('shows one item for each image path', (tester) async {
    final ocrService = _FakeOcrService.pending();

    await tester.pumpWidget(
      MaterialApp(
        home: BatchImportPage(
          imagePaths: const ['one.png', 'two.png', 'three.png'],
          ocrService: ocrService,
        ),
      ),
    );

    expect(find.text('批量导入'), findsWidgets);
    expect(find.text('3 张截图'), findsOneWidget);
    expect(find.byKey(const Key('batchImportItem_0')), findsOneWidget);
    expect(find.byKey(const Key('batchImportItem_1')), findsOneWidget);
    expect(find.byKey(const Key('batchImportItem_2')), findsOneWidget);
  });

  testWidgets('marks an item success after OCR and parsing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BatchImportPage(
          imagePaths: const ['one.png'],
          ocrService: _FakeOcrService({
            'one.png': '拼多多\n极兔速递 JT5519167631350\n取件码 Z5-2-1350\n兔喜快递超市',
          }),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('极兔速递'), findsOneWidget);
    expect(find.text('Z5-2-1350'), findsOneWidget);
    expect(find.text('识别成功'), findsOneWidget);
  });

  testWidgets('continues processing after the second image fails', (
    tester,
  ) async {
    final ocrService = _FakeOcrService({
      'one.png': '极兔速递 JT5519167631350\n取件码 Z5-2-1350',
      'two.png': Exception('broken image'),
      'three.png': '顺丰速运 SF1234567890\n取件码 8-3-2051',
    });

    await tester.pumpWidget(
      MaterialApp(
        home: BatchImportPage(
          imagePaths: const ['one.png', 'two.png', 'three.png'],
          ocrService: ocrService,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(ocrService.calls, ['one.png', 'two.png', 'three.png']);
    expect(find.text('极兔速递'), findsOneWidget);
    expect(find.text('顺丰速运'), findsOneWidget);
    expect(find.text('识别失败'), findsWidgets);
    expect(find.text('重新识别'), findsOneWidget);
  });

  testWidgets('updates progress from 0 of 3 to 3 of 3', (tester) async {
    final ocrService = _FakeOcrService({
      'one.png': '极兔速递 JT5519167631350\n取件码 Z5-2-1350',
      'two.png': '顺丰速运 SF1234567890\n取件码 8-3-2051',
      'three.png': '圆通速递\n取件码 6-2-8-1',
    });

    await tester.pumpWidget(
      MaterialApp(
        home: BatchImportPage(
          imagePaths: const ['one.png', 'two.png', 'three.png'],
          ocrService: ocrService,
        ),
      ),
    );

    expect(find.text('正在识别 0 / 3'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('识别完成 3 / 3'), findsOneWidget);
  });

  testWidgets('does not crash for an empty image list', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BatchImportPage(
          imagePaths: const [],
          ocrService: _FakeOcrService({}),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('0 张截图'), findsOneWidget);
    expect(find.text('暂无截图'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('deduplicates repeated paths in the same batch', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BatchImportPage(
          imagePaths: const ['one.png', 'one.png', 'two.png'],
          ocrService: _FakeOcrService({
            'one.png': '极兔速递 JT5519167631350\n取件码 Z5-2-1350',
            'two.png': '顺丰速运 SF1234567890\n取件码 8-3-2051',
          }),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('2 张截图'), findsOneWidget);
    expect(find.byKey(const Key('batchImportItem_0')), findsOneWidget);
    expect(find.byKey(const Key('batchImportItem_1')), findsOneWidget);
    expect(find.byKey(const Key('batchImportItem_2')), findsNothing);
  });

  testWidgets('opens batch review with successful drafts only', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BatchImportPage(
          imagePaths: const ['one.png', 'two.png'],
          ocrService: _FakeOcrService({
            'one.png': '极兔速递 JT5519167631350\n取件码 Z5-2-1350',
            'two.png': Exception('broken image'),
          }),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('openBatchReviewButton')));
    await tester.pumpAndSettle();

    expect(find.text('1 个识别结果'), findsOneWidget);
    expect(find.text('极兔速递'), findsOneWidget);
    expect(find.byKey(const Key('confirmAllButton')), findsOneWidget);
  });

  testWidgets('single image opens the same unified review flow', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BatchImportPage(
          imagePaths: const ['one.png'],
          ocrService: _FakeOcrService({
            'one.png': '极兔速递 JT5519167631350\n取件码 Z5-2-1350',
          }),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('openBatchReviewButton')));
    await tester.pumpAndSettle();

    expect(find.byType(BatchReviewPage), findsOneWidget);
    expect(find.byType(PickupReviewPage), findsNothing);
    expect(find.byKey(const Key('pickupCodeField')), findsOneWidget);
    expect(find.text('1 个识别结果'), findsOneWidget);
  });
}

class _FakeOcrService implements TextRecognitionService {
  final Map<String, Object> responses;
  final List<String> calls = [];
  final Completer<String>? pendingCompleter;

  _FakeOcrService(this.responses) : pendingCompleter = null;

  _FakeOcrService.pending()
    : responses = const {},
      pendingCompleter = Completer<String>();

  @override
  Future<String> recognizeText(String imagePath) async {
    calls.add(imagePath);

    if (pendingCompleter != null) {
      return pendingCompleter!.future;
    }

    final response = responses[imagePath];
    if (response is Exception) {
      throw response;
    }

    if (response is Error) {
      throw response;
    }

    return response as String? ?? '';
  }
}
