import 'dart:async';
import 'dart:convert';
import 'dart:io' show HttpException;

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class WifiAccessPoint {
  const WifiAccessPoint({
    required this.bssid,
    required this.signalStrength,
    required this.frequency,
    required this.ageMillis,
  });

  final String bssid;
  final int signalStrength;
  final int frequency;
  final int ageMillis;

  Map<String, Object> toBeaconDbJson() => {
    'macAddress': bssid,
    'signalStrength': signalStrength,
    'frequency': frequency,
    'age': ageMillis,
  };
}

class WifiLocationEstimate {
  const WifiLocationEstimate({
    required this.position,
    required this.accuracyMeters,
    required this.accessPointCount,
  });

  final LatLng position;
  final double accuracyMeters;
  final int accessPointCount;
}

typedef WifiScanner = Future<List<Map<Object?, Object?>>> Function();

/// Obtains a Wi-Fi-only position from beaconDB.
///
/// SSIDs are inspected locally only to honor hidden and `_nomap` exclusions.
/// They are never included in the network request.
class WifiLocationService {
  WifiLocationService({http.Client? client, WifiScanner? scanner})
    : _client = client ?? http.Client(),
      _scanner = scanner ?? _scanWithPlatformChannel;

  static const _channel = MethodChannel(
    'mintylinux.meshcore.wardrive/wifi_location',
  );
  static final Uri _endpoint = Uri.parse(
    'https://api.beacondb.net/v1/geolocate',
  );
  static const int _maximumScanAgeMillis = 45000;
  static const int _maximumAccessPoints = 20;

  final http.Client _client;
  final WifiScanner _scanner;

  Future<WifiLocationEstimate?> locate() async {
    final rawScans = await _scanner();
    final accessPoints = selectAccessPoints(rawScans);
    if (accessPoints.length < 2) return null;

    final response = await _client
        .post(
          _endpoint,
          headers: const {
            'Content-Type': 'application/json',
            'User-Agent': 'MeshCore-Wardrive-Android/1',
          },
          body: jsonEncode({
            'considerIp': false,
            'fallbacks': {'ipf': false, 'lacf': false},
            'wifiAccessPoints': accessPoints
                .map((accessPoint) => accessPoint.toBeaconDbJson())
                .toList(),
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 404) return null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'beaconDB returned HTTP ${response.statusCode}',
        uri: _endpoint,
      );
    }

    final json = jsonDecode(response.body);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid beaconDB response');
    }
    if (json['fallback'] != null) return null;
    final location = json['location'];
    final accuracy = json['accuracy'];
    if (location is! Map<String, dynamic> || accuracy is! num) {
      throw const FormatException('Incomplete beaconDB response');
    }
    final latitude = location['lat'];
    final longitude = location['lng'];
    if (latitude is! num || longitude is! num) {
      throw const FormatException('Invalid beaconDB coordinates');
    }

    final accuracyMeters = accuracy.toDouble();
    if (!accuracyMeters.isFinite || accuracyMeters <= 0) {
      throw const FormatException('Invalid beaconDB accuracy');
    }

    return WifiLocationEstimate(
      position: LatLng(latitude.toDouble(), longitude.toDouble()),
      accuracyMeters: accuracyMeters,
      accessPointCount: accessPoints.length,
    );
  }

  static List<WifiAccessPoint> selectAccessPoints(
    List<Map<Object?, Object?>> scans,
  ) {
    final strongestByBssid = <String, WifiAccessPoint>{};

    for (final scan in scans) {
      final bssid = scan['bssid'];
      final ssid = scan['ssid'];
      final signalStrength = scan['signalStrength'];
      final frequency = scan['frequency'];
      final ageMillis = scan['ageMillis'];
      if (bssid is! String ||
          ssid is! String ||
          signalStrength is! num ||
          frequency is! num ||
          ageMillis is! num) {
        continue;
      }
      if (ssid.isEmpty || ssid.toLowerCase().endsWith('_nomap')) continue;
      if (!_isPublicUnicastBssid(bssid)) continue;
      if (ageMillis < 0 || ageMillis > _maximumScanAgeMillis) continue;

      final normalizedBssid = bssid.toLowerCase().replaceAll('-', ':');
      final accessPoint = WifiAccessPoint(
        bssid: normalizedBssid,
        signalStrength: signalStrength.toInt(),
        frequency: frequency.toInt(),
        ageMillis: ageMillis.toInt(),
      );
      final previous = strongestByBssid[normalizedBssid];
      if (previous == null ||
          accessPoint.signalStrength > previous.signalStrength) {
        strongestByBssid[normalizedBssid] = accessPoint;
      }
    }

    final selected = strongestByBssid.values.toList()
      ..sort((a, b) => b.signalStrength.compareTo(a.signalStrength));
    return selected.take(_maximumAccessPoints).toList();
  }

  static bool _isPublicUnicastBssid(String value) {
    final normalized = value.replaceAll('-', ':');
    if (!RegExp(r'^[0-9a-fA-F]{2}(:[0-9a-fA-F]{2}){5}$').hasMatch(normalized)) {
      return false;
    }
    final firstOctet = int.parse(normalized.substring(0, 2), radix: 16);
    // Reject multicast and locally administered (usually randomized) MACs.
    return firstOctet & 0x03 == 0;
  }

  static Future<List<Map<Object?, Object?>>> _scanWithPlatformChannel() async {
    final scans = await _channel.invokeMethod<List<dynamic>>(
      'getWifiScanResults',
    );
    if (scans == null) return const [];
    return scans
        .whereType<Map<Object?, Object?>>()
        .map((scan) => Map<Object?, Object?>.from(scan))
        .toList();
  }

  void dispose() {
    _client.close();
  }
}
