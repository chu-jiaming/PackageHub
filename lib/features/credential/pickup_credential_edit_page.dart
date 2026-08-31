import 'package:flutter/material.dart';
import 'package:packagehub/core/parser/pickup_parser.dart';
import 'package:packagehub/core/repository/pickup_credential_repository.dart';
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
      appBar: AppBar(title: const Text('编辑取件凭证')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            DropdownButtonFormField<CourierCompany>(
              key: const Key('editCourierCompanyField'),
              initialValue: _selectedCourierCompany,
              decoration: InputDecoration(
                labelText: '快递公司',
                filled: true,
                border: InputBorder.none,
                fillColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
              ),
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
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('editPickupCodeField'),
              controller: _pickupCodeController,
              enabled: !_isSaving,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: '取件码',
                filled: true,
                border: InputBorder.none,
                fillColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('editTrackingNumberField'),
              controller: _trackingNumberController,
              enabled: !_isSaving,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: '运单号',
                filled: true,
                border: InputBorder.none,
                fillColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PickupStatus>(
              key: const Key('editStatusField'),
              initialValue: _selectedStatus,
              decoration: InputDecoration(
                labelText: '状态',
                filled: true,
                border: InputBorder.none,
                fillColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
              ),
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
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('saveCredentialEditButton'),
              onPressed: _isSaving ? null : _save,
              child: Text(_isSaving ? '保存中...' : '保存'),
            ),
          ],
        ),
      ),
    );
  }
}
