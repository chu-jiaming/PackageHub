import 'package:flutter/material.dart';
import 'package:packagehub/core/parser/pickup_parser.dart';
import 'package:packagehub/core/repository/pickup_credential_repository.dart';
import 'package:packagehub/design_system/components/ph_button.dart';
import 'package:packagehub/design_system/components/ph_navigation_header.dart';
import 'package:packagehub/design_system/components/ph_select_field.dart';
import 'package:packagehub/design_system/components/ph_text_field.dart';
import 'package:packagehub/models/pickup_credential.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';

class PickupCredentialEditPage extends StatefulWidget {
  final PickupCredential credential;
  final PickupCredentialRepositoryApi repository;

  const PickupCredentialEditPage({
    super.key,
    required this.credential,
    required this.repository,
  });

  @override
  State<PickupCredentialEditPage> createState() =>
      _PickupCredentialEditPageState();
}

class _PickupCredentialEditPageState extends State<PickupCredentialEditPage> {
  late CourierCompany _selectedCourierCompany;
  late PickupStatus _selectedStatus;
  late final TextEditingController _pickupCodeController;
  late final TextEditingController _trackingNumberController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedCourierCompany = widget.credential.courierCompany;
    _selectedStatus = widget.credential.status;
    _pickupCodeController = TextEditingController(
      text: widget.credential.pickupCode ?? '',
    );
    _trackingNumberController = TextEditingController(
      text: widget.credential.trackingNumber ?? '',
    );
  }

  @override
  void dispose() {
    _pickupCodeController.dispose();
    _trackingNumberController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final normalizedPickupCode = PickupParser.normalizePickupCode(
      _pickupCodeController.text,
    );
    final trackingNumber = _trackingNumberController.text.trim();
    final updatedCredential = widget.credential.copyWith(
      courierCompany: _selectedCourierCompany,
      pickupCode: normalizedPickupCode.isEmpty ? null : normalizedPickupCode,
      trackingNumber: trackingNumber.isEmpty ? null : trackingNumber,
      status: _selectedStatus,
    );

    try {
      final saved = await widget.repository.update(updatedCredential);
      if (mounted) {
        Navigator.of(context).pop<PickupCredential>(saved);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('无法保存修改')));
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PHNavigationHeader(
        title: '编辑取件凭证',
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            PHSelectField<CourierCompany>(
              key: const Key('editCourierCompanyField'),
              value: _selectedCourierCompany,
              items: CourierCompany.values.map((company) {
                return DropdownMenuItem(
                  value: company,
                  child: Text(company.displayName),
                );
              }).toList(),
              onChanged: _isSaving
                  ? null
                  : (company) {
                      if (company == null) {
                        return;
                      }
                      setState(() {
                        _selectedCourierCompany = company;
                      });
                    },
              label: '快递公司',
            ),
            const SizedBox(height: 16),
            PHTextField(
              fieldKey: const Key('editPickupCodeField'),
              controller: _pickupCodeController,
              enabled: !_isSaving,
              textInputAction: TextInputAction.next,
              label: '取件码',
            ),
            const SizedBox(height: 16),
            PHTextField(
              fieldKey: const Key('editTrackingNumberField'),
              controller: _trackingNumberController,
              enabled: !_isSaving,
              textInputAction: TextInputAction.next,
              label: '运单号',
            ),
            const SizedBox(height: 16),
            PHSelectField<PickupStatus>(
              key: const Key('editStatusField'),
              value: _selectedStatus,
              items: PickupStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status.displayName),
                );
              }).toList(),
              onChanged: _isSaving
                  ? null
                  : (status) {
                      if (status == null) {
                        return;
                      }
                      setState(() {
                        _selectedStatus = status;
                      });
                    },
              label: '状态',
            ),
            const SizedBox(height: 24),
            PHButton(
              key: const Key('saveCredentialEditButton'),
              onPressed: _isSaving ? null : _save,
              label: _isSaving ? '保存中...' : '保存',
            ),
          ],
        ),
      ),
    );
  }
}
