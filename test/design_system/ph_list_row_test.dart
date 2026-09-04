import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:packagehub/design_system/components/ph_list_row.dart';

Widget _row({
  String? subtitle,
  Widget? leading,
  Widget? trailing,
  VoidCallback? onTap,
  bool showChevron = true,
}) {
  return CupertinoApp(
    home: PHListRow(
      title: '设置',
      subtitle: subtitle,
      leading: leading,
      trailing: trailing,
      onTap: onTap,
      showChevron: showChevron,
    ),
  );
}

void main() {
  testWidgets('renders title, subtitle, leading, trailing and chevron', (
    tester,
  ) async {
    await tester.pumpWidget(
      _row(
        subtitle: '应用设置',
        leading: const Icon(CupertinoIcons.gear),
        trailing: const Text('开启'),
      ),
    );

    expect(find.text('设置'), findsOneWidget);
    expect(find.text('应用设置'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.gear), findsOneWidget);
    expect(find.text('开启'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.chevron_right), findsOneWidget);
  });

  testWidgets('supports missing subtitle and leading', (tester) async {
    await tester.pumpWidget(_row(showChevron: false));

    expect(find.text('设置'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.chevron_right), findsNothing);
  });

  testWidgets('row has an interactive minimum height and emits callback', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(_row(onTap: () => tapped = true));

    expect(
      tester.getSize(find.byType(PHListRow)).height,
      greaterThanOrEqualTo(44),
    );
    await tester.tap(find.byType(PHListRow));
    expect(tapped, isTrue);
  });
}
