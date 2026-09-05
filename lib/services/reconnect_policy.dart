import 'dart:math';

/// Exponential backoff policy for automatic LoRa reconnect attempts.
///
/// Attempt numbering is 1-based: the first retry waits [initialDelay], every
/// following attempt doubles the wait until [maxDelay] is reached.
class ReconnectBackoff {
  final Duration initialDelay;
  final Duration maxDelay;

  const ReconnectBackoff({
    this.initialDelay = const Duration(seconds: 3),
    this.maxDelay = const Duration(seconds: 60),
  });

  /// Wait time before retry [attempt]; capped at [maxDelay].
  Duration delayForAttempt(int attempt) {
    var delay = initialDelay;
    for (var i = 1; i < max(1, attempt); i++) {
      delay *= 2;
      if (delay >= maxDelay) return maxDelay;
    }
    return delay > maxDelay ? maxDelay : delay;
  }
}

/// Snapshot of the automatic reconnection loop for UI and logging listeners.
class ReconnectStatus {
  /// Whether the service is trying to restore a lost connection.
  final bool active;

  /// 1-based number of the upcoming attempt; 0 when inactive.
  final int nextAttempt;

  /// Human-readable name of the device being restored.
  final String? deviceName;

  /// Set on the final event when the link was restored automatically.
  final bool restored;

  const ReconnectStatus({
    required this.active,
    this.nextAttempt = 0,
    this.deviceName,
    this.restored = false,
  });
}
