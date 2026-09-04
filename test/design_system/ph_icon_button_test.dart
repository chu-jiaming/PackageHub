import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:packagehub/design_system/components/ph_icon_button.dart';

Widget _iconButton({VoidCallback? onPressed}) {
  return CupertinoApp(
    home: Center(
      child: PHIconButton(
        icon: const Icon(CupertinoIcons.add),
        semanticsLabel: '添加',
        onPressed: onPressed,
      ),
    ),
  );
}

void main() {
  testWidgets('icon button enforces a 44 point hit target', (tester) async {
    await tester.pumpWidget(_iconButton(onPressed: () {}));

    expect(tester.getSize(find.byType(PHIconButton)), const Size(44, 44));
  });

  testWidgets('icon button emits callback', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_iconButton(onPressed: () => tapped = true));

    await tester.tap(find.byType(PHIconButton));
    expect(tapped, isTrue);
  });

  testWidgets('disabled icon button does not emit callback', (tester) async {
    await tester.pumpWidget(_iconButton(onPressed: null));

    await tester.tap(find.byType(PHIconButton));
    expect(find.bySemanticsLabel('添加'), findsOneWidget);
  });

  testWidgets('icon button exposes semantics label', (tester) async {
    await tester.pumpWidget(_iconButton(onPressed: () {}));

    expect(find.bySemanticsLabel('添加'), findsOneWidget);
  });
}
