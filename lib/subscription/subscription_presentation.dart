import 'subscription_entitlement.dart';
import 'subscription_state.dart';

class SubscriptionPresentation {
  static String title(SubscriptionEntitlement entitlement) =>
      entitlement.isPro ? 'PackageHub Pro' : 'PackageHub Free';

  static String subtitle(SubscriptionEntitlement entitlement) {
    switch (entitlement.state) {
      case SubscriptionState.gracePeriod:
      case SubscriptionState.billingRetry:
        return '续费遇到问题 · 权益暂时保留';
      case SubscriptionState.expired:
        return 'Pro 已到期';
      case SubscriptionState.revoked:
        return 'Pro 权益已结束';
      case SubscriptionState.free:
        return '基础功能可继续使用';
      case SubscriptionState.active:
      case SubscriptionState.trial:
        return entitlement.planDisplayName ?? '持续服务方案';
    }
  }

  static String date(DateTime? value) {
    if (value == null) return '有效期未知';
    final local = value.toLocal();
    return '有效至 ${local.year.toString().padLeft(4, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.day.toString().padLeft(2, '0')}';
  }
}
