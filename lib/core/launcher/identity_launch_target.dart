import 'package:packagehub/models/identity_provider.dart';

enum IdentityTargetVerification { verified, experimental }

enum IdentityTargetType { web, appDeepLink }

enum IdentityTargetDestination { identityCode, appRoot }

class IdentityDirectTarget {
  final Uri uri;
  final IdentityTargetType type;
  final IdentityTargetVerification verification;
  final IdentityTargetDestination destination;
  const IdentityDirectTarget({
    required this.uri,
    required this.type,
    required this.verification,
    required this.destination,
  });
}

class IdentityLaunchTarget {
  final IdentityProvider provider;
  final List<IdentityDirectTarget> directTargets;
  final Uri? appFallbackUri;
  const IdentityLaunchTarget({
    required this.provider,
    required this.directTargets,
    this.appFallbackUri,
  });
}
