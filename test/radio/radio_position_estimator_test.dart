import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_wardrive/models/models.dart';
import 'package:meshcore_wardrive/models/ping_result.dart';
import 'package:meshcore_wardrive/services/radio_position_estimator.dart';

void main() {
  group('RadioPositionEstimator', () {
    test('requires responses from at least three positioned repeaters', () {
      final estimate = RadioPositionEstimator.estimate(
        responses: const [
          PingResponse(nodeId: 'A', rssi: -80, snr: 5),
          PingResponse(nodeId: 'B', rssi: -82, snr: 4),
        ],
        repeaters: [_repeater('A', 55.0, 37.0), _repeater('B', 55.01, 37.0)],
      );

      expect(estimate, isNull);
    });

    test('places equal-strength signals near the anchor centroid', () {
      final estimate = RadioPositionEstimator.estimate(
        responses: const [
          PingResponse(nodeId: 'A', rssi: -80, snr: 5),
          PingResponse(nodeId: 'B', rssi: -80, snr: 5),
          PingResponse(nodeId: 'C', rssi: -80, snr: 5),
        ],
        repeaters: [
          _repeater('A', 55.0, 37.0),
          _repeater('B', 55.0, 37.03),
          _repeater('C', 55.03, 37.0),
        ],
      );

      expect(estimate, isNotNull);
      expect(estimate!.position.latitude, closeTo(55.01, 0.0001));
      expect(estimate.position.longitude, closeTo(37.01, 0.0001));
      expect(estimate.repeaterCount, 3);
      expect(estimate.uncertaintyMeters, greaterThan(1000));
    });

    test('biases the estimate toward the strongest response', () {
      final equalEstimate = RadioPositionEstimator.estimate(
        responses: const [
          PingResponse(nodeId: 'A', rssi: -80, snr: 5),
          PingResponse(nodeId: 'B', rssi: -80, snr: 5),
          PingResponse(nodeId: 'C', rssi: -80, snr: 5),
        ],
        repeaters: [
          _repeater('A', 55.0, 37.0),
          _repeater('B', 55.0, 37.03),
          _repeater('C', 55.03, 37.0),
        ],
      )!;
      final strongEastEstimate = RadioPositionEstimator.estimate(
        responses: const [
          PingResponse(nodeId: 'A', rssi: -100, snr: 0),
          PingResponse(nodeId: 'B', rssi: -60, snr: 10),
          PingResponse(nodeId: 'C', rssi: -100, snr: 0),
        ],
        repeaters: [
          _repeater('A', 55.0, 37.0),
          _repeater('B', 55.0, 37.03),
          _repeater('C', 55.03, 37.0),
        ],
      )!;

      expect(
        strongEastEstimate.position.longitude,
        greaterThan(equalEstimate.position.longitude),
      );
      expect(
        strongEastEstimate.position.latitude,
        lessThan(equalEstimate.position.latitude),
      );
    });

    test('matches short response IDs to longer repeater IDs', () {
      final estimate = RadioPositionEstimator.estimate(
        responses: const [
          PingResponse(nodeId: 'AA001122', rssi: -80, snr: 5),
          PingResponse(nodeId: 'BB001122', rssi: -80, snr: 5),
          PingResponse(nodeId: 'CC001122', rssi: -80, snr: 5),
        ],
        repeaters: [
          _repeater('AA0011223344', 55.0, 37.0),
          _repeater('BB0011223344', 55.0, 37.03),
          _repeater('CC0011223344', 55.03, 37.0),
        ],
      );

      expect(estimate?.repeaterCount, 3);
    });
  });
}

Repeater _repeater(String id, double latitude, double longitude) =>
    Repeater(id: id, position: LatLng(latitude, longitude));
