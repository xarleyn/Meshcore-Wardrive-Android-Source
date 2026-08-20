import 'dart:async';

enum MapRuntimeSubscription {
  battery,
  radioPosition,
  carpeater,
  position,
  positionSource,
  course,
  compass,
  sampleSaved,
  pingEvent,
  newRepeater,
  deadZone,
  batterySaver,
  achievement,
  distance,
  speed,
}

enum MapRuntimeTimer { radioPositionExpiry, headingUpdate, pingPulse }

class MapRuntimeBindings {
  final Map<MapRuntimeSubscription, StreamSubscription<dynamic>>
  _subscriptions = {};
  final Map<MapRuntimeTimer, Timer> _timers = {};
  bool _disposed = false;

  bool get isDisposed => _disposed;

  void bind<T>(
    MapRuntimeSubscription key,
    Stream<T> stream,
    void Function(T value) onData, {
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    if (_disposed) return;
    cancelSubscription(key);
    _subscriptions[key] = stream.listen(
      (value) {
        if (!_disposed) onData(value);
      },
      onError: onError == null
          ? null
          : (Object error, StackTrace stackTrace) {
              if (!_disposed) onError(error, stackTrace);
            },
    );
  }

  void cancelSubscription(MapRuntimeSubscription key) {
    final subscription = _subscriptions.remove(key);
    if (subscription != null) unawaited(subscription.cancel());
  }

  bool hasActiveTimer(MapRuntimeTimer key) => _timers[key]?.isActive ?? false;

  bool scheduleTimer(
    MapRuntimeTimer key,
    Duration duration,
    void Function() callback, {
    bool replace = true,
  }) {
    if (_disposed) return false;
    final existing = _timers[key];
    if (!replace && (existing?.isActive ?? false)) return false;
    existing?.cancel();

    late final Timer timer;
    timer = Timer(duration, () {
      if (identical(_timers[key], timer)) _timers.remove(key);
      if (!_disposed) callback();
    });
    _timers[key] = timer;
    return true;
  }

  void cancelTimer(MapRuntimeTimer key) {
    _timers.remove(key)?.cancel();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    for (final subscription in _subscriptions.values) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
  }
}
