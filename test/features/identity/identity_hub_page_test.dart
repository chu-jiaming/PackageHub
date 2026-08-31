import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:packagehub/core/launcher/identity_launcher.dart';
import 'package:packagehub/core/launcher/identity_launch_target.dart';
import 'package:packagehub/core/launcher/identity_targets.dart';
import 'package:packagehub/features/identity/identity_hub_page.dart';
import 'package:packagehub/models/identity_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class _FakeLauncher implements IdentityLauncherApi {
  final List<IdentityProvider> calls = [];
  IdentityLaunchResult result;

  _FakeLauncher([this.result = IdentityLaunchResult.openedIdentityCode]);

  @override
  Future<IdentityLaunchResult> openIdentityCode(
    IdentityProvider provider,
  ) async {
    calls.add(provider);
    return result;
  }

  @override
  Future<bool> openAppFallback(IdentityProvider provider) async => true;
}

Widget _app(IdentityLauncherApi launcher) =>
    MaterialApp(home: IdentityHubPage(launcher: launcher));

void main() {
  test(
    'PDD production target is the verified app deep link identity target',
    () async {
      final target = identityLaunchTargets[IdentityProvider.pinduoduo]!;
      final primary = target.directTargets.first;
      expect(primary.uri.toString(), contains('entry_source=11'));
      expect(primary.uri.toString(), contains('refer_page_name=login'));
      expect(primary.verification, IdentityTargetVerification.verified);
      expect(primary.type, IdentityTargetType.appDeepLink);
      expect(primary.destination, IdentityTargetDestination.identityCode);
      final modes = <LaunchMode>[];
      final launcher = IdentityLauncher(
        openUri: (uri, mode) async {
          modes.add(mode);
          return true;
        },
      );
      expect(
        await launcher.openIdentityCode(IdentityProvider.pinduoduo),
        IdentityLaunchResult.openedIdentityCode,
      );
      expect(modes, [LaunchMode.externalApplication]);
    },
  );

  test('target configuration is centralized and ordered', () {
    final target = identityLaunchTargets[IdentityProvider.taobao]!;
    expect(target.directTargets.first.uri.toString(), taobaoIdentityUrl);
    expect(target.directTargets, hasLength(2));
    expect(
      target.directTargets.every(
        (item) => item.verification == IdentityTargetVerification.experimental,
      ),
      isTrue,
    );
  });

  test('Cainiao uses the experimental web identity target', () {
    final target = identityLaunchTargets[IdentityProvider.cainiao]!;
    final primary = target.directTargets.single;
    expect(primary.uri.toString(), cainiaoIdentityUrl);
    expect(primary.type, IdentityTargetType.web);
    expect(primary.destination, IdentityTargetDestination.identityCode);
    expect(primary.verification, IdentityTargetVerification.experimental);
    expect(target.appFallbackUri, isNull);
  });

  test(
    'Cainiao opens only its in-app browser target and never an app fallback',
    () async {
      final calls = <Uri>[];
      final modes = <LaunchMode>[];
      final launcher = IdentityLauncher(
        openUri: (uri, mode) async {
          calls.add(uri);
          modes.add(mode);
          return false;
        },
      );
      expect(
        await launcher.openIdentityCode(IdentityProvider.cainiao),
        IdentityLaunchResult.directTargetFailed,
      );
      expect(calls, [Uri.parse(cainiaoIdentityUrl)]);
      expect(modes, [LaunchMode.inAppBrowserView]);
      expect(await launcher.openAppFallback(IdentityProvider.cainiao), isFalse);
      expect(calls, [Uri.parse(cainiaoIdentityUrl)]);
    },
  );

  test('experimental web target succeeds when launchUrl succeeds', () async {
    final launcher = IdentityLauncher(openUri: (uri, mode) async => true);
    expect(
      await launcher.openIdentityCode(IdentityProvider.cainiao),
      IdentityLaunchResult.openedIdentityCode,
    );
  });

  test('experimental app deep link succeeds when launchUrl succeeds', () async {
    final launcher = IdentityLauncher(
      openUri: (uri, mode) async => true,
      targets: {
        IdentityProvider.cainiao: IdentityLaunchTarget(
          provider: IdentityProvider.cainiao,
          directTargets: [
            IdentityDirectTarget(
              uri: Uri.parse('cainiao://identity-code'),
              type: IdentityTargetType.appDeepLink,
              verification: IdentityTargetVerification.experimental,
              destination: IdentityTargetDestination.identityCode,
            ),
          ],
        ),
      },
    );
    expect(
      await launcher.openIdentityCode(IdentityProvider.cainiao),
      IdentityLaunchResult.openedIdentityCode,
    );
  });

  test('experimental direct targets never auto-open app fallback', () async {
    final calls = <Uri>[];
    final modes = <LaunchMode>[];
    final launcher = IdentityLauncher(
      openUri: (uri, mode) async {
        calls.add(uri);
        modes.add(mode);
        return false;
      },
      targets: {
        IdentityProvider.taobao: IdentityLaunchTarget(
          provider: IdentityProvider.taobao,
          directTargets: [
            IdentityDirectTarget(
              uri: Uri.parse('https://one.example'),
              type: IdentityTargetType.web,
              verification: IdentityTargetVerification.experimental,
              destination: IdentityTargetDestination.identityCode,
            ),
            IdentityDirectTarget(
              uri: Uri.parse('https://two.example'),
              type: IdentityTargetType.web,
              verification: IdentityTargetVerification.experimental,
              destination: IdentityTargetDestination.identityCode,
            ),
          ],
          appFallbackUri: Uri.parse('https://fallback.example'),
        ),
      },
    );
    expect(
      await launcher.openIdentityCode(IdentityProvider.taobao),
      IdentityLaunchResult.directTargetFailed,
    );
    expect(calls.map((uri) => uri.toString()), [
      'https://one.example',
      'https://two.example',
    ]);
    expect(calls, isNot(contains(Uri.parse('https://fallback.example'))));
    expect(modes, [LaunchMode.inAppBrowserView, LaunchMode.inAppBrowserView]);
  });

  test('verified web target reports browser opening, fallback is external only when called', () async {
    final modes = <LaunchMode>[];
    final launcher = IdentityLauncher(
      openUri: (uri, mode) async {
        modes.add(mode);
        return true;
      },
      targets: {
        IdentityProvider.taobao: IdentityLaunchTarget(
          provider: IdentityProvider.taobao,
          directTargets: [
            IdentityDirectTarget(
              uri: Uri.parse('https://identity.example'),
              type: IdentityTargetType.web,
              verification: IdentityTargetVerification.verified,
              destination: IdentityTargetDestination.identityCode,
            ),
          ],
          appFallbackUri: Uri.parse('https://app.example'),
        ),
      },
    );
    expect(
      await launcher.openIdentityCode(IdentityProvider.taobao),
      IdentityLaunchResult.openedIdentityCode,
    );
    expect(modes, [LaunchMode.inAppBrowserView]);
    expect(await launcher.openAppFallback(IdentityProvider.taobao), isTrue);
    expect(modes, [
      LaunchMode.inAppBrowserView,
      LaunchMode.externalApplication,
    ]);
  });

  test('provider metadata maps both built-in platforms', () {
    expect(IdentityProvider.taobao.metadata.displayName, '淘宝');
    expect(IdentityProvider.pinduoduo.metadata.displayName, '拼多多');
    expect(IdentityProvider.taobao.metadata.subtitle, '快递取件身份码');
    expect(IdentityProvider.pinduoduo.metadata.subtitle, '快递取件身份码');
  });

  testWidgets('shows providers and invokes injected launcher', (tester) async {
    final launcher = _FakeLauncher();
    await tester.pumpWidget(_app(launcher));
    expect(find.text('淘宝'), findsOneWidget);
    expect(find.text('拼多多'), findsOneWidget);
    expect(find.text('菜鸟裹裹'), findsOneWidget);
    expect(find.text('快递取件身份码'), findsNWidgets(3));
    await tester.tap(find.text('淘宝'));
    await tester.pump();
    await tester.tap(find.text('拼多多'));
    await tester.pump();
    expect(launcher.calls, [
      IdentityProvider.taobao,
      IdentityProvider.pinduoduo,
    ]);
    expect(find.textContaining('无法打开'), findsNothing);
  });

  testWidgets('Cainiao failure has no app fallback action', (tester) async {
    final launcher = _FakeLauncher(IdentityLaunchResult.directTargetFailed);
    await tester.pumpWidget(_app(launcher));
    await tester.tap(find.text('菜鸟裹裹'));
    await tester.pump();
    expect(find.text('无法直达菜鸟裹裹身份码'), findsOneWidget);
    expect(find.text('打开菜鸟裹裹'), findsNothing);
  });

  testWidgets('shows a friendly error when launching fails', (tester) async {
    final launcher = _FakeLauncher(IdentityLaunchResult.directTargetFailed);
    await tester.pumpWidget(_app(launcher));
    await tester.tap(find.text('淘宝'));
    await tester.pump();
    expect(find.text('无法直达淘宝身份码'), findsOneWidget);
  });
}
