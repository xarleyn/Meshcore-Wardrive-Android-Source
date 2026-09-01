import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/utils/discovery_timeout_options.dart';

void main() {
  test('includes the 5s timeout used in Settings', () {
    expect(DiscoveryTimeoutOptions.valuesFor(5), contains(5));
    expect(
      DiscoveryTimeoutOptions.valuesFor(5).where((v) => v == 5),
      hasLength(1),
    );
  });

  test('appends the current timeout when it is not a preset', () {
    final values = DiscoveryTimeoutOptions.valuesFor(7);
    expect(values, contains(7));
    expect(values.where((v) => v == 7), hasLength(1));
  });

  testWidgets('DropdownButton accepts a saved 5s discovery timeout', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DiscoveryTimeoutDropdown(value: 5, onChanged: (_) {}),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('5s'), findsOneWidget);
  });
}
