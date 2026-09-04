class StoreKitProductIds {
  StoreKitProductIds._();

  static const pro = String.fromEnvironment(
    'PACKAGEHUB_PRO_PRODUCT_ID',
    defaultValue: 'com.charm1ng.packagehub.pro.monthly',
  );
}
