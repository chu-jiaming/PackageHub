import 'package:packagehub/recognition/recognition_evidence.dart';
import 'package:packagehub/recognition/recognition_conflict.dart';

enum PackagePlatform { taobao, pinduoduo, jd, cainiao, unknown }

enum CourierCompany {
  sfExpress,
  yto,
  zto,
  sto,
  yunda,
  jtexpress,
  ems,
  chinaPost,
  jdLogistics,
  deppon,
  cainiaoExpress,
  bestExpress,
  other,
  unknown,
}

enum PickupStatus { pending, pickedUp, unknown }

class PickupCredentialDraft {
  final CourierCompany courierCompany;
  final String? trackingNumber;
  final String? pickupCode;
  final String? stationName;
  final PickupStatus status;
  final PackagePlatform sourcePlatform;
  final String rawText;
  final List<RecognitionEvidence> evidence;
  final List<RecognitionConflict> conflicts;

  const PickupCredentialDraft({
    required this.courierCompany,
    required this.trackingNumber,
    required this.pickupCode,
    required this.stationName,
    required this.status,
    required this.sourcePlatform,
    required this.rawText,
    this.evidence = const [],
    this.conflicts = const [],
  });

  PickupCredentialDraft copyWith({
    CourierCompany? courierCompany,
    Object? trackingNumber = _unset,
    Object? pickupCode = _unset,
    List<RecognitionEvidence>? evidence,
    List<RecognitionConflict>? conflicts,
  }) => PickupCredentialDraft(
    courierCompany: courierCompany ?? this.courierCompany,
    trackingNumber: identical(trackingNumber, _unset)
        ? this.trackingNumber
        : trackingNumber as String?,
    pickupCode: identical(pickupCode, _unset)
        ? this.pickupCode
        : pickupCode as String?,
    stationName: stationName,
    status: status,
    sourcePlatform: sourcePlatform,
    rawText: rawText,
    evidence: evidence ?? this.evidence,
    conflicts: conflicts ?? this.conflicts,
  );
}

const _unset = Object();

extension PackagePlatformDisplayName on PackagePlatform {
  String get displayName {
    return switch (this) {
      PackagePlatform.taobao => '淘宝',
      PackagePlatform.pinduoduo => '拼多多',
      PackagePlatform.jd => '京东',
      PackagePlatform.cainiao => '菜鸟',
      PackagePlatform.unknown => '其他 / 未知',
    };
  }
}

extension CourierCompanyDisplayName on CourierCompany {
  String get displayName {
    return switch (this) {
      CourierCompany.sfExpress => '顺丰速运',
      CourierCompany.yto => '圆通速递',
      CourierCompany.zto => '中通快递',
      CourierCompany.sto => '申通快递',
      CourierCompany.yunda => '韵达快递',
      CourierCompany.jtexpress => '极兔速递',
      CourierCompany.ems => 'EMS',
      CourierCompany.chinaPost => '中国邮政',
      CourierCompany.jdLogistics => '京东物流',
      CourierCompany.deppon => '德邦快递',
      CourierCompany.cainiaoExpress => '菜鸟速递',
      CourierCompany.bestExpress => '百世快递',
      CourierCompany.other => '其他',
      CourierCompany.unknown => '未识别快递公司',
    };
  }

  /// Compact name used by station-facing UI surfaces.
  String get stationDisplayName {
    return switch (this) {
      CourierCompany.sfExpress => '顺丰',
      CourierCompany.yto => '圆通',
      CourierCompany.zto => '中通',
      CourierCompany.sto => '申通',
      CourierCompany.yunda => '韵达',
      CourierCompany.jtexpress => '极兔',
      CourierCompany.ems || CourierCompany.chinaPost => '邮政',
      CourierCompany.jdLogistics => '京东',
      _ => displayName,
    };
  }
}

extension PickupStatusDisplayName on PickupStatus {
  String get displayName {
    return switch (this) {
      PickupStatus.pending => '待取件',
      PickupStatus.pickedUp => '已取件',
      PickupStatus.unknown => '未判断',
    };
  }
}
