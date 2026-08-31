import 'package:flutter/material.dart';

enum IdentityProvider { taobao, pinduoduo, cainiao }

class IdentityProviderMetadata {
  final String displayName;
  final String subtitle;
  final IconData icon;

  const IdentityProviderMetadata({
    required this.displayName,
    required this.subtitle,
    required this.icon,
  });
}

extension IdentityProviderMetadataExtension on IdentityProvider {
  IdentityProviderMetadata get metadata => switch (this) {
    IdentityProvider.taobao => const IdentityProviderMetadata(
      displayName: '淘宝',
      subtitle: '快递取件身份码',
      icon: Icons.shopping_bag_outlined,
    ),
    IdentityProvider.pinduoduo => const IdentityProviderMetadata(
      displayName: '拼多多',
      subtitle: '快递取件身份码',
      icon: Icons.storefront_outlined,
    ),
    IdentityProvider.cainiao => const IdentityProviderMetadata(
      displayName: '菜鸟裹裹',
      subtitle: '快递取件身份码',
      icon: Icons.local_shipping_outlined,
    ),
  };
}
