/// Outcome of one discovery ping.
enum PingStatus { success, failed, timeout, pending }

/// One repeater response heard during a discovery ping.
class PingResponse {
  final String nodeId;
  final int rssi;
  final int snr;
  final int? responseTimeMs;

  const PingResponse({
    required this.nodeId,
    required this.rssi,
    required this.snr,
    this.responseTimeMs,
  });

  Map<String, dynamic> toJson() => {
    'nodeId': nodeId,
    'rssi': rssi,
    'snr': snr,
    'responseTimeMs': responseTimeMs,
  };
}

/// Aggregate result of a discovery ping with all collected responses.
class PingResult {
  final DateTime timestamp;
  final PingStatus status;
  final int? rssi;
  final int? snr;
  final String? nodeId;
  final double? latitude;
  final double? longitude;
  final String? error;
  final int? responseTimeMs;
  final List<PingResponse> responses;

  PingResult({
    required this.timestamp,
    required this.status,
    this.rssi,
    this.snr,
    this.nodeId,
    this.latitude,
    this.longitude,
    this.error,
    this.responseTimeMs,
    List<PingResponse> responses = const [],
  }) : responses = List.unmodifiable(responses);

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'status': status.name,
    'rssi': rssi,
    'snr': snr,
    'nodeId': nodeId,
    'latitude': latitude,
    'longitude': longitude,
    'error': error,
    'responseTimeMs': responseTimeMs,
    'responses': responses.map((response) => response.toJson()).toList(),
  };
}
