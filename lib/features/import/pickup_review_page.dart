import 'dart:io';

import 'package:flutter/material.dart';
import 'package:packagehub/features/import/pickup_review_form.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';

class PickupReviewPage extends StatefulWidget {
  final PickupCredentialDraft originalDraft;
  final String? imagePath;

  const PickupReviewPage({
    super.key,
    required this.originalDraft,
    this.imagePath,
  });

  @override
  State<PickupReviewPage> createState() => _PickupReviewPageState();
}

class _PickupReviewPageState extends State<PickupReviewPage> {
  late PickupCredentialDraft _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.originalDraft;
  }

  void _confirm() {
    Navigator.of(context).pop(_draft);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('确认取件信息')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const Text(
              '确认取件信息',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '自动识别结果可能有误，请核对后继续。',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            ),
            if (widget.imagePath != null) ...[
              const SizedBox(height: 18),
              _ScreenshotPreview(imagePath: widget.imagePath!),
            ],
            const SizedBox(height: 22),
            PickupReviewForm(
              draft: _draft,
              onChanged: (draft) => _draft = draft,
              onComplete: _confirm,
              completeButtonLabel: '确认信息',
              completeButtonKey: const Key('confirmPickupButton'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScreenshotPreview extends StatelessWidget {
  final String imagePath;

  const _ScreenshotPreview({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 150,
        width: double.infinity,
        child: ColoredBox(
          color: Colors.black,
          child: Image.file(File(imagePath), fit: BoxFit.contain),
        ),
      ),
    );
  }
}
