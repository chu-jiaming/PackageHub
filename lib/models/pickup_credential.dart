import 'package:packagehub/models/pickup_credential_draft.dart';

const Object _copyWithUnset = Object();

/// Persisted pickup credential entity.
///
/// PackageHub v1 local persistence deliberately stores only structured
/// pickup credential fields. Do not persist raw OCR text or imported
/// screenshots without an explicit future product decision.
class PickupCredential {
  final int? id;
  final CourierCompany courierCompany;
  final String? trackingNumber;
  final String? pickupCode;
  final PickupStatus status;
  final PackagePlatform sourcePlatform;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PickupCredential({
    this.id,
    required this.courierCompany,
    this.trackingNumber,
    this.pickupCode,
    required this.status,
    required this.sourcePlatform,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a persisted entity from a [PickupCredentialDraft].
  ///
  /// Only structured fields are copied. [rawText] and [stationName] are
  /// intentionally excluded for privacy and product reasons.
  factory PickupCredential.fromDraft(
    PickupCredentialDraft draft, {
    int? id,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    return PickupCredential(
      id: id,
      courierCompany: draft.courierCompany,
      trackingNumber: draft.trackingNumber,
      pickupCode: draft.pickupCode,
      status: draft.status,
      sourcePlatform: draft.sourcePlatform,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  /// Convert to a database-compatible map with snake_case keys.
  ///
  /// Enums are serialized using their `.name` property for stability.
  /// Timestamps are stored as millisecondsSinceEpoch.
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'courier_company': courierCompany.name,
      'tracking_number': trackingNumber,
      'pickup_code': pickupCode,
      'status': status.name,
      'source_platform': sourcePlatform.name,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Reconstruct a [PickupCredential] from a database map.
  ///
  /// Unknown enum strings fall back to their respective `.unknown` variant
  /// instead of throwing.
  factory PickupCredential.fromMap(Map<String, Object?> map) {
    return PickupCredential(
      id: map['id'] as int?,
      courierCompany: _parseCourierCompany(map['courier_company'] as String?),
      trackingNumber: map['tracking_number'] as String?,
      pickupCode: map['pickup_code'] as String?,
      status: _parsePickupStatus(map['status'] as String?),
      sourcePlatform: _parsePackagePlatform(map['source_platform'] as String?),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  static CourierCompany _parseCourierCompany(String? value) {
    if (value == null) return CourierCompany.unknown;
    for (final company in CourierCompany.values) {
      if (company.name == value) return company;
    }
    return CourierCompany.unknown;
  }

  static PickupStatus _parsePickupStatus(String? value) {
    if (value == null) return PickupStatus.unknown;
    for (final status in PickupStatus.values) {
      if (status.name == value) return status;
    }
    return PickupStatus.unknown;
  }

  static PackagePlatform _parsePackagePlatform(String? value) {
    if (value == null) return PackagePlatform.unknown;
    for (final platform in PackagePlatform.values) {
      if (platform.name == value) return platform;
    }
    return PackagePlatform.unknown;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PickupCredential &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          courierCompany == other.courierCompany &&
          trackingNumber == other.trackingNumber &&
          pickupCode == other.pickupCode &&
          status == other.status &&
          sourcePlatform == other.sourcePlatform;

  /// Return a copy with a new database-generated [id].
  PickupCredential copyWithId(int newId) {
    return copyWith(id: newId);
  }

  PickupCredential copyWith({
    int? id,
    CourierCompany? courierCompany,
    Object? trackingNumber = _copyWithUnset,
    Object? pickupCode = _copyWithUnset,
    PickupStatus? status,
    PackagePlatform? sourcePlatform,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PickupCredential(
      id: id ?? this.id,
      courierCompany: courierCompany ?? this.courierCompany,
      trackingNumber: identical(trackingNumber, _copyWithUnset)
          ? this.trackingNumber
          : trackingNumber as String?,
      pickupCode: identical(pickupCode, _copyWithUnset)
          ? this.pickupCode
          : pickupCode as String?,
      status: status ?? this.status,
      sourcePlatform: sourcePlatform ?? this.sourcePlatform,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  int get hashCode => Object.hash(
    id,
    courierCompany,
    trackingNumber,
    pickupCode,
    status,
    sourcePlatform,
  );
}
