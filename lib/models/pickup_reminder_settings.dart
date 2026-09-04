class PickupReminderSettings {
  final bool enabled;
  final int days;

  const PickupReminderSettings({this.enabled = true, this.days = 3});

  PickupReminderSettings copyWith({bool? enabled, int? days}) =>
      PickupReminderSettings(
        enabled: enabled ?? this.enabled,
        days: days ?? this.days,
      );
}
