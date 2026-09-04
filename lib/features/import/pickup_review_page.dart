import 'dart:io';

import 'package:flutter/material.dart';
import 'package:packagehub/design_system/components/ph_banner.dart';
import 'package:packagehub/design_system/components/ph_navigation_header.dart';
import 'package:packagehub/design_system/components/ph_section_header.dart';
import 'package:packagehub/design_system/tokens/ph_color_scheme.dart';
import 'package:packagehub/design_system/tokens/ph_radius.dart';
import 'package:packagehub/design_system/tokens/ph_spacing.dart';
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
      appBar: PHNavigationHeader(
        title: '确认取件信息',
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            PHSpacing.md,
            PHSpacing.xs,
            PHSpacing.md,
            PHSpacing.lg,
          ),
          children: [
            const PHSectionHeader(title: '确认取件信息'),
            const PHBanner(
              variant: PHBannerVariant.info,
              title: '自动识别结果可能有误，请核对后继续。',
            ),
            if (widget.imagePath != null) ...[
              const SizedBox(height: PHSpacing.md),
              _ScreenshotPreview(imagePath: widget.imagePath!),
            ],
            const SizedBox(height: PHSpacing.lg),
            PickupReviewForm(
              draft: _draft,
              onChanged: (draft) => setState(() => _draft = draft),
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
    final colors = PHColorScheme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(PHRadius.sm),
      child: SizedBox(
        height: 150,
        width: double.infinity,
        child: ColoredBox(
          color: colors.bgCanvas,
          child: Image.file(File(imagePath), fit: BoxFit.contain),
        ),
      ),
    );
  }
}
