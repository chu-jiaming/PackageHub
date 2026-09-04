import 'package:flutter/material.dart';

import 'account_repository.dart';
import 'account_device.dart';

import 'package:packagehub/design_system/components/ph_grouped_section.dart';
import 'package:packagehub/design_system/components/ph_list_row.dart';
import 'package:packagehub/design_system/components/ph_navigation_header.dart';

class DevicesPage extends StatelessWidget {
  final AccountRepository accountRepository;
  const DevicesPage({super.key, required this.accountRepository});
  @override
  Widget build(BuildContext context) {
    final state = accountRepository.current;
    return Scaffold(
      appBar: PHNavigationHeader(
        title: '登录设备',
        leading: IconButton(
          tooltip: '返回',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: !state.isSignedIn
          ? const Center(child: Text('请先登录 PackageHub 账号'))
          : FutureBuilder<List<AccountDevice>>(
              future: accountRepository.loadDevices(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    PHGroupedSection(
                      title: '已登录设备',
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        for (var i = 0; i < snapshot.data!.length; i++)
                          PHListRow(
                            leading: const Icon(Icons.devices_outlined),
                            title: snapshot.data![i].deviceLabel,
                            subtitle:
                                '${snapshot.data![i].platform} · 最后使用：${snapshot.data![i].lastSeenAt.toLocal()}',
                            showChevron: false,
                            showSeparator: i < snapshot.data!.length - 1,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Pro 设备限制将在订阅系统接入后生效.'),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
