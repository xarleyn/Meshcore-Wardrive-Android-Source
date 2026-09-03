import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/utils/ping_distance_options.dart';
import 'package:meshcore_wardrive/widgets/ping_distance_options.dart';

void main() {
  test('includes the Frequent 50m interval used in Settings', () {
    expect(PingDistanceOptions.valuesFor(50.0), contains(50.0));
    expect(
      PingDistanceOptions.valuesFor(50.0).where((v) => v == 50.0),
      hasLength(1),
    );
  });

  test(
    'does not duplicate 50m when it is both a preset and the current value',
    () {
      expect(PingDistanceOptions.valuesFor(50.0).toSet(), hasLength(5));
    },
  );

  test('appends the current interval when it is not a preset', () {
    final values = PingDistanceOptions.valuesFor(100.0);
    expect(values, contains(100.0));
    expect(values.where((v) => v == 100.0), hasLength(1));
  });

  testWidgets('DropdownButton accepts a saved 50m ping interval', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PingDistanceDropdown(value: 50.0, onChanged: (_) {}),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('50m'), findsOneWidget);
  });

  testWidgets('DropdownButton accepts a non-preset current interval', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PingDistanceDropdown(value: 100.0, onChanged: (_) {}),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('100m'), findsOneWidget);
  });
}
