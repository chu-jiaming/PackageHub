import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:packagehub/core/reminder/pickup_notification_service.dart';
import 'package:packagehub/core/repository/pickup_credential_repository.dart';
import 'package:packagehub/features/settings/pickup_reminder_settings_page.dart';
import 'package:packagehub/models/pickup_credential.dart';
import 'package:packagehub/models/pickup_reminder_settings.dart';

void main() {
  testWidgets('reminder days uses a numeric keyboard and digits-only input', (
    tester,
  ) async {
    await _pumpPage(tester);

    final textField = tester.widget<TextField>(
      find.byKey(const Key('pickupReminderDaysField')),
    );
    expect(textField.keyboardType, TextInputType.number);
    expect(textField.textInputAction, TextInputAction.done);
    expect(textField.inputFormatters, hasLength(1));

    final formatter = textField.inputFormatters!.single;
    final formatted = formatter.formatEditUpdate(
      const TextEditingValue(),
      const TextEditingValue(text: '0a7'),
    );
    expect(formatted.text, '07');
  });

  testWidgets(
    'done action releases focus, preserves text, and saves clamped days',
    (tester) async {
      final repository = _FakeReminderRepository();
      await _pumpPage(tester, repository: repository);

      final field = find.byKey(const Key('pickupReminderDaysField'));
      await tester.tap(field);
      await tester.enterText(field, '35');
      expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);

      final keyboardField = tester.widget<KeyboardField>(
        find.byType(KeyboardField),
      );
      final doneButton =
          keyboardField.toolbarButtons!.single(FocusNode()) as CupertinoButton;
      doneButton.onPressed!();
      await tester.pump();

      expect(tester.widget<TextField>(field).focusNode!.hasFocus, isFalse);
      expect(tester.widget<TextField>(field).controller!.text, '35');
      expect(repository.savedSettings.days, 30);
    },
  );

  testWidgets(
    'submitted invalid input keeps existing fallback validation and saves',
    (tester) async {
      final repository = _FakeReminderRepository();
      await _pumpPage(tester, repository: repository);

      await tester.enterText(
        find.byKey(const Key('pickupReminderDaysField')),
        '',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(repository.savedSettings.days, 3);
    },
  );

  testWidgets('keyboard accessory is disabled on Android', (tester) async {
    await _pumpPage(tester);

    expect(
      tester.widget<KeyboardActions>(find.byType(KeyboardActions)).enabled,
      isFalse,
    );
  });

  testWidgets('keyboard accessory is enabled on iOS', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await _pumpPage(tester);

    expect(
      tester.widget<KeyboardActions>(find.byType(KeyboardActions)).enabled,
      isTrue,
    );
    debugDefaultTargetPlatformOverride = null;
  });
}

Future<void> _pumpPage(
  WidgetTester tester, {
  _FakeReminderRepository? repository,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: PickupReminderSettingsPage(
        repository: repository ?? _FakeReminderRepository(),
        notificationService: _FakeNotificationService(),
      ),
    ),
  );
  await tester.pump();
}

class _FakeReminderRepository implements PickupReminderSettingsRepository {
  PickupReminderSettings savedSettings = const PickupReminderSettings();

  @override
  Future<List<PickupCredential>> getAll() async => [];

  @override
  Future<PickupReminderSettings> getReminderSettings() async =>
      const PickupReminderSettings();

  @override
  Future<void> saveReminderSettings(PickupReminderSettings settings) async {
    savedSettings = settings;
  }
}

class _FakeNotificationService extends PickupNotificationService {
  @override
  Future<void> sync(
    Iterable<PickupCredential> credentials, {
    required PickupReminderSettings settings,
  }) async {}
}
