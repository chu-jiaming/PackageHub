import 'package:flutter/material.dart';
import 'package:packagehub/core/repository/pickup_credential_repository.dart';
import 'package:packagehub/models/pickup_reminder_settings.dart';
import 'package:packagehub/core/reminder/pickup_notification_service.dart';

class PickupReminderSettingsPage extends StatefulWidget {
  final PickupCredentialRepository repository;
  const PickupReminderSettingsPage({super.key, required this.repository});

  @override
  State<PickupReminderSettingsPage> createState() => _PickupReminderSettingsPageState();
}

class _PickupReminderSettingsPageState extends State<PickupReminderSettingsPage> {
  PickupReminderSettings _settings = const PickupReminderSettings();
  final _daysController = TextEditingController(text: '3');
  bool _loading = true;
  final _notificationService = PickupNotificationService();

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final settings = await widget.repository.getReminderSettings();
    if (!mounted) return;
    setState(() { _settings = settings; _daysController.text = '${settings.days}'; _loading = false; });
  }
  Future<void> _save({bool? enabled, int? days}) async {
    final next = _settings.copyWith(enabled: enabled, days: days);
    setState(() => _settings = next);
    await widget.repository.saveReminderSettings(next);
    await _notificationService.sync(await widget.repository.getAll(), settings: next);
  }
  @override
  void dispose() { _daysController.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('取件提醒')),
    body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SwitchListTile.adaptive(
          key: const Key('pickupReminderEnabledSwitch'),
          contentPadding: EdgeInsets.zero,
          title: const Text('启用取件提醒'),
          subtitle: const Text('待取件超过指定天数后，在首页提示'),
          value: _settings.enabled,
          onChanged: (value) => _save(enabled: value),
        ),
        const SizedBox(height: 20),
        TextField(
          key: const Key('pickupReminderDaysField'),
          controller: _daysController,
          enabled: _settings.enabled,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: '提醒天数', suffixText: '天', border: OutlineInputBorder()),
          onSubmitted: (value) => _save(days: int.tryParse(value)?.clamp(1, 30) ?? 3),
        ),
        const SizedBox(height: 8),
        Text('可设置 1～30 天。修改后按回车保存。', style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}
