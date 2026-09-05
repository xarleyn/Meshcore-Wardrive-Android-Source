import 'dart:async';
import 'dart:math';

import '../models/ping_result.dart';

/// Tracks one discovery ping from transmission through its first response.
///
/// The first response completes [result] immediately. Further responses can
/// still be recorded for a short collection window so radio positioning can
/// use more than one repeater without delaying user feedback.
class PingResponseTracker {
  PingResponseTracker({
    required this.sentAt,
    required this.latitude,
    required this.longitude,
    this.collectUntilTimeout = false,
  });

  final DateTime sentAt;
  final double latitude;
  final double longitude;
  final bool collectUntilTimeout;
  final Completer<PingResult> _completer = Completer<PingResult>();
  final Completer<PingResult> _collectionCompleter = Completer<PingResult>();
  final List<PingResponse> _responses = [];

  bool _acceptingResponses = true;
  int? _firstResponseTimeMs;

  Future<PingResult> get result => _completer.future;
  Future<PingResult> get collectedResult => _collectionCompleter.future;
  bool get isAcceptingResponses => _acceptingResponses;
  bool get hasResponse => _firstResponseTimeMs != null;
  List<PingResponse> get responses => List.unmodifiable(_responses);

  /// Records a response and returns a fresh aggregate result when it changes.
  /// Returns null for a closed tracker or a weaker duplicate response.
  PingResult? addResponse(PingResponse response, DateTime receivedAt) {
    if (!_acceptingResponses) return null;

    final responseTimeMs = max(0, receivedAt.difference(sentAt).inMilliseconds);
    final timedResponse = PingResponse(
      nodeId: response.nodeId,
      rssi: response.rssi,
      snr: response.snr,
      responseTimeMs: response.responseTimeMs ?? responseTimeMs,
    );

    final existingIndex = _responses.indexWhere(
      (existing) => existing.nodeId == timedResponse.nodeId,
    );
    if (existingIndex == -1) {
      _responses.add(timedResponse);
    } else if (timedResponse.rssi > _responses[existingIndex].rssi) {
      _responses[existingIndex] = timedResponse;
    } else {
      return null;
    }

    _firstResponseTimeMs ??= responseTimeMs;
    final pingResult = _successResult(receivedAt);
    if (!_completer.isCompleted) {
      _completer.complete(pingResult);
    }
    return pingResult;
  }

  PingResult? timeout(DateTime timedOutAt) {
    if (!_acceptingResponses || _completer.isCompleted) return null;
    _acceptingResponses = false;
    final pingResult = PingResult(
      timestamp: timedOutAt,
      status: PingStatus.timeout,
      latitude: latitude,
      longitude: longitude,
      error: 'No repeaters in range - dead zone',
      responseTimeMs: max(0, timedOutAt.difference(sentAt).inMilliseconds),
    );
    _completer.complete(pingResult);
    _collectionCompleter.complete(pingResult);
    return pingResult;
  }

  PingResult? fail(DateTime failedAt, String error) {
    if (_completer.isCompleted) {
      close(failedAt);
      return null;
    }
    _acceptingResponses = false;
    final pingResult = PingResult(
      timestamp: failedAt,
      status: PingStatus.failed,
      latitude: latitude,
      longitude: longitude,
      error: error,
    );
    _completer.complete(pingResult);
    _collectionCompleter.complete(pingResult);
    return pingResult;
  }

  PingResult? close(DateTime closedAt) {
    if (!_acceptingResponses) return null;
    _acceptingResponses = false;
    if (_responses.isEmpty) return null;

    final pingResult = _successResult(closedAt);
    if (!_completer.isCompleted) {
      _completer.complete(pingResult);
    }
    if (!_collectionCompleter.isCompleted) {
      _collectionCompleter.complete(pingResult);
    }
    return pingResult;
  }

  PingResult _successResult(DateTime receivedAt) {
    final sortedResponses = List<PingResponse>.of(_responses)
      ..sort((a, b) => b.snr.compareTo(a.snr));
    final best = sortedResponses.first;
    return PingResult(
      timestamp: receivedAt,
      status: PingStatus.success,
      rssi: best.rssi,
      snr: best.snr,
      nodeId: best.nodeId,
      latitude: latitude,
      longitude: longitude,
      responseTimeMs: _firstResponseTimeMs,
      responses: sortedResponses,
    );
  }
}
