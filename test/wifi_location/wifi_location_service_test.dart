import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meshcore_wardrive/services/wifi_location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('filters private, hidden, opted-out, and stale access points', () {
    final selected = WifiLocationService.selectAccessPoints([
      _scan('00:11:22:33:44:55', 'public', -60),
      _scan('00:11:22:33:44:55', 'public', -40),
      _scan('04:11:22:33:44:56', 'cafe_nomap', -30),
      _scan('06:11:22:33:44:57', 'randomized', -20),
      _scan('08:11:22:33:44:58', '', -20),
      _scan('0c:11:22:33:44:59', 'stale', -20, ageMillis: 45001),
    ]);

    expect(selected, hasLength(1));
    expect(selected.single.bssid, '00:11:22:33:44:55');
    expect(selected.single.signalStrength, -40);
  });

  test('sends only radio fields and parses a beaconDB estimate', () async {
    late Map<String, dynamic> requestJson;
    final client = MockClient((request) async {
      requestJson = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(
        jsonEncode({
          'location': {'lat': 55.75, 'lng': 37.62},
          'accuracy': 42.0,
        }),
        200,
      );
    });
    final service = WifiLocationService(
      client: client,
      scanner: () async => [
        _scan('00:11:22:33:44:55', 'home', -40),
        _scan('0c:11:22:33:44:66', 'office', -55),
      ],
    );

    final estimate = await service.locate();

    expect(estimate, isNotNull);
    expect(estimate!.position.latitude, 55.75);
    expect(estimate.position.longitude, 37.62);
    expect(estimate.accuracyMeters, 42);
    expect(estimate.accessPointCount, 2);
    expect(requestJson['considerIp'], isFalse);
    expect(requestJson['fallbacks'], {'ipf': false, 'lacf': false});
    final sentAccessPoints = requestJson['wifiAccessPoints'] as List<dynamic>;
    expect(sentAccessPoints, hasLength(2));
    expect(sentAccessPoints.first, isNot(contains('ssid')));
    service.dispose();
  });

  test('returns null when beaconDB has no matching access points', () async {
    final service = WifiLocationService(
      client: MockClient((_) async => http.Response('{}', 404)),
      scanner: () async => [
        _scan('00:11:22:33:44:55', 'one', -40),
        _scan('0c:11:22:33:44:66', 'two', -55),
      ],
    );

    expect(await service.locate(), isNull);
    service.dispose();
  });

  test('does not accept a coarse server fallback as Wi-Fi location', () async {
    final service = WifiLocationService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'location': {'lat': 55.75, 'lng': 37.62},
            'accuracy': 10000,
            'fallback': 'ipf',
          }),
          200,
        ),
      ),
      scanner: () async => [
        _scan('00:11:22:33:44:55', 'one', -40),
        _scan('0c:11:22:33:44:66', 'two', -55),
      ],
    );

    expect(await service.locate(), isNull);
    service.dispose();
  });
}

Map<Object?, Object?> _scan(
  String bssid,
  String ssid,
  int signalStrength, {
  int ageMillis = 1000,
}) => {
  'bssid': bssid,
  'ssid': ssid,
  'signalStrength': signalStrength,
  'frequency': 2412,
  'ageMillis': ageMillis,
};
