import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';

typedef InternetProbe = Future<bool> Function(Duration timeout);

enum InternetStatus { checking, online, offline }

/// Periodically verifies that the device can reach the public internet.
///
/// This intentionally performs a real HTTP request instead of only checking
/// whether Wi-Fi or mobile data is enabled. A connected network can still be
/// unable to reach the internet, for example when a carrier allowlist is in
/// effect.
class InternetConnectivityService extends ChangeNotifier
    with WidgetsBindingObserver {
  InternetConnectivityService({
    InternetProbe? probe,
    this.checkInterval = const Duration(seconds: 20),
    this.probeTimeout = const Duration(seconds: 3),
  }) : _probe = probe ?? _defaultProbe;

  static final Uri _probeUri = Uri.parse(
    'https://connectivitycheck.gstatic.com/generate_204',
  );

  final InternetProbe _probe;
  final Duration checkInterval;
  final Duration probeTimeout;

  Timer? _timer;
  bool _started = false;
  bool _disposed = false;
  bool _checkInProgress = false;
  InternetStatus _status = InternetStatus.checking;

  InternetStatus get status => _status;
  bool get isOffline => _status == InternetStatus.offline;

  void start() {
    if (_started || _disposed) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    unawaited(checkNow());
    _timer = Timer.periodic(checkInterval, (_) => unawaited(checkNow()));
  }

  Future<void> checkNow() async {
    if (_checkInProgress) return;
    _checkInProgress = true;

    var isOnline = false;
    try {
      isOnline = await _probe(probeTimeout).timeout(probeTimeout);
    } catch (_) {
      isOnline = false;
    } finally {
      _checkInProgress = false;
    }

    if (_disposed) return;

    final nextStatus = isOnline
        ? InternetStatus.online
        : InternetStatus.offline;
    if (_status != nextStatus) {
      _status = nextStatus;
      notifyListeners();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(checkNow());
    }
  }

  void stop() {
    if (!_started) return;
    _started = false;
    _timer?.cancel();
    _timer = null;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void dispose() {
    _disposed = true;
    stop();
    super.dispose();
  }

  static Future<bool> _defaultProbe(Duration timeout) async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      return await (() async {
        final request = await client.getUrl(_probeUri);
        request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
        final response = await request.close();
        await response.drain<void>();
        return response.statusCode == HttpStatus.noContent;
      })().timeout(timeout);
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }
}
