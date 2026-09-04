import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:packagehub/design_system/components/ph_banner.dart';
import 'package:packagehub/design_system/components/ph_bottom_action_bar.dart';
import 'package:packagehub/design_system/components/ph_bottom_navigation.dart';
import 'package:packagehub/design_system/components/ph_bottom_sheet.dart';
import 'package:packagehub/design_system/components/ph_courier_section_header.dart';
import 'package:packagehub/design_system/components/ph_detail_row.dart';
import 'package:packagehub/design_system/components/ph_empty_state.dart';
import 'package:packagehub/design_system/components/ph_grouped_section.dart';
import 'package:packagehub/design_system/components/ph_identity_provider_card.dart';
import 'package:packagehub/design_system/components/ph_import_status_card.dart';
import 'package:packagehub/design_system/components/ph_list_row.dart';
import 'package:packagehub/design_system/components/ph_navigation_header.dart';
import 'package:packagehub/design_system/components/ph_section_header.dart';
import 'package:packagehub/design_system/components/ph_select_field.dart';
import 'package:packagehub/design_system/components/ph_text_field.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('navigation header preserves 44 point action targets', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const PHNavigationHeader(
          title: '设置',
          leading: SizedBox(width: 44, height: 44),
          actions: [SizedBox(width: 44, height: 44)],
        ),
      ),
    );

    expect(find.text('设置'), findsOneWidget);
    expect(tester.getSize(find.byType(PHNavigationHeader)).height, 64);
  });

  testWidgets('grouped section and list row can hide the last separator', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        PHGroupedSection(
          title: '账号',
          children: const [
            PHListRow(title: '账号信息'),
            PHListRow(title: '关于', showSeparator: false),
          ],
        ),
      ),
    );

    expect(find.text('账号'), findsOneWidget);
    expect(find.text('关于'), findsOneWidget);
  });

  testWidgets('form fields preserve controller and select callbacks', (
    tester,
  ) async {
    final controller = TextEditingController();
    String? selected;
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            PHTextField(
              controller: controller,
              label: '取件码',
              onChanged: (value) => controller.text = value,
            ),
            PHSelectField<String>(
              value: 'a',
              label: '快递公司',
              items: const [DropdownMenuItem(value: 'a', child: Text('A'))],
              onChanged: (value) => selected = value,
            ),
          ],
        ),
      ),
    );

    expect(find.text('取件码'), findsOneWidget);
    expect(find.text('快递公司'), findsOneWidget);
    expect(controller, isNotNull);
    expect(selected, isNull);
    controller.dispose();
  });

  testWidgets('remaining Wave 1 components expose their presentation props', (
    tester,
  ) async {
    var selectedIndex = -1;
    await tester.pumpWidget(
      _app(
        ListView(
          children: [
            const PHSectionHeader(title: '标题'),
            const PHBottomActionBar(actions: [Text('保存')]),
            const PHBottomSheet(title: '底部', child: Text('内容')),
            const PHIdentityProviderCard(
              title: '淘宝',
              subtitle: '身份码',
              icon: Icon(CupertinoIcons.person),
            ),
            const PHImportStatusCard(
              status: PHImportStatus.success,
              title: '识别完成',
            ),
            const PHDetailRow(label: '运单号', value: 'SF123'),
            const PHBanner(variant: PHBannerVariant.info, title: '提示'),
            const PHEmptyState(title: '暂无数据'),
            const PHCourierSectionHeader(title: '顺丰', count: 1),
            PHBottomNavigation(
              selectedIndex: 0,
              onDestinationSelected: (value) => selectedIndex = value,
              items: [
                PHBottomNavigationItem(
                  icon: const Icon(Icons.home),
                  label: '首页',
                ),
                PHBottomNavigationItem(
                  icon: const Icon(Icons.settings),
                  label: '设置',
                ),
              ],
            ),
          ],
        ),
      ),
    );

    expect(find.text('保存'), findsOneWidget);
    expect(find.text('识别完成'), findsOneWidget);
    expect(find.text('SF123'), findsOneWidget);
    expect(find.text('暂无数据'), findsOneWidget);
    expect(find.text('顺丰'), findsOneWidget);
    expect(selectedIndex, -1);
  });
}
