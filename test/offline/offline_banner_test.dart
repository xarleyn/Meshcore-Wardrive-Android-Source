import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/services/internet_connectivity_service.dart';
import 'package:meshcore_wardrive/widgets/offline_banner.dart';

import '../helpers/l10n_harness.dart';

void main() {
  testWidgets('shows the banner only while offline', (tester) async {
    var isReachable = true;
    final service = InternetConnectivityService(
      probe: (_) async => isReachable,
    );
    await service.checkNow();

    final l10n = await pumpWithL10n(
      tester,
      OfflineAppFrame(
        connectivity: service,
        child: const Scaffold(body: Text('Map content')),
      ),
    );

    expect(find.text(l10n.offlineBannerMessage), findsNothing);
    expect(find.text('Map content'), findsOneWidget);

    isReachable = false;
    await service.checkNow();
    await tester.pump();

    expect(find.text(l10n.offlineBannerMessage), findsOneWidget);
    expect(find.text('Map content'), findsOneWidget);
    service.dispose();
  });

  testWidgets('shows a Russian offline banner', (tester) async {
    var isReachable = false;
    final service = InternetConnectivityService(
      probe: (_) async => isReachable,
    );
    await service.checkNow();

    final l10n = await pumpWithL10n(
      tester,
      OfflineAppFrame(
        connectivity: service,
        child: const Scaffold(body: Text('Map content')),
      ),
      locale: const Locale('ru'),
    );

    expect(find.text(l10n.offlineBannerMessage), findsOneWidget);
    expect(
      find.text('Вы офлайн — локальное отслеживание продолжается'),
      findsOneWidget,
    );
    service.dispose();
  });
}
