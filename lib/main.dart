import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:packagehub/core/ocr/ocr_service.dart';
import 'package:packagehub/core/parser/pickup_parser.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';

void main() {
  runApp(const PackageHubApp());
}

class PackageHubApp extends StatelessWidget {
  const PackageHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PackageHub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _pickScreenshot(BuildContext context) async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (image == null) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ImportPreviewPage(imagePath: image.path),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'PackageHub',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            const Text(
              '待取件',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              '2 个包裹等待领取',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),

            const PickupCard(
              platform: '淘宝',
              pickupCode: '6-2-8-1',
              station: '菜鸟驿站 · XX小区店',
              timeText: '今天 10:32',
              icon: Icons.local_shipping_outlined,
            ),

            const SizedBox(height: 16),

            const PickupCard(
              platform: '拼多多',
              pickupCode: '3-5-2-7',
              station: '丰巢智能柜 · 1号楼',
              timeText: '昨天 18:05',
              icon: Icons.inventory_2_outlined,
            ),

            const SizedBox(height: 32),

            Text(
              '已取件',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '暂无已取件包裹',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _pickScreenshot(context),
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('添加截图'),
      ),
    );
  }
}

class ImportPreviewPage extends StatefulWidget {
  final String imagePath;

  const ImportPreviewPage({super.key, required this.imagePath});

  @override
  State<ImportPreviewPage> createState() => _ImportPreviewPageState();
}

class _ImportPreviewPageState extends State<ImportPreviewPage> {
  final OcrService _ocrService = const OcrService();

  bool _isRecognizing = false;
  String? _recognizedText;
  PickupCredentialDraft? _parsedDraft;
  String? _errorMessage;

  Future<void> _recognizeText() async {
    if (_isRecognizing) {
      return;
    }

    setState(() {
      _isRecognizing = true;
      _recognizedText = null;
      _parsedDraft = null;
      _errorMessage = null;
    });

    try {
      final text = await _ocrService.recognizeText(widget.imagePath);
      final parsedDraft = PickupParser.parse(text);

      if (!mounted) {
        return;
      }

      setState(() {
        _recognizedText = text.trim().isEmpty ? '未识别到文字' : text;
        _parsedDraft = parsedDraft;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = _friendlyErrorMessage(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRecognizing = false;
        });
      }
    }
  }

  String _friendlyErrorMessage(Object error) {
    if (error is UnsupportedError) {
      return error.message ?? '当前平台暂不支持 OCR。';
    }

    if (error is PlatformException) {
      final message = error.message;
      if (message == null || message.trim().isEmpty) {
        return 'OCR 识别失败：${error.code}';
      }

      return 'OCR 识别失败：$message';
    }

    if (error is MissingPluginException) {
      return 'OCR 通道未连接，请完全停止 App 后重新编译运行。';
    }

    return 'OCR 识别失败：$error';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('导入截图')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ColoredBox(
                color: Colors.black,
                child: Center(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Image.file(
                      File(widget.imagePath),
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isRecognizing ? null : _recognizeText,
                      child: _isRecognizing
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text('识别中...'),
                              ],
                            )
                          : const Text('识别取件信息'),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  if (_recognizedText != null) ...[
                    const SizedBox(height: 18),
                    _ParsedResultView(draft: _parsedDraft!),
                    const SizedBox(height: 12),
                    _RawOcrTextTile(text: _recognizedText!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RawOcrTextTile extends StatelessWidget {
  final String text;

  const _RawOcrTextTile({required this.text});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          initiallyExpanded: false,
          title: const Text(
            '原始 OCR 文本',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          children: [
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 180),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  text,
                  style: const TextStyle(height: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParsedResultView extends StatelessWidget {
  final PickupCredentialDraft draft;

  const _ParsedResultView({required this.draft});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '解析结果',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _ParsedResultRow(label: '平台', value: draft.platform.displayName),
          _ParsedResultRow(label: '取件码', value: draft.pickupCode ?? '未识别'),
          _ParsedResultRow(label: '取件点', value: draft.stationName ?? '未识别'),
          _ParsedResultRow(label: '状态', value: draft.status.displayName),
        ],
      ),
    );
  }
}

class _ParsedResultRow extends StatelessWidget {
  final String label;
  final String value;

  const _ParsedResultRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              '$label：',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class PickupCard extends StatelessWidget {
  final String platform;
  final String pickupCode;
  final String station;
  final String timeText;
  final IconData icon;

  const PickupCard({
    super.key,
    required this.platform,
    required this.pickupCode,
    required this.station,
    required this.timeText,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  platform,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                timeText,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),

          const SizedBox(height: 28),

          Text(
            '取件码',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),

          const SizedBox(height: 8),

          Text(
            pickupCode,
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              letterSpacing: 5,
            ),
          ),

          const SizedBox(height: 26),

          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 18,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  station,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              child: Text('在$platform中查看'),
            ),
          ),
        ],
      ),
    );
  }
}
