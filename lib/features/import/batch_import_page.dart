import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:packagehub/core/ocr/ocr_service.dart';
import 'package:packagehub/core/parser/pickup_parser.dart';
import 'package:packagehub/design_system/components/ph_bottom_action_bar.dart';
import 'package:packagehub/design_system/components/ph_button.dart';
import 'package:packagehub/design_system/components/ph_empty_state.dart';
import 'package:packagehub/design_system/components/ph_import_status_card.dart';
import 'package:packagehub/design_system/components/ph_navigation_header.dart';
import 'package:packagehub/design_system/components/ph_section_header.dart';
import 'package:packagehub/design_system/tokens/ph_color_scheme.dart';
import 'package:packagehub/design_system/tokens/ph_radius.dart';
import 'package:packagehub/design_system/tokens/ph_spacing.dart';
import 'package:packagehub/design_system/tokens/ph_typography.dart';
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
      appBar: PHNavigationHeader(
        title: '批量导入',
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: PHSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PHSectionHeader(title: '批量导入'),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: PHSpacing.md,
                    ),
                    child: Text(
                      '${_items.length} 张截图',
                      key: const Key('batchImportCountText'),
                      style: PHTypography.subheadline.copyWith(
                        color: PHColorScheme.of(context).textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: PHSpacing.sm),
                  LinearProgressIndicator(
                    value: _items.isEmpty ? 0 : _finishedCount / _items.length,
                    color: PHColorScheme.of(context).iconAccent,
                    backgroundColor: PHColorScheme.of(context).bgDisabled,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      PHSpacing.md,
                      PHSpacing.xs,
                      PHSpacing.md,
                      0,
                    ),
                    child: Text(
                      progressText,
                      key: const Key('batchImportProgressText'),
                      style: PHTypography.footnote.copyWith(
                        color: PHColorScheme.of(context).textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _items.isEmpty
                  ? const PHEmptyState(title: '暂无截图')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        PHSpacing.md,
                        PHSpacing.xs,
                        PHSpacing.md,
                        PHSpacing.md,
                      ),
                      itemCount: _items.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: PHSpacing.sm),
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
            PHBottomActionBar(
              actions: [
                PHButton(
                  key: const Key('openBatchReviewButton'),
                  onPressed: _isFinished && _successCount > 0
                      ? _openBatchReview
                      : null,
                  label: '核对取件信息',
                ),
              ],
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
    final status = switch (item.status) {
      BatchImportStatus.pending => PHImportStatus.waiting,
      BatchImportStatus.recognizing => PHImportStatus.recognizing,
      BatchImportStatus.success => PHImportStatus.success,
      BatchImportStatus.failed => PHImportStatus.failed,
    };
    final statusText = _BatchImportDetails.statusText(item.status);
    return PHImportStatusCard(
      status: status,
      title: _BatchImportDetails.titleText(item, index),
      message: item.errorMessage == null
          ? statusText
          : '$statusText：${item.errorMessage}',
      preview: _ScreenshotThumbnail(imagePath: item.imagePath),
      details: _BatchImportDetails(item: item, index: index),
      trailing:
          item.status == BatchImportStatus.failed ||
              item.status == BatchImportStatus.success
          ? Column(
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
            )
          : null,
    );
  }
}

class _ScreenshotThumbnail extends StatelessWidget {
  final String imagePath;

  const _ScreenshotThumbnail({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final colors = PHColorScheme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(PHRadius.sm),
      child: SizedBox.square(
        dimension: 64,
        child: ColoredBox(
          color: colors.bgSurfaceSecondary,
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
            cacheWidth: 240,
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.image_outlined, color: colors.iconSecondary);
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
    final drafts = item.drafts;
    final isMultiDraft = drafts.length > 1;
    final colors = PHColorScheme.of(context);

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
          if (item.status == BatchImportStatus.success &&
              drafts.length == 1) ...[
            const SizedBox(height: 8),
            Text(drafts.single.pickupCode ?? '无取件码'),
            if (drafts.single.trackingNumber != null) ...[
              const SizedBox(height: 2),
              Text(
                drafts.single.trackingNumber!,
                style: PHTypography.footnote.copyWith(
                  color: colors.textSecondary,
                ),
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
                Divider(height: 1, color: colors.separatorDefault),
                const SizedBox(height: 8),
              ],
              _CredentialSummary(draft: drafts[draftIndex]),
            ],
          ],
        ],
      ),
    );
  }

  static String titleText(BatchImportItem item, int index) {
    final draft = item.drafts.firstOrNull;
    if (item.status == BatchImportStatus.failed) {
      return '识别失败';
    }

    if (item.drafts.length > 1) {
      return '识别出 ${item.drafts.length} 个取件凭证';
    }

    if (draft == null) {
      return '第 ${index + 1} 张';
    }

    if (draft.courierCompany == CourierCompany.unknown) {
      return '未识别快递公司';
    }

    return draft.courierCompany.displayName;
  }

  static String _titleText(PickupCredentialDraft? draft) {
    if (draft == null) {
      return '未识别';
    }

    if (draft.courierCompany == CourierCompany.unknown) {
      return '未识别快递公司';
    }

    return draft.courierCompany.displayName;
  }

  static String statusText(BatchImportStatus status) {
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
    final colors = PHColorScheme.of(context);
    final company = draft.courierCompany == CourierCompany.unknown
        ? '未识别快递公司'
        : draft.courierCompany.displayName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          company,
          style: PHTypography.bodyEmphasis.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          draft.pickupCode ?? '无取件码',
          style: PHTypography.subheadline.copyWith(color: colors.textPrimary),
        ),
        if (draft.trackingNumber != null) ...[
          const SizedBox(height: 2),
          Text(
            draft.trackingNumber!,
            style: PHTypography.footnote.copyWith(color: colors.textSecondary),
          ),
        ],
      ],
    );
  }
}
