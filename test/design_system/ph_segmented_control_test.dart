import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:packagehub/design_system/components/ph_segmented_control.dart';

enum _Choice { first, second, third }

Widget _segmented({
  required _Choice value,
  required ValueChanged<_Choice?> onValueChanged,
}) {
  return CupertinoApp(
    home: Center(
      child: PHSegmentedControl<_Choice>(
        value: value,
        children: const {
          _Choice.first: Text('第一'),
          _Choice.second: Text('第二'),
          _Choice.third: Text('第三'),
        },
        onValueChanged: onValueChanged,
      ),
    ),
  );
}

void main() {
  testWidgets('direct tap selects each segment', (tester) async {
    var selected = _Choice.first;
    await tester.pumpWidget(
      _segmented(
        value: selected,
        onValueChanged: (value) {
          if (value != null) selected = value;
        },
      ),
    );

    for (final label in ['第一', '第二', '第三']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }
    expect(selected, _Choice.third);
  });

  testWidgets('drag selects a segment', (tester) async {
    var selected = _Choice.first;
    await tester.pumpWidget(
      _segmented(
        value: selected,
        onValueChanged: (value) {
          if (value != null) selected = value;
        },
      ),
    );

    await tester.dragFrom(
      tester.getCenter(find.text('第一')),
      const Offset(140, 0),
    );
    await tester.pumpAndSettle();
    expect(selected, isNot(_Choice.first));
  });

  testWidgets('small jitter does not clear the current selection', (
    tester,
  ) async {
    var selected = _Choice.second;
    await tester.pumpWidget(
      _segmented(
        value: selected,
        onValueChanged: (value) {
          if (value != null) selected = value;
        },
      ),
    );

    await tester.drag(
      find.byType(CupertinoSlidingSegmentedControl<_Choice>),
      const Offset(2, 1),
    );
    await tester.pumpAndSettle();
    expect(selected, _Choice.second);
  });

  testWidgets('segmented control meets minimum interactive height', (
    tester,
  ) async {
    await tester.pumpWidget(
      _segmented(value: _Choice.first, onValueChanged: (_) {}),
    );

    expect(
      tester.getSize(find.byType(PHSegmentedControl<_Choice>)).height,
      greaterThanOrEqualTo(44),
    );
  });
}
