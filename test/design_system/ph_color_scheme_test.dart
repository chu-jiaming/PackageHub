import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:packagehub/design_system/tokens/ph_color_scheme.dart';

void main() {
  test('matches the Figma Light semantic color collection', () {
    expect(PHColorScheme.light.bgCanvas, const Color(0xFFF2F2F7));
    expect(PHColorScheme.light.bgAccent, const Color(0xFF0066CC));
    expect(PHColorScheme.light.textAccent, const Color(0xFF0066CC));
    expect(PHColorScheme.light.iconAccent, const Color(0xFF007AFF));
    expect(PHColorScheme.light.borderDefault, const Color(0xFFE5E5EA));
  });

  test('matches the Figma Dark semantic color collection', () {
    expect(PHColorScheme.dark.bgCanvas, const Color(0xFF000000));
    expect(PHColorScheme.dark.bgSurface, const Color(0xFF1C1C1E));
    expect(PHColorScheme.dark.textPrimary, const Color(0xFFFFFFFF));
    expect(PHColorScheme.dark.textAccent, const Color(0xFF64B5F6));
    expect(PHColorScheme.dark.iconAccent, const Color(0xFF0A84FF));
    expect(PHColorScheme.dark.separatorDefault, const Color(0xFF2C2C2E));
  });

  testWidgets('components resolve the semantic scheme from ThemeExtension', (
    tester,
  ) async {
    late Color resolved;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [PHColorScheme.dark]),
        home: Builder(
          builder: (context) {
            resolved = PHColorScheme.of(context).textPrimary;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(resolved, PHColorScheme.dark.textPrimary);
  });
}
