String? normalizeTrackingNumber(String? trackingNumber) {
  if (trackingNumber == null) {
    return null;
  }

  final normalized = trackingNumber.trim().replaceAll(' ', '').toUpperCase();
  if (normalized.isEmpty) {
    return null;
  }

  return normalized;
}
