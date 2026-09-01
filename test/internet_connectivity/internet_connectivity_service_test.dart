import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/services/internet_connectivity_service.dart';

void main() {
  test('reports offline when the internet probe fails', () async {
    final service = InternetConnectivityService(probe: (_) async => false);

    await service.checkNow();

    expect(service.status, InternetStatus.offline);
    expect(service.isOffline, isTrue);
    service.dispose();
  });

  test('reports recovery when a later probe succeeds', () async {
    var isReachable = false;
    final service = InternetConnectivityService(
      probe: (_) async => isReachable,
    );

    await service.checkNow();
    isReachable = true;
    await service.checkNow();

    expect(service.status, InternetStatus.online);
    expect(service.isOffline, isFalse);
    service.dispose();
  });

  test('treats a probe timeout as offline', () async {
    final probeCompleter = Completer<bool>();
    final service = InternetConnectivityService(
      probeTimeout: const Duration(milliseconds: 1),
      probe: (_) => probeCompleter.future,
    );

    await service.checkNow();

    expect(service.status, InternetStatus.offline);
    service.dispose();
  });
}
