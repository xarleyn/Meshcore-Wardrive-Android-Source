import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/services/internet_connectivity_service.dart';
import 'package:meshcore_wardrive/widgets/offline_banner.dart';

void main() {
  testWidgets('shows the banner only while offline', (tester) async {
    var isReachable = true;
    final service = InternetConnectivityService(
      probe: (_) async => isReachable,
    );
    await service.checkNow();

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => OfflineAppFrame(
          connectivity: service,
          child: child ?? const SizedBox.shrink(),
        ),
        home: const Scaffold(body: Text('Map content')),
      ),
    );

    expect(
      find.text("You're offline - local tracking continues"),
      findsNothing,
    );
    expect(find.text('Map content'), findsOneWidget);

    isReachable = false;
    await service.checkNow();
    await tester.pump();

    expect(
      find.text("You're offline - local tracking continues"),
      findsOneWidget,
    );
    expect(find.text('Map content'), findsOneWidget);
    service.dispose();
  });
}
