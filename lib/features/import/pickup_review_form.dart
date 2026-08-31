import 'package:flutter/material.dart';
import 'package:packagehub/core/parser/pickup_parser.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';

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
