class AccountDevice {
  final String id, installationId, platform, deviceLabel;
  final DateTime lastSeenAt;
  const AccountDevice({
    required this.id,
    required this.installationId,
    required this.platform,
    required this.deviceLabel,
    required this.lastSeenAt,
  });
}
