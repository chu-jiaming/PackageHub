import 'package:flutter/foundation.dart';

/// Whether the process may use the developer entitlement override.
///
/// Debug builds remain convenient for local development. Profile and release
/// builds require the explicit compile-time flag, whose safe default is false.
const bool _releaseOverrideEnabled = bool.fromEnvironment(
  'PACKAGEHUB_DEV_ENTITLEMENT_OVERRIDE',
  defaultValue: false,
);

bool get devEntitlementOverrideAllowed =>
    kDebugMode || _releaseOverrideEnabled;
