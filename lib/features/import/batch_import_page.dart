import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:packagehub/core/ocr/ocr_service.dart';
import 'package:packagehub/core/parser/pickup_parser.dart';
import 'package:packagehub/features/import/batch_import_item.dart';
import 'package:packagehub/features/import/batch_review_page.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';

const int kMaxBatchImageCount = 10;

List<String> normalizeBatchImagePaths(
  Iterable<String> imagePaths, {
  int maxCount = kMaxBatchImageCount,
}) {
  final normalizedPaths = <String>[];
  final seenPaths = <String>{};

  for (final imagePath in imagePaths) {
    if (imagePath.isEmpty || seenPaths.contains(imagePath)) {
      continue;
    }

    seenPaths.add(imagePath);
    normalizedPaths.add(imagePath);

    if (normalizedPaths.length == maxCount) {
      break;
    }
  }

  return normalizedPaths;
}

class BatchImportPage extends StatefulWidget {
  final List<String> imagePaths;
  final TextRecognitionService? ocrService;

  const BatchImportPage({super.key, required this.imagePaths, this.ocrService});

  @override
  State<BatchImportPage> createState() => _BatchImportPageState();
}

class _BatchImportPageState extends State<BatchImportPage> {
  late final TextRecognitionService _ocrService;
  late List<BatchImportItem> _items;

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _ocrService = widget.ocrService ?? const OcrService();
    _items = normalizeBatchImagePaths(widget.imagePaths)
        .map((imagePath) => BatchImportItem(imagePath: imagePath))
        .toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _processPendingItems();
      }
    });
  }

  int get _finishedCount {
    return _items
        .where(
          (item) =>
              item.status == BatchImportStatus.success ||
              item.status == BatchImportStatus.failed,
        )
        .length;
  }

  int get _successCount {
    return _items
        .where((item) => item.status == BatchImportStatus.success)
        .length;
  }

  bool get _isFinished {
    return _items.isEmpty || _finishedCount == _items.length;
  }

  Future<void> _processPendingItems() async {
    if (_isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    for (var index = 0; index < _items.length; index++) {
      if (!mounted) {
        return;
      }

      if (_items[index].status != BatchImportStatus.pending) {
        continue;
      }

      await _recognizeItem(index);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isProcessing = false;
    });
  }

  Future<void> _recognizeItem(int index) async {
    setState(() {
      _items[index] = _items[index].copyWith(
        status: BatchImportStatus.recognizing,
        clearDrafts: true,
        clearErrorMessage: true,
      );
    });

    try {
      final rawText = await _ocrService.recognizeText(_items[index].imagePath);
      final drafts = PickupParser.parseAll(rawText);

      if (!mounted) {
        return;
      }

      setState(() {
        _items[index] = _items[index].copyWith(
          status: BatchImportStatus.success,
          drafts: drafts,
          clearErrorMessage: true,
        );
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _items[index] = _items[index].copyWith(
          status: BatchImportStatus.failed,
          errorMessage: _friendlyErrorMessage(error),
          clearDrafts: true,
        );
      });
    }
  }

  Future<void> _retryItem(int index) async {
    if (_isProcessing) {
      return;
    }

    await _recognizeItem(index);
  }

  void _removeItem(int index) {
    if (_isProcessing) {
      return;
    }

    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _openBatchReview() async {
    final successfulItems = _items
        .where(
          (item) =>
              item.status == BatchImportStatus.success &&
              item.drafts.isNotEmpty,
        )
        .toList();

    final confirmedDrafts = await Navigator.of(context)
        .push<List<PickupCredentialDraft>>(
          MaterialPageRoute(
            builder: (context) => BatchReviewPage.withGroups(
              groups: successfulItems
                  .map(
                    (item) => PickupReviewGroup(
                      imagePath: item.imagePath,
                      drafts: item.drafts,
                    ),
                  )
                  .toList(),
            ),
          ),
        );

    if (!mounted || confirmedDrafts == null) {
      return;
    }

    Navigator.of(context).pop<List<PickupCredentialDraft>>(confirmedDrafts);
  }

  String _friendlyErrorMessage(Object error) {
    if (error is UnsupportedError) {
      return error.message ?? '当前平台暂不支持文字识别。';
    }

    if (error is PlatformException) {
      final message = error.message;
      if (message == null || message.trim().isEmpty) {
        return '文字识别失败：${error.code}';
      }

      return '文字识别失败：$message';
    }

    if (error is MissingPluginException) {
      return '文字识别功能未连接，请完全停止 App 后重新编译运行。';
    }

    return '文字识别失败：$error';
  }

  @override
  Widget build(BuildContext context) {
    final progressText = _isFinished
        ? '识别完成 $_finishedCount / ${_items.length}'
        : '正在识别 $_finishedCount / ${_items.length}';

    return Scaffold(
      appBar: AppBar(title: const Text('批量导入')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: double.infinity),
                  const Text(
                    '批量导入',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_items.length} 张截图',
                    key: const Key('batchImportCountText'),
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _items.isEmpty ? 0 : _finishedCount / _items.length,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    progressText,
                    key: const Key('batchImportProgressText'),
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _items.isEmpty
                  ? Center(
                      child: Text(
                        '暂无截图',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      itemCount: _items.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _BatchImportCard(
                          key: Key('batchImportItem_$index'),
                          item: _items[index],
                          index: index,
                          isProcessingBatch: _isProcessing,
                          onRetry: () => _retryItem(index),
                          onRemove: () => _removeItem(index),
                        );
                      },
                    ),
            ),
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: FilledButton(
                key: const Key('openBatchReviewButton'),
                onPressed: _isFinished && _successCount > 0
                    ? _openBatchReview
                    : null,
                child: const Text('核对取件信息'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BatchImportCard extends StatelessWidget {
  final BatchImportItem item;
  final int index;
  final bool isProcessingBatch;
  final VoidCallback onRetry;
  final VoidCallback onRemove;

  const _BatchImportCard({
    super.key,
    required this.item,
    required this.index,
    required this.isProcessingBatch,
    required this.onRetry,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ScreenshotThumbnail(imagePath: item.imagePath),
          const SizedBox(width: 12),
          Expanded(
            child: _BatchImportDetails(item: item, index: index),
          ),
          if (item.status == BatchImportStatus.failed ||
              item.status == BatchImportStatus.success)
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (item.status == BatchImportStatus.failed)
                  TextButton(
                    key: Key('retryBatchImportItem_$index'),
                    onPressed: isProcessingBatch ? null : onRetry,
                    child: const Text('重新识别'),
                  ),
                TextButton(
                  key: Key('removeBatchImportItem_$index'),
                  onPressed: isProcessingBatch ? null : onRemove,
                  child: const Text('移除'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ScreenshotThumbnail extends StatelessWidget {
  final String imagePath;

  const _ScreenshotThumbnail({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox.square(
        dimension: 64,
        child: ColoredBox(
          color: const Color(0xFFF3F4F6),
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
            cacheWidth: 240,
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.image_outlined, color: Colors.grey.shade500);
            },
          ),
        ),
      ),
    );
  }
}

class _BatchImportDetails extends StatelessWidget {
  final BatchImportItem item;
  final int index;

  const _BatchImportDetails({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final statusText = _statusText(item.status);
    final drafts = item.drafts;
    final isMultiDraft = drafts.length > 1;

    return Semantics(
      container: true,
      label: [
        '第 ${index + 1} 张截图',
        if (isMultiDraft) '识别出 ${drafts.length} 个取件凭证',
        for (final draft in drafts)
          '${_titleText(draft)}, 取件码 ${draft.pickupCode ?? '无取件码'}',
      ].join('，'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isMultiDraft
                ? '识别出 ${drafts.length} 个取件凭证'
                : _titleText(drafts.firstOrNull),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            statusText,
            key: Key('batchImportStatus_$index'),
            style: TextStyle(
              color: item.status == BatchImportStatus.failed
                  ? Theme.of(context).colorScheme.error
                  : Colors.grey.shade700,
            ),
          ),
          if (item.status == BatchImportStatus.success &&
              drafts.length == 1) ...[
            const SizedBox(height: 8),
            Text(drafts.single.pickupCode ?? '无取件码'),
            if (drafts.single.trackingNumber != null) ...[
              const SizedBox(height: 2),
              Text(
                drafts.single.trackingNumber!,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ],
          if (item.status == BatchImportStatus.success &&
              drafts.length > 1) ...[
            const SizedBox(height: 8),
            for (
              var draftIndex = 0;
              draftIndex < drafts.length;
              draftIndex++
            ) ...[
              if (draftIndex > 0) ...[
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
              ],
              _CredentialSummary(draft: drafts[draftIndex]),
            ],
          ],
          if (item.status == BatchImportStatus.failed &&
              item.errorMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              item.errorMessage!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _titleText(PickupCredentialDraft? draft) {
    if (item.status == BatchImportStatus.failed) {
      return '识别失败';
    }

    if (draft == null) {
      return '第 ${index + 1} 张';
    }

    if (draft.courierCompany == CourierCompany.unknown) {
      return '未识别快递公司';
    }

    return draft.courierCompany.displayName;
  }

  static String _statusText(BatchImportStatus status) {
    return switch (status) {
      BatchImportStatus.pending => '等待识别',
      BatchImportStatus.recognizing => '正在识别',
      BatchImportStatus.success => '识别成功',
      BatchImportStatus.failed => '识别失败',
    };
  }
}

class _CredentialSummary extends StatelessWidget {
  final PickupCredentialDraft draft;

  const _CredentialSummary({required this.draft});

  @override
  Widget build(BuildContext context) {
    final company = draft.courierCompany == CourierCompany.unknown
        ? '未识别快递公司'
        : draft.courierCompany.displayName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          company,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(draft.pickupCode ?? '无取件码'),
        if (draft.trackingNumber != null) ...[
          const SizedBox(height: 2),
          Text(draft.trackingNumber!, style: const TextStyle(fontSize: 13)),
        ],
      ],
    );
  }
}
