import 'package:flutter/material.dart';
import 'package:packagehub/core/parser/pickup_parser.dart';
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
        DropdownButtonFormField<CourierCompany>(
          key: const Key('courierCompanyField'),
          initialValue: _selectedCourierCompany,
          decoration: InputDecoration(
            labelText: '快递公司',
            filled: true,
            border: InputBorder.none,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          items: CourierCompany.values.map((company) {
            return DropdownMenuItem(
              value: company,
              child: Text(company.displayName),
            );
          }).toList(),
          onChanged: _updateCourierCompany,
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: const Key('pickupCodeField'),
          controller: _pickupCodeController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: '取件码',
            filled: true,
            border: InputBorder.none,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: const Key('trackingNumberField'),
          controller: _trackingNumberController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: '运单号',
            filled: true,
            border: InputBorder.none,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<PickupStatus>(
          key: const Key('statusField'),
          initialValue: _selectedStatus,
          decoration: InputDecoration(
            labelText: '状态',
            filled: true,
            border: InputBorder.none,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          items: PickupStatus.values.map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(status.displayName),
            );
          }).toList(),
          onChanged: _updateStatus,
        ),
        const SizedBox(height: 12),
        Text(
          '识别来源：${widget.draft.sourcePlatform.displayName}',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        ..._evidenceLabels(),
        ..._conflictLabels(),
        const SizedBox(height: 2),
        _RawTextTile(text: widget.draft.rawText),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: widget.completeButtonKey,
            onPressed: _complete,
            child: Text(widget.completeButtonLabel),
          ),
        ),
      ],
    );
  }

  List<Widget> _evidenceLabels() {
    final labels = <Widget>[];
    for (final field in RecognitionField.values) {
      final item = widget.draft.evidence
          .where((e) => e.field == field)
          .firstOrNull;
      if (item == null) continue;
      labels.add(
        Text(
          '${_fieldName(field)}：${_evidenceLabel(item)}',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
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
    return [
      for (final conflict in widget.draft.conflicts) ...[
        const SizedBox(height: 8),
        Text(
          '检测到多个可能结果，请确认',
          style: TextStyle(fontSize: 13, color: Colors.orange.shade800),
        ),
        for (final alternative in conflict.alternatives)
          Text(
            '${_fieldName(conflict.field)}：${_displayValue(alternative.value)}',
            style: TextStyle(fontSize: 13, color: Colors.orange.shade800),
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
    return Material(
      color: Colors.transparent,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          initiallyExpanded: false,
          title: const Text(
            '查看原始识别文本',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          children: [
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 180),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(8),
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
