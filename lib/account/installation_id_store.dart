import 'dart:math';

import 'package:flutter/services.dart';

class InstallationIdStore {
  const InstallationIdStore();
  Future<String> getOrCreate() async {
    final existing = await const MethodChannel('packagehub/keychain')
        .invokeMethod<String>('read', {'key': 'packagehub.installation_id'});
    if (existing != null) return existing;
    final id = _uuid();
    await const MethodChannel('packagehub/keychain').invokeMethod<void>(
      'write',
      {'key': 'packagehub.installation_id', 'value': id},
    );
    return id;
  }

  String _uuid() {
    final r = Random.secure();
    String h(int n) =>
        List.generate(n, (_) => r.nextInt(16).toRadixString(16)).join();
    return '${h(8)}-${h(4)}-4${h(3)}-${(8 + r.nextInt(4)).toRadixString(16)}${h(3)}-${h(12)}';
  }
}
