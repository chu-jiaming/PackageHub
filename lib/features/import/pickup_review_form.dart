import 'package:flutter/material.dart';
import 'package:packagehub/core/parser/pickup_parser.dart';
import 'package:packagehub/design_system/components/ph_banner.dart';
import 'package:packagehub/design_system/components/ph_button.dart';
import 'package:packagehub/design_system/components/ph_select_field.dart';
import 'package:packagehub/design_system/components/ph_text_field.dart';
import 'package:packagehub/design_system/tokens/ph_color_scheme.dart';
import 'package:packagehub/design_system/tokens/ph_radius.dart';
import 'package:packagehub/design_system/tokens/ph_spacing.dart';
import 'package:packagehub/design_system/tokens/ph_typography.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';
import 'package:packagehub/recognition/recognition_evidence.dart';

class PickupReviewForm extends StatefulWidget {
  final PickupCredentialDraft draft;
  final ValueChanged<PickupCredentialDraft> onChanged;
  final VoidCallback onComplete;
  final String completeButtonLabel;
  final Key completeButtonKey;

  const PickupReviewForm({
    super.key,
    required this.draft,
    required this.onChanged,
    required this.onComplete,
    this.completeButtonLabel = '完成编辑',
    this.completeButtonKey = const Key('completeReviewEditButton'),
  });

  @override
  State<PickupReviewForm> createState() => _PickupReviewFormState();
}

class _PickupReviewFormState extends State<PickupReviewForm> {
  late CourierCompany _selectedCourierCompany;
  late PickupStatus _selectedStatus;
  late final TextEditingController _pickupCodeController;
  late final TextEditingController _trackingNumberController;

  @override
  void initState() {
    super.initState();
    _selectedCourierCompany = widget.draft.courierCompany;
    _selectedStatus = widget.draft.status;
    _pickupCodeController = TextEditingController(
      text: widget.draft.pickupCode ?? '',
    );
    _trackingNumberController = TextEditingController(
      text: widget.draft.trackingNumber ?? '',
    );

    _pickupCodeController.addListener(_emitDraft);
    _trackingNumberController.addListener(_emitDraft);
  }

  @override
  void dispose() {
    _pickupCodeController.dispose();
    _trackingNumberController.dispose();
    super.dispose();
  }

  PickupCredentialDraft _currentDraft() {
    final normalizedPickupCode = PickupParser.normalizePickupCode(
      _pickupCodeController.text,
    );
    final normalizedTrackingNumber = _trackingNumberController.text.trim();

    final changedFields = <RecognitionField>{};
    if ((widget.draft.pickupCode ?? '') !=
        (normalizedPickupCode.isEmpty ? '' : normalizedPickupCode)) {
      changedFields.add(RecognitionField.pickupCode);
    }
    if ((widget.draft.trackingNumber ?? '') !=
        (normalizedTrackingNumber.isEmpty ? '' : normalizedTrackingNumber)) {
      changedFields.add(RecognitionField.trackingNumber);
    }
    if (_selectedCourierCompany != widget.draft.courierCompany) {
      changedFields.add(RecognitionField.courierCompany);
    }
    return PickupCredentialDraft(
      courierCompany: _selectedCourierCompany,
      trackingNumber: normalizedTrackingNumber.isEmpty
          ? null
          : normalizedTrackingNumber,
      pickupCode: normalizedPickupCode.isEmpty ? null : normalizedPickupCode,
      stationName: widget.draft.stationName,
      status: _selectedStatus,
      sourcePlatform: widget.draft.sourcePlatform,
      rawText: widget.draft.rawText,
      evidence: widget.draft.evidence
          .where((e) => !changedFields.contains(e.field))
          .toList(),
      conflicts: widget.draft.conflicts
          .where((conflict) => !changedFields.contains(conflict.field))
          .toList(),
    );
  }

  void _emitDraft() {
    widget.onChanged(_currentDraft());
  }

  void _updateCourierCompany(CourierCompany? company) {
    if (company == null) {
      return;
    }

    setState(() {
      _selectedCourierCompany = company;
    });
    _emitDraft();
  }

  void _updateStatus(PickupStatus? status) {
    if (status == null) {
      return;
    }

    setState(() {
      _selectedStatus = status;
    });
    _emitDraft();
  }

  void _complete() {
    _emitDraft();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PHSelectField<CourierCompany>(
          key: const Key('courierCompanyField'),
          value: _selectedCourierCompany,
          items: CourierCompany.values.map((company) {
            return DropdownMenuItem(
              value: company,
              child: Text(company.displayName),
            );
          }).toList(),
          onChanged: _updateCourierCompany,
          label: '快递公司',
        ),
        const SizedBox(height: PHSpacing.md),
        PHTextField(
          fieldKey: const Key('pickupCodeField'),
          controller: _pickupCodeController,
          textInputAction: TextInputAction.next,
          label: '取件码',
        ),
        const SizedBox(height: PHSpacing.md),
        PHTextField(
          fieldKey: const Key('trackingNumberField'),
          controller: _trackingNumberController,
          textInputAction: TextInputAction.next,
          label: '运单号',
        ),
        const SizedBox(height: PHSpacing.md),
        PHSelectField<PickupStatus>(
          key: const Key('statusField'),
          value: _selectedStatus,
          items: PickupStatus.values.map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(status.displayName),
            );
          }).toList(),
          onChanged: _updateStatus,
          label: '状态',
        ),
        const SizedBox(height: PHSpacing.sm),
        Text(
          '识别来源：${widget.draft.sourcePlatform.displayName}',
          style: PHTypography.footnote.copyWith(
            color: PHColorScheme.of(context).textSecondary,
          ),
        ),
        ..._evidenceLabels(),
        ..._conflictLabels(),
        const SizedBox(height: PHSpacing.xxs),
        _RawTextTile(text: widget.draft.rawText),
        const SizedBox(height: PHSpacing.lg),
        PHButton(
          key: widget.completeButtonKey,
          onPressed: _complete,
          label: widget.completeButtonLabel,
        ),
      ],
    );
  }

  List<Widget> _evidenceLabels() {
    final labels = <Widget>[];
    final colors = PHColorScheme.of(context);
    for (final field in RecognitionField.values) {
      final item = widget.draft.evidence
          .where((e) => e.field == field)
          .firstOrNull;
      if (item == null) continue;
      labels.add(
        Text(
          '${_fieldName(field)}：${_evidenceLabel(item)}',
          style: PHTypography.footnote.copyWith(color: colors.textSecondary),
        ),
      );
    }
    return labels;
  }

  String _evidenceLabel(RecognitionEvidence evidence) {
    if (evidence.kind == RecognitionEvidenceKind.direct) return '来自原文';
    return evidence.source == RecognitionEvidenceSource.trackingPrefixRule
        ? '根据运单号规则推断'
        : '根据站点规则推断';
  }

  List<Widget> _conflictLabels() {
    final colors = PHColorScheme.of(context);
    return [
      for (final conflict in widget.draft.conflicts) ...[
        const SizedBox(height: PHSpacing.sm),
        const PHBanner(
          variant: PHBannerVariant.warning,
          title: '检测到多个可能结果，请确认',
        ),
        for (final alternative in conflict.alternatives)
          Text(
            '${_fieldName(conflict.field)}：${_displayValue(alternative.value)}',
            style: PHTypography.footnote.copyWith(color: colors.textWarning),
          ),
      ],
    ];
  }

  String _displayValue(Object value) => switch (value) {
    CourierCompany company => company.displayName,
    _ => value.toString(),
  };

  String _fieldName(RecognitionField field) => switch (field) {
    RecognitionField.pickupCode => '取件码',
    RecognitionField.courierCompany => '快递公司',
    RecognitionField.trackingNumber => '运单号',
  };
}

class _RawTextTile extends StatelessWidget {
  final String text;

  const _RawTextTile({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = PHColorScheme.of(context);
    return Material(
      color: Colors.transparent,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: colors.separatorDefault),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          initiallyExpanded: false,
          title: const Text(
            '查看原始识别文本',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          children: [
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 180),
              padding: const EdgeInsets.all(PHSpacing.md),
              decoration: BoxDecoration(
                color: colors.bgSurfaceSecondary,
                borderRadius: BorderRadius.circular(PHRadius.sm),
                border: Border.all(color: colors.borderDefault),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  text,
                  style: PHTypography.body.copyWith(
                    color: colors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
