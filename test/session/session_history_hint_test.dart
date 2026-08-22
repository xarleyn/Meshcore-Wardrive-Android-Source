import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/screens/session_history_screen.dart';

void main() {
  testWidgets('session map hint stays brighter than the dark card', (
    tester,
  ) async {
    late TextStyle style;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          cardColor: const Color(0xFF1E1E1E),
        ),
        home: Builder(
          builder: (context) {
            style = sessionMapHintStyle(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(style.color, isNotNull);
    expect(style.color!.computeLuminance(), greaterThan(0.15));
    expect(
      style.color!.computeLuminance(),
      greaterThan(const Color(0xFF1E1E1E).computeLuminance()),
    );
  });
}
