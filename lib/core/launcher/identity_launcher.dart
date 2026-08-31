import 'package:packagehub/core/launcher/identity_launch_target.dart';
import 'package:packagehub/core/launcher/identity_targets.dart';
import 'package:packagehub/models/identity_provider.dart';
import 'package:url_launcher/url_launcher.dart';

enum IdentityLaunchResult {
  openedIdentityCode,
  directTargetFailed,
  openedAppFallback,
  failed,
}

typedef IdentityUriOpener = Future<bool> Function(Uri uri, LaunchMode mode);

abstract interface class IdentityLauncherApi {
  Future<IdentityLaunchResult> openIdentityCode(IdentityProvider provider);
  Future<bool> openAppFallback(IdentityProvider provider);
}

class IdentityLauncher implements IdentityLauncherApi {
  final Map<IdentityProvider, IdentityLaunchTarget> targets;
  final IdentityUriOpener _openUri;
  IdentityLauncher({
    Map<IdentityProvider, IdentityLaunchTarget>? targets,
    IdentityUriOpener? openUri,
  }) : targets = targets ?? identityLaunchTargets,
       _openUri = openUri ?? ((uri, mode) => launchUrl(uri, mode: mode));

  @override
  Future<IdentityLaunchResult> openIdentityCode(
    IdentityProvider provider,
  ) async {
    final target = targets[provider];
    if (target == null) return IdentityLaunchResult.failed;
    for (final directTarget in target.directTargets) {
      try {
        final mode = directTarget.type == IdentityTargetType.web
            ? LaunchMode.inAppBrowserView
            : LaunchMode.externalApplication;
        // launchUrl == true means the system accepted and displayed the
        // direct target. Verification is configuration metadata, not a
        // DOM-level check or runtime success condition.
        if (await _openUri(directTarget.uri, mode)) {
          return IdentityLaunchResult.openedIdentityCode;
        }
      } catch (_) {}
    }
    return IdentityLaunchResult.directTargetFailed;
  }

  @override
  Future<bool> openAppFallback(IdentityProvider provider) async {
    final uri = targets[provider]?.appFallbackUri;
    if (uri == null) return false;
    try {
      return await _openUri(uri, LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
