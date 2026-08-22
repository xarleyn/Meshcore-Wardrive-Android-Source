import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_wardrive/models/models.dart';
import 'package:meshcore_wardrive/utils/session_map_view.dart';

void main() {
  final older = WSession(
    id: 1,
    startTime: DateTime.utc(2026, 8, 1, 10),
    endTime: DateTime.utc(2026, 8, 1, 12),
  );
  final newer = WSession(
    id: 2,
    startTime: DateTime.utc(2026, 8, 2, 10),
    endTime: DateTime.utc(2026, 8, 2, 12),
  );
  final current = WSession(id: 3, startTime: DateTime.utc(2026, 8, 19, 10));

  Sample sampleAt(DateTime timestamp) => Sample(
    id: timestamp.toIso8601String(),
    position: const LatLng(55.75, 37.62),
    timestamp: timestamp,
    geohash: 'ucftpv12',
  );

  group('SessionMapView.visibleSamples', () {
    final before = sampleAt(DateTime.utc(2026, 8, 18, 9));
    final during = sampleAt(DateTime.utc(2026, 8, 19, 11));
    final after = sampleAt(DateTime.utc(2026, 8, 19, 13));
    final samples = [before, during, after];

    test('all scope returns every sample', () {
      const view = SessionMapView.all();
      expect(view.visibleSamples(samples), samples);
    });

    test('empty scope returns no samples', () {
      const view = SessionMapView.empty();
      expect(view.visibleSamples(samples), isEmpty);
    });

    test('session scope keeps samples inside the time range', () {
      final view = SessionMapView.session(
        WSession(
          id: 3,
          startTime: DateTime.utc(2026, 8, 19, 10),
          endTime: DateTime.utc(2026, 8, 19, 12),
        ),
      );

      expect(view.visibleSamples(samples), [during]);
    });

    test('in-progress session uses now as the end bound', () {
      final view = SessionMapView.session(current);
      final now = DateTime.utc(2026, 8, 19, 11, 30);

      expect(view.visibleSamples(samples, now: now), [during]);
    });
  });

  group('SessionMapView transitions', () {
    test('short-press start always switches to all samples', () {
      final filtered = SessionMapView.session(newer);
      expect(filtered.afterShortPressStart().scope, SessionMapScope.all);
      expect(
        const SessionMapView.empty().afterShortPressStart().scope,
        SessionMapScope.all,
      );
    });

    test('fresh start isolates the new session', () {
      final view = const SessionMapView.all().afterFreshStart(current);
      expect(view.scope, SessionMapScope.session);
      expect(view.session, current);
    });

    test('discarding an empty session shows the newest remaining session', () {
      final view = SessionMapView.session(current);
      final next = view.afterDiscardingEmpty([newer, older]);
      expect(next.scope, SessionMapScope.session);
      expect(next.session?.id, newer.id);
    });

    test('discarding the last empty session shows an empty map', () {
      final view = SessionMapView.session(current);
      expect(view.afterDiscardingEmpty(const []).scope, SessionMapScope.empty);
    });

    test('deleting the active session falls back to the newest remaining', () {
      final view = SessionMapView.session(newer);
      final next = view.afterDeletingSession(
        deletedId: newer.id!,
        remainingNewestFirst: [older],
      );
      expect(next.session?.id, older.id);
    });

    test('deleting the last remaining session shows an empty map', () {
      final view = SessionMapView.session(older);
      expect(
        view
            .afterDeletingSession(
              deletedId: older.id!,
              remainingNewestFirst: const [],
            )
            .scope,
        SessionMapScope.empty,
      );
    });

    test('deleting a different session leaves the current view unchanged', () {
      final view = SessionMapView.session(newer);
      final next = view.afterDeletingSession(
        deletedId: older.id!,
        remainingNewestFirst: [newer],
      );
      expect(next.session?.id, newer.id);
    });

    test('deleting a session while showing all samples leaves all samples', () {
      const view = SessionMapView.all();
      final next = view.afterDeletingSession(
        deletedId: newer.id!,
        remainingNewestFirst: [older],
      );
      expect(next.scope, SessionMapScope.all);
    });

    test('stopping with samples keeps an isolated session up to date', () {
      final finalized = WSession(
        id: current.id,
        startTime: current.startTime,
        endTime: DateTime.utc(2026, 8, 19, 12),
        sampleCount: 4,
      );
      final next = SessionMapView.session(current)
          .afterStopWithSamples(finalized);
      expect(next.session?.endTime, finalized.endTime);
      expect(next.session?.sampleCount, 4);
    });

    test('stopping with samples while showing all stays on all', () {
      final finalized = WSession(
        id: 9,
        startTime: DateTime.utc(2026, 8, 19, 10),
        endTime: DateTime.utc(2026, 8, 19, 11),
        sampleCount: 2,
      );
      expect(
        const SessionMapView.all().afterStopWithSamples(finalized).scope,
        SessionMapScope.all,
      );
    });
  });

  test('a session is empty only when it has no GPS samples', () {
    expect(SessionMapView.isEmptySession(0), isTrue);
    expect(SessionMapView.isEmptySession(1), isFalse);
  });
}
