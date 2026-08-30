enum PackagePlatform { taobao, pinduoduo, jd, cainiao, unknown }

enum PickupStatus { pending, unknown }

class PickupCredentialDraft {
  final PackagePlatform platform;
  final String? pickupCode;
  final String? stationName;
  final PickupStatus status;
  final String rawText;

  const PickupCredentialDraft({
    required this.platform,
    required this.pickupCode,
    required this.stationName,
    required this.status,
    required this.rawText,
  });
}

extension PackagePlatformDisplayName on PackagePlatform {
  String get displayName {
    return switch (this) {
      PackagePlatform.taobao => '淘宝',
      PackagePlatform.pinduoduo => '拼多多',
      PackagePlatform.jd => '京东',
      PackagePlatform.cainiao => '菜鸟',
      PackagePlatform.unknown => '未知',
    };
  }
}

extension PickupStatusDisplayName on PickupStatus {
  String get displayName {
    return switch (this) {
      PickupStatus.pending => '待取件',
      PickupStatus.unknown => '未知',
    };
  }
}
