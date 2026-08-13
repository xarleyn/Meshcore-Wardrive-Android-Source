import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/services/lora_companion_service.dart';

void main() {
  group('PingResponseTracker', () {
    final sentAt = DateTime.utc(2026, 8, 13, 12);

    test('completes on the first response with its actual latency', () async {
      final tracker = PingResponseTracker(
        sentAt: sentAt,
        latitude: 55.75,
        longitude: 37.62,
      );

      final update = tracker.addResponse(
        const PingResponse(nodeId: 'AABBCCDD', rssi: -83, snr: 6),
        sentAt.add(const Duration(milliseconds: 125)),
      );
      final result = await tracker.result;

      expect(update, same(result));
      expect(result.status, PingStatus.success);
      expect(result.nodeId, 'AABBCCDD');
      expect(result.responseTimeMs, 125);
      expect(result.responses, hasLength(1));
    });

    test(
      'accepts a first response after the old three-second boundary',
      () async {
        final tracker = PingResponseTracker(
          sentAt: sentAt,
          latitude: 55.75,
          longitude: 37.62,
        );

        tracker.addResponse(
          const PingResponse(nodeId: 'AABBCCDD', rssi: -90, snr: 2),
          sentAt.add(const Duration(milliseconds: 3100)),
        );
        final result = await tracker.result;

        expect(result.status, PingStatus.success);
        expect(result.responseTimeMs, 3100);
      },
    );

    test(
      'streams a stronger aggregate without changing first-response time',
      () async {
        final tracker = PingResponseTracker(
          sentAt: sentAt,
          latitude: 55.75,
          longitude: 37.62,
        );

        tracker.addResponse(
          const PingResponse(nodeId: 'FIRST', rssi: -95, snr: 1),
          sentAt.add(const Duration(milliseconds: 140)),
        );
        final firstResult = await tracker.result;
        final aggregate = tracker.addResponse(
          const PingResponse(nodeId: 'STRONGER', rssi: -70, snr: 9),
          sentAt.add(const Duration(milliseconds: 900)),
        );

        expect(firstResult.nodeId, 'FIRST');
        expect(firstResult.responses, hasLength(1));
        expect(aggregate?.nodeId, 'STRONGER');
        expect(aggregate?.responseTimeMs, 140);
        expect(aggregate?.responses, hasLength(2));
      },
    );

    test(
      'completes collection with every unique response and latency',
      () async {
        final tracker = PingResponseTracker(
          sentAt: sentAt,
          latitude: 55.75,
          longitude: 37.62,
        );

        tracker.addResponse(
          const PingResponse(nodeId: 'FIRST', rssi: -90, snr: 2),
          sentAt.add(const Duration(milliseconds: 120)),
        );
        tracker.addResponse(
          const PingResponse(nodeId: 'SECOND', rssi: -75, snr: 8),
          sentAt.add(const Duration(milliseconds: 640)),
        );
        tracker.close(sentAt.add(const Duration(seconds: 3)));

        final result = await tracker.collectedResult;
        expect(result.responses.map((response) => response.nodeId), [
          'SECOND',
          'FIRST',
        ]);
        expect(result.responses.first.responseTimeMs, 640);
        expect(result.responses.last.responseTimeMs, 120);
        expect(result.responseTimeMs, 120);
      },
    );

    test('ignores a weaker duplicate from the same repeater', () {
      final tracker = PingResponseTracker(
        sentAt: sentAt,
        latitude: 55.75,
        longitude: 37.62,
      );

      tracker.addResponse(
        const PingResponse(nodeId: 'AABBCCDD', rssi: -80, snr: 5),
        sentAt.add(const Duration(milliseconds: 100)),
      );
      final duplicate = tracker.addResponse(
        const PingResponse(nodeId: 'AABBCCDD', rssi: -95, snr: 1),
        sentAt.add(const Duration(milliseconds: 200)),
      );

      expect(duplicate, isNull);
      expect(tracker.responses.single.rssi, -80);
    });

    test('completes as a timeout only when no response arrived', () async {
      final tracker = PingResponseTracker(
        sentAt: sentAt,
        latitude: 55.75,
        longitude: 37.62,
      );

      final update = tracker.timeout(sentAt.add(const Duration(seconds: 10)));
      final result = await tracker.result;

      expect(update, same(result));
      expect(result.status, PingStatus.timeout);
      expect(result.responseTimeMs, 10000);
      expect(tracker.isAcceptingResponses, isFalse);
      expect(
        tracker.addResponse(
          const PingResponse(nodeId: 'LATE', rssi: -80, snr: 5),
          sentAt.add(const Duration(seconds: 11)),
        ),
        isNull,
      );
    });
  });
}
