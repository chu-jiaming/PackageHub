import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:packagehub/models/pickup_credential.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';
import 'package:packagehub/models/pickup_reminder_settings.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class PickupNotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  PickupNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    _initialized = true;
  }

  Future<void> sync(
    Iterable<PickupCredential> credentials, {
    required PickupReminderSettings settings,
  }) async {
    await initialize();
    await _plugin.cancelAll();
    if (!settings.enabled) return;
    final now = tz.TZDateTime.now(tz.local);
    for (final credential in credentials) {
      if (credential.id == null || credential.status != PickupStatus.pending) continue;
      final scheduled = tz.TZDateTime.from(
        credential.createdAt.add(Duration(days: settings.days)),
        tz.local,
      );
      await _plugin.zonedSchedule(
        credential.id!,
        '取件提醒',
        '有一个包裹已超过 ${settings.days} 天未取件，请及时取件。',
        scheduled.isBefore(now) ? now.add(const Duration(seconds: 2)) : scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'pickup_reminders',
            '取件提醒',
            channelDescription: '包裹超过设定天数后的取件提醒',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}
