import 'package:flutter/material.dart';
import 'package:packagehub/core/repository/pickup_credential_repository.dart';
import 'package:packagehub/features/credential/pickup_credential_edit_page.dart';
import 'package:packagehub/models/pickup_credential.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';

class PickupCredentialDetailPage extends StatefulWidget {
  final PickupCredential credential;
  final PickupCredentialRepositoryApi repository;

  const PickupCredentialDetailPage({
    super.key,
    required this.credential,
    required this.repository,
  });

  @override
  State<PickupCredentialDetailPage> createState() =>
      _PickupCredentialDetailPageState();
}

class _PickupCredentialDetailPageState
    extends State<PickupCredentialDetailPage> {
  late PickupCredential _credential;
  bool _hasChanged = false;
  bool _isUpdating = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _credential = widget.credential;
  }

  void _close() {
    Navigator.of(context).pop<bool>(_hasChanged);
  }

  Future<void> _openEditPage() async {
    final updated = await Navigator.of(context).push<PickupCredential>(
      MaterialPageRoute(
        builder: (context) => PickupCredentialEditPage(
          credential: _credential,
          repository: widget.repository,
        ),
      ),
    );

    if (!mounted || updated == null) {
      return;
    }

    setState(() {
      _credential = updated;
      _hasChanged = true;
    });
  }

  Future<void> _markPickedUp() async {
    await _runLifecycleAction(
      () => widget.repository.markPickedUp(_requireCredentialId()),
      successMessage: '已标记为已取件',
    );
  }

  Future<void> _markPending() async {
    await _runLifecycleAction(
      () => widget.repository.markPending(_requireCredentialId()),
      successMessage: '已恢复为待取件',
    );
  }

  Future<void> _runLifecycleAction(
    Future<PickupCredential> Function() action, {
    required String successMessage,
  }) async {
    if (_isUpdating) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final updated = await action();
      if (mounted) {
        setState(() {
          _credential = updated;
          _hasChanged = true;
          _isUpdating = false;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('无法更新取件状态')));
      }
    }
  }

  int _requireCredentialId() {
    final id = _credential.id;
    if (id == null) {
      throw StateError('Cannot update a pickup credential without an id.');
    }
    return id;
  }

  Future<void> _confirmDelete() async {
    if (_isDeleting) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除取件凭证？'),
          content: const Text('删除后无法恢复。'),
          actions: [
            TextButton(
              key: const Key('cancelDeleteCredentialButton'),
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              key: const Key('confirmDeleteCredentialButton'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _delete();
    }
  }

  Future<void> _delete() async {
    if (_isDeleting) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await widget.repository.deleteById(_requireCredentialId());
      if (mounted) {
        Navigator.of(context).pop<bool>(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('无法删除取件凭证')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('credentialDetailBackButton'),
          icon: const Icon(Icons.arrow_back),
          onPressed: _close,
          tooltip: '返回',
        ),
        title: const Text('取件凭证详情'),
        actions: [
          TextButton(
            key: const Key('editCredentialButton'),
            onPressed: _isUpdating || _isDeleting ? null : _openEditPage,
            child: const Text('编辑'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _DetailRow(
              label: '快递公司',
              value: _credential.courierCompany.displayName,
            ),
            _DetailRow(label: '取件码', value: _credential.pickupCode ?? '未填写'),
            _DetailRow(
              label: '运单号',
              value: _credential.trackingNumber ?? '未填写',
            ),
            _DetailRow(label: '状态', value: _credential.status.displayName),
            _DetailRow(
              label: '来源平台',
              value: _credential.sourcePlatform.displayName,
              subdued: true,
            ),
            const SizedBox(height: 24),
            if (_credential.status == PickupStatus.pending)
              FilledButton(
                key: const Key('detailMarkPickedUpButton'),
                onPressed: _isUpdating || _isDeleting ? null : _markPickedUp,
                child: Text(_isUpdating ? '更新中...' : '标记已取件'),
              )
            else if (_credential.status == PickupStatus.pickedUp)
              FilledButton.tonal(
                key: const Key('detailMarkPendingButton'),
                onPressed: _isUpdating || _isDeleting ? null : _markPending,
                child: Text(_isUpdating ? '更新中...' : '恢复待取件'),
              ),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('deleteCredentialButton'),
              onPressed: _isUpdating || _isDeleting ? null : _confirmDelete,
              child: Text(_isDeleting ? '删除中...' : '删除凭证'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool subdued;

  const _DetailRow({
    required this.label,
    required this.value,
    this.subdued = false,
  });

  @override
  Widget build(BuildContext context) {
    final valueStyle = TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: subdued ? Colors.grey.shade600 : null,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 6),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}
