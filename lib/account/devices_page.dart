import 'package:flutter/material.dart';

import 'account_repository.dart';
import 'account_device.dart';

class DevicesPage extends StatelessWidget {
  final AccountRepository accountRepository;
  const DevicesPage({super.key, required this.accountRepository});
  @override
  Widget build(BuildContext context) {
    final state = accountRepository.current;
    return Scaffold(
      appBar: AppBar(title: const Text('登录设备')),
      body: !state.isSignedIn
          ? const Center(child: Text('请先登录 PackageHub 账号'))
          : FutureBuilder<List<AccountDevice>>(
              future: accountRepository.loadDevices(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    for (final device in snapshot.data!)
                      ListTile(
                        leading: const Icon(Icons.devices_outlined),
                        title: Text(device.deviceLabel),
                        subtitle: Text(
                          '${device.platform} · 最后使用：${device.lastSeenAt.toLocal()}',
                        ),
                      ),
                    const SizedBox(height: 12),
                    const Text('Pro 设备限制将在订阅系统接入后生效.'),
                  ],
                );
              },
            ),
    );
  }
}
