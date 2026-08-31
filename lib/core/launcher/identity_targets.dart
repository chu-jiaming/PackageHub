import 'package:packagehub/core/launcher/identity_launch_target.dart';
import 'package:packagehub/models/identity_provider.dart';

const taobaoIdentityUrl =
    'https://pages-fast.m.taobao.com/wow/z/uniapp/1011717/last-mile-fe/end-collect-platform/identity-code';
const cainiaoIdentityUrl =
    'https://page.cainiao.com/cn-app-web/identity-code/index.html#/?source=&bizEntry=ALIPAY_GUOGUO';

final identityLaunchTargets = <IdentityProvider, IdentityLaunchTarget>{
  IdentityProvider.taobao: IdentityLaunchTarget(
    provider: IdentityProvider.taobao,
    directTargets: [
      IdentityDirectTarget(
        uri: Uri.parse(taobaoIdentityUrl),
        type: IdentityTargetType.web,
        verification: IdentityTargetVerification.experimental,
        destination: IdentityTargetDestination.identityCode,
      ),
      IdentityDirectTarget(
        uri: Uri.parse(
          'https://pages-fast.m.taobao.com/wow/z/uniapp/1100410/last-mile-fe/m-end-identity-code/home',
        ),
        type: IdentityTargetType.web,
        verification: IdentityTargetVerification.experimental,
        destination: IdentityTargetDestination.identityCode,
      ),
    ],
    appFallbackUri: Uri.parse('https://www.taobao.com/'),
  ),
  IdentityProvider.pinduoduo: IdentityLaunchTarget(
    provider: IdentityProvider.pinduoduo,
    directTargets: [
      // Manually verified on a real device to reach the PDD ID_CODE page.
      // refer_* values may be internal routing/attribution metadata; stability
      // is not guaranteed by a public API, so re-verify before simplifying.
      IdentityDirectTarget(
        uri: Uri.parse(
          'pinduoduo://com.xunmeng.pinduoduo/mdkd/package?tab=ID_CODE&entry_source=11&refer_page_name=login&refer_page_id=10169_1751901995470_3gdprcfjhr&refer_page_sn=10169',
        ),
        type: IdentityTargetType.appDeepLink,
        verification: IdentityTargetVerification.verified,
        destination: IdentityTargetDestination.identityCode,
      ),
      IdentityDirectTarget(
        uri: Uri.parse(
          'pinduoduo://com.xunmeng.pinduoduo/mdkd/package?tab=ID_CODE',
        ),
        type: IdentityTargetType.appDeepLink,
        verification: IdentityTargetVerification.experimental,
        destination: IdentityTargetDestination.identityCode,
      ),
      IdentityDirectTarget(
        uri: Uri.parse(
          'pinduoduo://com.xunmeng.pinduoduo/mdkd/package?tab=ID_CODE&entry_source=11',
        ),
        type: IdentityTargetType.appDeepLink,
        verification: IdentityTargetVerification.experimental,
        destination: IdentityTargetDestination.identityCode,
      ),
    ],
    appFallbackUri: Uri.parse('https://www.pinduoduo.com/'),
  ),
  IdentityProvider.cainiao: IdentityLaunchTarget(
    provider: IdentityProvider.cainiao,
    directTargets: [
      IdentityDirectTarget(
        uri: Uri.parse(cainiaoIdentityUrl),
        type: IdentityTargetType.web,
        verification: IdentityTargetVerification.experimental,
        destination: IdentityTargetDestination.identityCode,
      ),
    ],
  ),
};
