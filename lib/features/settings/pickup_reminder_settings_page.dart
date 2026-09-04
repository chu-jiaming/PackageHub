import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:packagehub/core/repository/pickup_credential_repository.dart';
import 'package:packagehub/models/pickup_reminder_settings.dart';
import 'package:packagehub/core/reminder/pickup_notification_service.dart';
import 'package:packagehub/design_system/components/ph_navigation_header.dart';
import 'package:packagehub/design_system/components/ph_text_field.dart';

class PickupReminderSettingsPage extends StatefulWidget {
  final PickupReminderSettingsRepository repository;
  final PickupNotificationService? notificationService;

  const PickupReminderSettingsPage({
    super.key,
    required this.repository,
    this.notificationService,
  });

  @override
  State<PickupReminderSettingsPage> createState() =>
      _PickupReminderSettingsPageState();
}

class _PickupReminderSettingsPageState
    extends State<PickupReminderSettingsPage> {
  PickupReminderSettings _settings = const PickupReminderSettings();
  final _daysController = TextEditingController(text: '3');
  late final FocusNode _reminderDaysFocusNode;
  bool _loading = true;
  late final PickupNotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _reminderDaysFocusNode = FocusNode();
    _notificationService =
        widget.notificationService ?? PickupNotificationService();
    _load();
  }

  Future<void> _load() async {
    final settings = await widget.repository.getReminderSettings();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _daysController.text = '${settings.days}';
      _loading = false;
    });
  }

  Future<void> _save({bool? enabled, int? days}) async {
    final next = _settings.copyWith(enabled: enabled, days: days);
    setState(() => _settings = next);
    await widget.repository.saveReminderSettings(next);
    await _notificationService.sync(
      await widget.repository.getAll(),
      settings: next,
    );
  }

  Future<void> _submitDays() {
    _reminderDaysFocusNode.unfocus();
    return _save(days: int.tryParse(_daysController.text)?.clamp(1, 30) ?? 3);
  }

  @override
  void dispose() {
    _reminderDaysFocusNode.dispose();
    _daysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: PHNavigationHeader(
      title: '取件提醒',
      leading: IconButton(
        tooltip: '返回',
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back),
      ),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : KeyboardActions(
            enabled: defaultTargetPlatform == TargetPlatform.iOS,
            navigation: KeyboardNavigation.none,
            doneText: '完成',
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                KeyboardField(
                  focusNode: _reminderDaysFocusNode,
                  toolbarButtons: [
                    (node) => CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      onPressed: () => unawaited(_submitDays()),
                      child: const Text('完成'),
                    ),
                  ],
                  child: PHTextField(
                    fieldKey: const Key('pickupReminderDaysField'),
                    controller: _daysController,
                    focusNode: _reminderDaysFocusNode,
                    enabled: _settings.enabled,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onTapOutside: (_) => _reminderDaysFocusNode.unfocus(),
                    label: '提醒天数',
                    suffixText: '天',
                    onSubmitted: (_) => unawaited(_submitDays()),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '可设置 1～30 天。完成输入后点击键盘上的“完成”。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
  );
}
