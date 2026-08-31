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

  const PickupCredentialDraft({
    required this.courierCompany,
    required this.trackingNumber,
    required this.pickupCode,
    required this.stationName,
    required this.status,
    required this.sourcePlatform,
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
