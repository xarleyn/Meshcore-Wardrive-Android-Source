import '../models/models.dart';

enum SessionMapScope { all, session, empty }

class SessionMapView {
  final SessionMapScope scope;
  final WSession? session;

  const SessionMapView._(this.scope, this.session);

  const SessionMapView.all() : this._(SessionMapScope.all, null);

  const SessionMapView.empty() : this._(SessionMapScope.empty, null);

  const SessionMapView.session(WSession session)
    : this._(SessionMapScope.session, session);

  bool get isFiltered => scope != SessionMapScope.all;

  static bool isEmptySession(int gpsSampleCount) => gpsSampleCount == 0;

  List<Sample> visibleSamples(List<Sample> samples, {DateTime? now}) {
    switch (scope) {
      case SessionMapScope.all:
        return samples;
      case SessionMapScope.empty:
        return const [];
      case SessionMapScope.session:
        final selected = session;
        if (selected == null) return const [];
        final start = selected.startTime;
        final end = selected.endTime ?? now ?? DateTime.now();
        return samples
            .where(
              (s) =>
                  s.timestamp.isAfter(
                    start.subtract(const Duration(seconds: 1)),
                  ) &&
                  s.timestamp.isBefore(end.add(const Duration(seconds: 1))),
            )
            .toList();
    }
  }

  SessionMapView afterShortPressStart() => const SessionMapView.all();

  SessionMapView afterFreshStart(WSession newSession) =>
      SessionMapView.session(newSession);

  SessionMapView afterDiscardingEmpty(List<WSession> remainingNewestFirst) =>
      lastSavedOrEmpty(remainingNewestFirst);

  SessionMapView afterDeletingSession({
    required int deletedId,
    required List<WSession> remainingNewestFirst,
  }) {
    if (scope != SessionMapScope.session || session?.id != deletedId) {
      return this;
    }
    return lastSavedOrEmpty(remainingNewestFirst);
  }

  SessionMapView afterStopWithSamples(WSession finalized) {
    if (scope != SessionMapScope.session) return this;
    return SessionMapView.session(finalized);
  }

  static SessionMapView lastSavedOrEmpty(List<WSession> remainingNewestFirst) {
    if (remainingNewestFirst.isEmpty) return const SessionMapView.empty();
    return SessionMapView.session(remainingNewestFirst.first);
  }
}
