import 'dart:math';

import 'package:latlong2/latlong.dart';

import '../models/models.dart';
import '../models/ping_result.dart';

/// A deliberately coarse position inferred from signals received by fixed
/// repeaters. It must never be treated as a replacement for a GPS fix.
class RadioPositionEstimate {
  final LatLng position;
  final double uncertaintyMeters;
  final int repeaterCount;

  const RadioPositionEstimate({
    required this.position,
    required this.uncertaintyMeters,
    required this.repeaterCount,
  });
}

/// Estimates a position using an RSSI-weighted centroid of known repeaters.
///
/// RSSI does not provide a dependable absolute distance outdoors, so this is
/// intentionally not presented as trilateration. Requiring three fixed
/// repeaters and returning a large uncertainty circle keeps the result useful
/// without implying GPS-like precision.
class RadioPositionEstimator {
  static const _distance = Distance();

  static RadioPositionEstimate? estimate({
    required Iterable<PingResponse> responses,
    required Iterable<Repeater> repeaters,
  }) {
    final repeatersById = <String, Repeater>{
      for (final repeater in repeaters)
        if (!_isUnknownPosition(repeater.position))
          repeater.id.toUpperCase(): repeater,
    };

    final strongestByRepeater = <String, PingResponse>{};
    for (final response in responses) {
      final id = response.nodeId.toUpperCase();
      final existing = strongestByRepeater[id];
      if (existing == null || response.rssi > existing.rssi) {
        strongestByRepeater[id] = response;
      }
    }

    final anchors = <({Repeater repeater, PingResponse response})>[];
    for (final entry in strongestByRepeater.entries) {
      final repeater = _findRepeater(entry.key, repeatersById);
      if (repeater != null) {
        anchors.add((repeater: repeater, response: entry.value));
      }
    }

    if (anchors.length < 3) return null;

    final strongestRssi = anchors
        .map((anchor) => anchor.response.rssi)
        .reduce(max);
    var weightSum = 0.0;
    var latitudeSum = 0.0;
    var longitudeX = 0.0;
    var longitudeY = 0.0;

    for (final anchor in anchors) {
      // Relative field strength is less misleading than converting RSSI to an
      // absolute distance. The floor prevents one noisy reading from entirely
      // discarding an otherwise useful anchor.
      final weight = max(
        0.05,
        pow(10, (anchor.response.rssi - strongestRssi) / 20).toDouble(),
      );
      final longitudeRadians = anchor.repeater.position.longitude * pi / 180;
      weightSum += weight;
      latitudeSum += anchor.repeater.position.latitude * weight;
      longitudeX += cos(longitudeRadians) * weight;
      longitudeY += sin(longitudeRadians) * weight;
    }

    final position = LatLng(
      latitudeSum / weightSum,
      atan2(longitudeY, longitudeX) * 180 / pi,
    );

    var weightedSquaredDistance = 0.0;
    for (final anchor in anchors) {
      final weight = max(
        0.05,
        pow(10, (anchor.response.rssi - strongestRssi) / 20).toDouble(),
      );
      final distanceMeters = _distance.as(
        LengthUnit.Meter,
        position,
        anchor.repeater.position,
      );
      weightedSquaredDistance += weight * distanceMeters * distanceMeters;
    }

    // The spread of the anchors is a conservative visualization of how coarse
    // the estimate is. A floor avoids showing a deceptively precise dot when
    // repeaters are clustered together.
    final uncertaintyMeters = max(
      250.0,
      sqrt(weightedSquaredDistance / weightSum),
    );

    return RadioPositionEstimate(
      position: position,
      uncertaintyMeters: uncertaintyMeters,
      repeaterCount: anchors.length,
    );
  }

  static Repeater? _findRepeater(
    String responseId,
    Map<String, Repeater> repeatersById,
  ) {
    final exact = repeatersById[responseId];
    if (exact != null) return exact;

    // Eight hexadecimal characters are the stable prefix used by discovery
    // replies. Shorter prefixes are too ambiguous for positioning.
    if (responseId.length < 8) return null;

    for (final entry in repeatersById.entries) {
      final shorterLength = min(entry.key.length, responseId.length);
      if (shorterLength >= 8 &&
          entry.key.substring(0, shorterLength) ==
              responseId.substring(0, shorterLength)) {
        return entry.value;
      }
    }
    return null;
  }

  static bool _isUnknownPosition(LatLng position) =>
      position.latitude == 0 && position.longitude == 0;
}
