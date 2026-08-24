import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:latlong2/latlong.dart';
import 'package:pointycastle/export.dart';
import 'package:usb_serial/usb_serial.dart';

import 'debug_log_service.dart';
import 'meshcore_protocol.dart';
import 'settings_service.dart';
import '../models/models.dart';
import '../utils/bluetooth_scan.dart';
import '../utils/repeater_contacts.dart';

const String _meshCoreServiceUuid = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
const String _meshCoreRxUuid = '6e400002-b5a3-f393-e0a9-e50e24dcca9e';
const String _meshCoreTxUuid = '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

enum ConnectionType { usb, bluetooth, none }

enum PingStatus { success, failed, timeout, pending }

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

/// Finds the remembered USB device among the currently attached devices.
///
/// Android reassigns `deviceId` on every replug, so matching relies on stable
/// attributes instead: serial number plus VID/PID first, then the interface
/// path (`deviceName`), then bare VID/PID.
UsbDevice? matchUsbDevice(List<UsbDevice> attached, UsbDevice remembered) {
  bool sameVidPid(UsbDevice device) =>
      device.vid == remembered.vid && device.pid == remembered.pid;

  final rememberedSerial = remembered.serial;
  if (rememberedSerial != null && rememberedSerial.isNotEmpty) {
    for (final device in attached) {
      if (sameVidPid(device) && device.serial == rememberedSerial) {
        return device;
      }
    }
  }
  for (final device in attached) {
    if (sameVidPid(device) && device.deviceName == remembered.deviceName) {
      return device;
    }
  }
  for (final device in attached) {
    if (sameVidPid(device)) return device;
  }
  return null;
}

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

class LoRaCompanionService {
  // LoRa device connection
  ConnectionType _connectionType = ConnectionType.none;
  BluetoothDevice? _bluetoothDevice;
  BluetoothCharacteristic? _txCharacteristic;
  BluetoothCharacteristic? _rxCharacteristic;
  UsbPort? _usbPort;
  StreamSubscription? _deviceSubscription;
  String? _deviceName; // Connected device's advertised name
  String? _nodeAdvertName; // Device's own MeshCore advert name (SELF_INFO)

  // State
  final _pingResultController = StreamController<PingResult>.broadcast();
  static const _pingResponseCollectionWindow = Duration(seconds: 3);
  final _pendingPings = <int, PingResponseTracker>{};
  final _pingTimeoutTimers = <int, Timer>{};
  final _pingCollectionTimers = <int, Timer>{};
  bool _startingPing = false;
  final _random = Random();
  int? _batteryPercent;
  final _batteryController = StreamController<int?>.broadcast();
  StreamSubscription? _connectionStateSubscription;

  // Automatic reconnection after an unexpected connection loss. A connection
  // dropped by the user (disconnectDevice) is never restored automatically.
  static const ReconnectBackoff _reconnectBackoff = ReconnectBackoff();
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _autoReconnectActive = false;
  bool _connectInFlight = false;

  // Settled tail of the serialized explicit-connect queue. A manual connect
  // waits behind an in-flight background reconnection attempt instead of
  // failing outright while that attempt holds the link busy.
  Future<bool>? _connectChainTail;

  bool _userDisconnectRequested = false;
  String? _lastBluetoothRemoteId;
  String? _lastBluetoothName;
  UsbDevice? _lastUsbDevice;
  final _reconnectStateController =
      StreamController<ReconnectStatus>.broadcast();

  /// Emits after every successfully established device connection - initial,
  /// manual, or automatic.
  final _connectedController = StreamController<void>.broadcast();

  // Connected device identity for sample tagging
  String? _connectedDeviceId; // Stable ID for the connected LoRa companion
  String? get connectedDeviceId => _connectedDeviceId;

  // Track pending contact requests
  final Set<String> _pendingContactRequests = {};

  // Repeater scanning
  final List<Repeater> _discoveredRepeaters =
      []; // Repeaters that have echoed during wardriving
  final Map<String, Repeater> _repeaterContactCache =
      {}; // All known repeater contacts (from scan)
  final Map<String, int> _nodeTypes =
      {}; // Map of node ID -> advType (1=companion, 2=repeater, 3=room)
  Completer<List<Repeater>>? _scanCompleter;
  final Map<String, Repeater> _knownRepeaters =
      {}; // Map of repeater ID -> location from internet map
  // Advertised names of every repeater/room-server contact ever parsed
  // (ID -> advName), including contacts without a known GPS position.
  final Map<String, String> _repeaterContactNames = {};

  // Throttle contact lookups to avoid dumping full list repeatedly
  final Map<String, DateTime> _lastContactRequestAt = {}; // keyPrefix -> time
  final Duration _contactRequestCooldown = const Duration(minutes: 5);

  // Carpeater: cache full 32-byte public keys by prefix (populated from contact frames)
  final Map<String, Uint8List> _contactPubKeyCache = {};
  // Carpeater: callback receives (pushCode, frameData) for login + binary responses
  void Function(int pushCode, Uint8List data)? _carpeaterPayloadCallback;

  // Settings
  String? _ignoredRepeaterPrefix;

  // Track known repeater IDs for new discovery alerts (populated from DB on connect)
  final Set<String> _knownRepeaterIds = {};
  final _newRepeaterController = StreamController<String>.broadcast();
  Stream<String> get newRepeaterStream => _newRepeaterController.stream;
  bool _newRepeaterAlertsEnabled = true;

  /// Load known repeater IDs from the database so only truly new ones trigger alerts
  Future<void> loadKnownRepeaterIds(Set<String> ids) async {
    _knownRepeaterIds.addAll(ids);
    _debugLog.logInfo('Loaded ${ids.length} known repeater IDs from DB');
  }

  /// Set whether new repeater alerts are enabled
  void setNewRepeaterAlertsEnabled(bool enabled) {
    _newRepeaterAlertsEnabled = enabled;
  }

  // Secure storage
  final _secureStorage = const FlutterSecureStorage();
  final _debugLog = DebugLogService();
  final _protocol = MeshCoreProtocol();

  bool get isDeviceConnected => _connectionType != ConnectionType.none;
  bool get isPingInProgress => _startingPing || _pendingPings.isNotEmpty;
  ConnectionType get connectionType => _connectionType;
  String? get deviceName => _deviceName;

  /// The connected device's own MeshCore advert name from SELF_INFO. Unlike
  /// [deviceName] this is not the Bluetooth/USB transport name and not the
  /// public key; it is the node name the radio is known by inside the mesh.
  String? get nodeAdvertName => _nodeAdvertName;
  Stream<PingResult> get pingResults => _pingResultController.stream;
  int? get batteryPercent => _batteryPercent;
  Stream<int?> get batteryStream => _batteryController.stream;

  /// Whether the automatic reconnection loop is engaged after a lost device.
  bool get isAutoReconnecting => _autoReconnectActive;

  /// Number of failed reconnect attempts since the connection was lost.
  int get reconnectAttempts => _reconnectAttempts;

  /// Name of the device the reconnection loop is trying to reach.
  String? get reconnectDeviceName =>
      _lastBluetoothName ??
      _lastUsbDevice?.productName ??
      _lastUsbDevice?.deviceName;

  /// Broadcasts [ReconnectStatus] updates of the automatic reconnection loop.
  Stream<ReconnectStatus> get reconnectStateStream =>
      _reconnectStateController.stream;

  /// Emits once per established device connection, after the protocol
  /// handshake has been sent.
  ///
  /// Unlike [reconnectStateStream] this fires for every connection source,
  /// including a manual connect made while the automatic loop was still
  /// trying, so listeners can resume work that paused on a lost link.
  Stream<void> get connectedStream => _connectedController.stream;

  /// Whether the current (or most recent) teardown was requested by the user
  /// rather than caused by an unexpected link loss.
  bool get userDisconnectRequested => _userDisconnectRequested;

  /// Get the currently ignored repeater prefix
  String? get ignoredRepeaterPrefix => _ignoredRepeaterPrefix;

  /// Set repeater prefixes to ignore (comma-separated, e.g. "7E,A4F,BAD5")
  void setIgnoredRepeaterPrefix(String? prefix) {
    _ignoredRepeaterPrefix = prefix;
  }

  /// Check if a node ID matches any ignored prefix
  bool _isIgnoredRepeater(String nodeId) {
    if (_ignoredRepeaterPrefix == null || _ignoredRepeaterPrefix!.isEmpty) {
      return false;
    }
    final prefixes = _ignoredRepeaterPrefix!
        .split(',')
        .map((s) => s.trim().toUpperCase())
        .where((s) => s.isNotEmpty);
    final upper = nodeId.toUpperCase();
    return prefixes.any((prefix) => upper.startsWith(prefix));
  }

  /// Check if a node ID is a companion device (not a repeater)
  /// Uses cached node type from contact info (advType: 1=companion, 2=repeater, 3=room)
  bool _isCompanionNode(String nodeId) {
    final nodeType = _nodeTypes[nodeId];
    if (nodeType == null) return false; // Unknown type, allow it
    return nodeType == ADV_TYPE_CHAT; // Type 1 = companion/chat device
  }

  /// Get device name for display (from BT device)
  String getDeviceName() {
    if (_bluetoothDevice != null) {
      return _bluetoothDevice!.platformName.isNotEmpty
          ? _bluetoothDevice!.platformName
          : _bluetoothDevice!.remoteId.toString();
    }
    return 'Unknown';
  }

  // ============================================================================
  // DEVICE CONNECTION - BLUETOOTH
  // ============================================================================

  KnownBluetoothDevice _toKnownBluetoothDevice(BluetoothDevice device) {
    return KnownBluetoothDevice(
      remoteId: device.remoteId.toString(),
      name: device.platformName,
    );
  }

  /// Bonded and currently connected companion radios that can appear before a
  /// scan result arrives.
  Future<List<KnownBluetoothDevice>> getBondedCompanionDevices() async {
    try {
      if (await FlutterBluePlus.isSupported == false) return const [];

      final bonded = await FlutterBluePlus.bondedDevices;
      final connected = await FlutterBluePlus.systemDevices([
        Guid(meshCoreNordicUartServiceUuid),
      ]);
      return collectKnownBluetoothDevices(
        recent: const [],
        bonded: [
          for (final device in [...bonded, ...connected])
            if (isLikelyLoRaCompanion(
              name: device.platformName,
              remoteId: device.remoteId.toString(),
            ))
              _toKnownBluetoothDevice(device),
        ],
      );
    } catch (e) {
      debugPrint('Error listing bonded Bluetooth devices: $e');
      return const [];
    }
  }

  /// Emits known devices immediately, then the growing scan list.
  ///
  /// Cancelling the subscription stops the BLE scan.
  Stream<BluetoothScanSnapshot> watchBluetoothScan({
    List<KnownBluetoothDevice> knownDevices = const [],
    Duration timeout = const Duration(seconds: 10),
  }) {
    late final StreamController<BluetoothScanSnapshot> controller;
    StreamSubscription<List<ScanResult>>? resultsSub;
    StreamSubscription<bool>? scanningSub;
    var latest = BluetoothScanSnapshot(
      devices: mergeBluetoothScanResults(
        known: knownDevices,
        discovered: const [],
      ),
      isScanning: true,
    );

    void emit(BluetoothScanSnapshot snapshot) {
      latest = snapshot;
      if (!controller.isClosed) controller.add(snapshot);
    }

    List<DiscoveredBluetoothDevice> toDiscovered(List<ScanResult> results) {
      final devices = <DiscoveredBluetoothDevice>[];
      final seen = <String>{};
      for (final result in results) {
        final name = result.device.platformName.isNotEmpty
            ? result.device.platformName
            : result.advertisementData.advName;
        final remoteId = result.device.remoteId.toString();
        if (!isLikelyLoRaCompanion(
          name: name,
          remoteId: remoteId,
          serviceUuids: result.advertisementData.serviceUuids.map(
            (uuid) => uuid.toString(),
          ),
          knownRemoteIds: knownDevices.map((device) => device.remoteId),
        )) {
          continue;
        }
        if (!seen.add(normalizeBluetoothId(remoteId))) continue;
        devices.add(DiscoveredBluetoothDevice(remoteId: remoteId, name: name));
      }
      return devices;
    }

    controller = StreamController<BluetoothScanSnapshot>(
      onListen: () async {
        emit(latest);
        try {
          if (await FlutterBluePlus.isSupported == false) {
            emit(
              latest.copyWith(
                isScanning: false,
                error: 'Bluetooth not supported',
              ),
            );
            return;
          }

          resultsSub = FlutterBluePlus.scanResults.listen((results) {
            emit(
              BluetoothScanSnapshot(
                devices: mergeBluetoothScanResults(
                  known: knownDevices,
                  discovered: toDiscovered(results),
                ),
                isScanning: FlutterBluePlus.isScanningNow,
                error: latest.error,
              ),
            );
          });
          scanningSub = FlutterBluePlus.isScanning.listen((scanning) {
            emit(latest.copyWith(isScanning: scanning));
          });

          await FlutterBluePlus.startScan(timeout: timeout);
        } catch (e) {
          emit(latest.copyWith(isScanning: false, error: e.toString()));
        }
      },
      onCancel: () async {
        await resultsSub?.cancel();
        await scanningSub?.cancel();
        resultsSub = null;
        scanningSub = null;
        try {
          if (FlutterBluePlus.isScanningNow) {
            await FlutterBluePlus.stopScan();
          }
        } catch (_) {}
      },
    );

    return controller.stream;
  }

  /// Queues [action] behind any in-flight or queued explicit connect.
  ///
  /// A manual connect made while a background reconnection attempt is still
  /// running therefore waits for it instead of failing outright. Ownership
  /// may change while waiting: a user disconnect that arrives meanwhile fails
  /// the queued request, and a link restored by the automatic loop (which
  /// always targets the remembered device) counts as success.
  Future<bool> _serializeConnect(Future<bool> Function() action) {
    final earlier = _connectChainTail;
    late final Future<bool> current;
    current = () async {
      if (earlier != null) {
        try {
          await earlier;
        } catch (_) {}
      }
      if (_userDisconnectRequested) return false;
      if (isDeviceConnected) return true;
      return action();
    }();
    _connectChainTail = current;
    unawaited(
      current.whenComplete(() {
        if (identical(_connectChainTail, current)) {
          _connectChainTail = null;
        }
      }),
    );
    return current;
  }

  /// Connect to LoRa device via Bluetooth (user-initiated).
  ///
  /// Cancels any pending automatic reconnection first so an explicit connect
  /// always supersedes the background loop, and waits behind an in-flight
  /// attempt instead of being rejected while that attempt is running.
  Future<bool> connectBluetooth(BluetoothDevice device) {
    _stopAutoReconnect();
    // An explicit user connect re-arms automatic reconnection for the new
    // session once it is established.
    _userDisconnectRequested = false;
    return _serializeConnect(() => _connectBluetoothDevice(device));
  }

  Future<bool> _connectBluetoothDevice(BluetoothDevice device) async {
    if (_connectInFlight) return false;
    if (isDeviceConnected) {
      _debugLog.logInfo('Connect skipped: a device link already exists');
      return true;
    }
    _connectInFlight = true;
    try {
      try {
        await device.connect(
          license: License.nonprofit,
          timeout: const Duration(seconds: 15),
        );
        _bluetoothDevice = device;

        try {
          await device.requestMtu(512);
        } catch (e) {
          _debugLog.logInfo('BLE MTU negotiation unavailable: $e');
        }

        List<BluetoothService> services = await device.discoverServices();

        // MeshCore uses the Nordic UART service with fixed RX/TX UUIDs.
        for (BluetoothService service in services) {
          if (service.uuid.toString().toLowerCase() == _meshCoreServiceUuid) {
            for (BluetoothCharacteristic char in service.characteristics) {
              final uuid = char.uuid.toString().toLowerCase();
              if (uuid == _meshCoreRxUuid && char.properties.write) {
                _txCharacteristic = char;
              }
              if (uuid == _meshCoreTxUuid && char.properties.notify) {
                _rxCharacteristic = char;
                await char.setNotifyValue(true);
                _deviceSubscription = char.lastValueStream.listen((value) {
                  _handleDeviceData(Uint8List.fromList(value));
                });
              }
            }
          }

          // Try to read battery service (standard BLE Battery Service)
          // UUID: 0x180F (Battery Service), 0x2A19 (Battery Level Characteristic)
          if (service.uuid.toString().toLowerCase() ==
              '0000180f-0000-1000-8000-00805f9b34fb') {
            for (BluetoothCharacteristic char in service.characteristics) {
              if (char.uuid.toString().toLowerCase() ==
                  '00002a19-0000-1000-8000-00805f9b34fb') {
                try {
                  // Store battery characteristic for periodic reading
                  _batteryCharacteristic = char;

                  // Try to read battery level
                  final value = await char.read();
                  if (value.isNotEmpty) {
                    _batteryPercent = value[0];
                    _batteryController.add(_batteryPercent);
                    debugPrint('Battery level: $_batteryPercent%');
                  }

                  // Subscribe to battery updates if supported
                  if (char.properties.notify) {
                    await char.setNotifyValue(true);
                    char.lastValueStream.listen((value) {
                      if (value.isNotEmpty) {
                        _batteryPercent = value[0];
                        _batteryController.add(_batteryPercent);
                        debugPrint('Battery level updated: $_batteryPercent%');
                      }
                    });
                  }
                } catch (e) {
                  debugPrint('Could not read battery level: $e');
                }
              }
            }
          }
        }

        if (_txCharacteristic != null && _rxCharacteristic != null) {
          _connectionType = ConnectionType.bluetooth;
          _deviceName = device.platformName.isNotEmpty
              ? device.platformName
              : device.remoteId.toString();
          _connectedDeviceId = device.remoteId
              .toString()
              .replaceAll(':', '')
              .toUpperCase();
          _onConnectionEstablished(
            bluetoothRemoteId: device.remoteId.toString(),
            bluetoothName: _deviceName,
          );
          debugPrint(
            'Connected to LoRa device via Bluetooth (ID: $_connectedDeviceId)',
          );

          // Monitor connection state for disconnection
          _connectionStateSubscription = device.connectionState.listen((state) {
            debugPrint('Bluetooth connection state: $state');
            if (state == BluetoothConnectionState.disconnected) {
              _handleBluetoothDisconnection();
            }
          });

          // Enable BLE mode in protocol parser (unwrapped frames)
          _protocol.setBLEMode(true);
          _debugLog.logInfo('Protocol set to BLE mode (unwrapped frames)');

          // Start periodic battery check if not already getting updates
          _startBatteryMonitoring();

          // Negotiate the protocol and identify the app.
          await Future.delayed(const Duration(milliseconds: 500));
          await _sendProtocolHandshake();

          // Load full contact list so repeaters appear on the map
          await Future.delayed(const Duration(milliseconds: 150));
          await _requestAllContacts();

          _notifyConnectionEstablished();
          return true;
        }

        return false;
      } catch (e) {
        debugPrint('Bluetooth connection error: $e');
        return false;
      }
    } finally {
      _connectInFlight = false;
    }
  }

  // ============================================================================
  // DEVICE CONNECTION - USB
  // ============================================================================

  /// Scan for USB LoRa devices
  Future<List<UsbDevice>> scanUsbDevices() async {
    try {
      return await UsbSerial.listDevices();
    } catch (e) {
      debugPrint('Error scanning USB: $e');
      return [];
    }
  }

  /// Connect to LoRa device via USB (user-initiated).
  ///
  /// Cancels any pending automatic reconnection first so an explicit connect
  /// always supersedes the background loop, and waits behind an in-flight
  /// attempt instead of being rejected while that attempt is running.
  Future<bool> connectUsb(UsbDevice device) {
    _stopAutoReconnect();
    // An explicit user connect re-arms automatic reconnection for the new
    // session once it is established.
    _userDisconnectRequested = false;
    return _serializeConnect(() => _connectUsbDevice(device));
  }

  Future<bool> _connectUsbDevice(UsbDevice device) async {
    if (_connectInFlight) return false;
    if (isDeviceConnected) {
      _debugLog.logInfo('Connect skipped: a device link already exists');
      return true;
    }
    _connectInFlight = true;
    try {
      try {
        _usbPort = await device.create();
        if (_usbPort == null) return false;

        bool opened = await _usbPort!.open();
        if (!opened) return false;

        await _usbPort!.setDTR(true);
        await _usbPort!.setRTS(true);
        await _usbPort!.setPortParameters(
          115200, // Standard baud rate for Meshtastic
          UsbPort.DATABITS_8,
          UsbPort.STOPBITS_1,
          UsbPort.PARITY_NONE,
        );

        _deviceSubscription = _usbPort!.inputStream?.listen(
          (data) {
            _handleDeviceData(Uint8List.fromList(data));
          },
          onError: (error) {
            debugPrint('⚠️ USB stream error: $error');
            _handleUsbDisconnection();
          },
          onDone: () {
            debugPrint('⚠️ USB stream closed');
            _handleUsbDisconnection();
          },
        );

        _connectionType = ConnectionType.usb;
        // Use USB device product name + vendor ID as stable identifier
        _connectedDeviceId = 'USB_${device.productName ?? 'unknown'}'
            .replaceAll(' ', '_')
            .toUpperCase();
        _deviceName = device.productName ?? 'USB Device';
        _onConnectionEstablished(usbDevice: device);
        debugPrint(
          'Connected to LoRa device via USB (ID: $_connectedDeviceId)',
        );

        // Ensure USB mode in protocol parser (wrapped frames with '>')
        _protocol.setBLEMode(false);
        _debugLog.logInfo('Protocol set to USB mode (wrapped frames)');

        // Negotiate the protocol and identify the app.
        await Future.delayed(const Duration(milliseconds: 500));
        await _sendProtocolHandshake();

        // Load full contact list so repeaters appear on the map
        await Future.delayed(const Duration(milliseconds: 150));
        await _requestAllContacts();

        _notifyConnectionEstablished();
        return true;
      } catch (e) {
        debugPrint('USB connection error: $e');
        return false;
      }
    } finally {
      _connectInFlight = false;
    }
  }

  // ============================================================================
  // MQTT CONNECTION - REMOVED
  // ============================================================================

  // ============================================================================
  // REPEATER SCANNING
  // ============================================================================

  /// Scan for nearby repeaters by requesting all contacts
  /// Loads repeater contacts from the device's contact list
  Future<List<Repeater>> scanForRepeaters({int timeoutSeconds = 5}) async {
    if (!isDeviceConnected) {
      _debugLog.logError('Cannot scan - LoRa device not connected');
      return [];
    }

    try {
      _debugLog.logInfo('🔍 Loading repeater contacts from device...');
      _repeaterContactCache.clear();
      _scanCompleter = Completer<List<Repeater>>();

      // Request all contacts from device
      await _requestAllContacts();

      _debugLog.logInfo('Requested contact list');
      debugPrint('📡 Loading repeater contacts...');

      // Wait for contacts to be loaded
      Timer(Duration(seconds: timeoutSeconds), () {
        if (_scanCompleter != null && !_scanCompleter!.isCompleted) {
          _debugLog.logInfo(
            '✅ Scan complete: Cached ${_repeaterContactCache.length} contact(s)',
          );
          debugPrint(
            '✅ Cached ${_repeaterContactCache.length} repeater contact(s)',
          );
          _scanCompleter!.complete(List.from(_repeaterContactCache.values));
          _scanCompleter = null;
        }
      });

      return await _scanCompleter!.future;
    } catch (e) {
      _debugLog.logError('Repeater scan error: $e');
      return [];
    }
  }

  List<Repeater> get discoveredRepeaters =>
      List.unmodifiable(_discoveredRepeaters);

  /// Previously found repeater contacts: everything synced from the
  /// companion radio's contact list or heard during wardriving. Contacts
  /// without a known position appear as name-only stubs; positioned entries
  /// win and live discoveries win over stale contact data.
  List<Repeater> get knownRepeaterContacts => mergeRepeaterContacts(
    nameOnly: _repeaterContactNames,
    positioned: [..._knownRepeaters.values, ..._discoveredRepeaters],
  );

  /// Match a 2-character hex prefix to full repeater ID(s)
  /// Returns the first matching repeater from known repeaters
  String? matchRepeaterPrefix(String prefix) {
    if (prefix.length != 2) return null;

    final upperPrefix = prefix.toUpperCase();

    // Check known repeaters first
    for (final repeaterId in _knownRepeaters.keys) {
      if (repeaterId.toUpperCase().startsWith(upperPrefix)) {
        return repeaterId;
      }
    }

    // Check contact cache
    for (final repeaterId in _repeaterContactCache.keys) {
      if (repeaterId.toUpperCase().startsWith(upperPrefix)) {
        return repeaterId;
      }
    }

    // Check discovered repeaters
    for (final repeater in _discoveredRepeaters) {
      if (repeater.id.toUpperCase().startsWith(upperPrefix)) {
        return repeater.id;
      }
    }

    return null; // No match found
  }

  /// Get repeater location by ID (from cache or fetch)
  /// If repeaterId is 2 characters, attempt to match it to a full ID first
  Repeater? getRepeaterLocation(String repeaterId) {
    // If it's a 2-char prefix, try to expand it first
    String? fullId = repeaterId;
    if (repeaterId.length == 2) {
      fullId = matchRepeaterPrefix(repeaterId);
      if (fullId == null) return null; // No match found
    }

    return _knownRepeaters[fullId] ?? _repeaterContactCache[fullId];
  }

  // Internet map API methods removed - MQTT dependencies

  /// Parse repeater information from LoRa device output
  void _parseRepeaterLine(String line) {
    try {
      // Skip empty lines and common noise
      if (line.trim().isEmpty || line.length < 5) return;

      // Try to parse node information
      // Common formats:
      // Meshtastic: "Node: !1a2b3c4d Name: Repeater1 Lat: 47.123 Lon: -122.456 SNR: 8.5 dB"
      // MeshCore: Different formats - we'll try to detect patterns

      // Look for hex IDs (common in mesh networks)
      final hexIdMatch = RegExp(r'([0-9a-fA-F]{4,16})').firstMatch(line);

      // Look for coordinates in any format
      double? lat;
      double? lon;

      // Try various coordinate formats
      final patterns = [
        RegExp(
          r'lat[:\s=]*(-?\d+\.\d+)[,\s]+lon[:\s=]*(-?\d+\.\d+)',
          caseSensitive: false,
        ),
        RegExp(r'\(\s*(-?\d+\.\d+)\s*,\s*(-?\d+\.\d+)\s*\)'),
        RegExp(r'(-?\d+\.\d{4,})\s*,\s*(-?\d+\.\d{4,})'),
      ];

      for (final pattern in patterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          lat = double.tryParse(match.group(1)!);
          lon = double.tryParse(match.group(2)!);
          if (lat != null && lon != null) break;
        }
      }

      // If we found coordinates, try to extract other info
      if (lat != null && lon != null) {
        // Use hex ID if found, or generate from line
        String nodeId = hexIdMatch?.group(1) ?? line.hashCode.toRadixString(16);

        // Try to extract name
        String? name;
        final namePatterns = [
          RegExp(r'[Nn]ame[:\s]+([A-Za-z0-9_-]+)'),
          RegExp(r'!\w+\s+([A-Za-z0-9_-]+)'),
        ];

        for (final pattern in namePatterns) {
          final match = pattern.firstMatch(line);
          if (match != null) {
            name = match.group(1);
            break;
          }
        }

        // Extract SNR
        int? snr;
        final snrMatch = RegExp(r'[Ss][Nn][Rr][:\s=]*(-?\d+(?:\.\d+)?)')
            .firstMatch(line);
        if (snrMatch != null) {
          snr = double.tryParse(snrMatch.group(1)!)?.toInt();
        }

        // Extract RSSI
        int? rssi;
        final rssiMatch = RegExp(r'[Rr][Ss][Ss][Ii][:\s=]*(-?\d+)')
            .firstMatch(line);
        if (rssiMatch != null) {
          rssi = int.tryParse(rssiMatch.group(1)!);
        }

        final repeater = Repeater(
          id: nodeId,
          position: LatLng(lat, lon),
          name: name,
          snr: snr,
          rssi: rssi,
          timestamp: DateTime.now(),
        );

        // Avoid duplicates based on position (within 10 meters)
        final isDuplicate = _discoveredRepeaters.any(
          (r) =>
              (r.position.latitude - lat!).abs() < 0.0001 &&
              (r.position.longitude - lon!).abs() < 0.0001,
        );

        if (!isDuplicate) {
          _discoveredRepeaters.add(repeater);
          _debugLog.logInfo('✅ Found: ${name ?? nodeId} at ($lat, $lon)');
          debugPrint(
            '✅ Found repeater: ${name ?? nodeId} at ($lat, $lon), SNR: $snr',
          );
        }
      }
    } catch (e) {
      // Don't spam logs with parse errors, just debug output
      debugPrint('Parse error on line: $line - $e');
    }
  }

  // ============================================================================
  // DEVICE INFO
  // ============================================================================

  /// Handle RESP_CODE_SELF_INFO - device information
  void _handleSelfInfo(Uint8List data) {
    final info = _protocol.parseSelfInfoFrame(data);
    if (info == null) {
      _debugLog.logError('Invalid self info response');
      return;
    }
    final name = info['name'] as String?;
    _nodeAdvertName = name;
    _debugLog.logInfo(
      'Received device self info${name == null ? '' : ': $name'}',
    );
    // Persist while the connection is active so achievement checks can
    // inspect the connected node's name without a live radio link.
    unawaited(SettingsService().setCompanionNodeName(name));
  }

  /// Forget the connected device's MeshCore advert name after a disconnect.
  void _forgetNodeAdvertName() {
    _nodeAdvertName = null;
    unawaited(SettingsService().setCompanionNodeName(null));
  }

  void _handleDeviceInfo(Uint8List data) {
    final info = _protocol.parseDeviceInfoFrame(data);
    if (info == null) {
      _debugLog.logError('Invalid device info response');
      return;
    }
    _debugLog.logInfo(
      'MeshCore ${info['firmware_version'] ?? 'firmware'} '
      '(protocol ${info['firmware_protocol']}, '
      '${info['manufacturer'] ?? 'unknown device'})',
    );
  }

  // ============================================================================
  // PING OPERATIONS
  // ============================================================================

  /// Update device position (for proper mesh routing)
  Future<void> _updateDevicePosition(double latitude, double longitude) async {
    try {
      final posPayload = _protocol.createPositionPayload(latitude, longitude);
      final posCmd = _createCommandForDevice(CMD_SET_ADVERT_LATLON, posPayload);
      await _sendBinaryToDevice(posCmd);
      _debugLog.logInfo('📍 Updated device position: $latitude, $longitude');
    } catch (e) {
      _debugLog.logError('Failed to update position: $e');
    }
  }

  /// Send Discovery ping to find nearby repeaters
  /// Uses MeshCore Discovery protocol (DISCOVER_REQ/DISCOVER_RESP)
  /// This service prevents overlap so each discovery cycle has one owner.
  Future<PingResult> ping({
    double? latitude,
    double? longitude,
    int timeoutSeconds = 30,
    bool waitForAllResponses = false,
    bool collectUntilTimeout = false,
  }) async {
    if (!isDeviceConnected) {
      return PingResult(
        timestamp: DateTime.now(),
        status: PingStatus.failed,
        error: 'LoRa device not connected',
      );
    }

    if (latitude == null || longitude == null) {
      return PingResult(
        timestamp: DateTime.now(),
        status: PingStatus.failed,
        error: 'No GPS location',
      );
    }

    if (isPingInProgress) {
      return PingResult(
        timestamp: DateTime.now(),
        status: PingStatus.failed,
        latitude: latitude,
        longitude: longitude,
        error: 'Another ping is already in progress',
      );
    }

    int? registeredTag;
    _startingPing = true;
    try {
      // Update device position for proper mesh routing
      await _updateDevicePosition(latitude, longitude);

      // Register before transmitting. Otherwise a fast USB/BLE notification
      // can arrive before the pending ping exists.
      final tag = _random.nextInt(0xFFFFFFFF);
      final pingSendTime = DateTime.now();
      final tracker = PingResponseTracker(
        sentAt: pingSendTime,
        latitude: latitude,
        longitude: longitude,
        collectUntilTimeout: collectUntilTimeout,
      );
      registeredTag = tag;
      _pendingPings[tag] = tracker;
      _pingTimeoutTimers[tag] = Timer(Duration(seconds: timeoutSeconds), () {
        final pending = _pendingPings[tag];
        if (pending == null) return;

        final result = pending.timeout(DateTime.now());
        _removePendingPing(tag);
        if (result != null) {
          _debugLog.logPing(
            'Ping timeout after ${result.responseTimeMs}ms. No repeaters responded.',
          );
          _pingResultController.add(result);
        }
      });
      _startingPing = false;

      // Send zero-hop advertisement to get immediate contact updates
      final zeroHopPayload = Uint8List.fromList([0]); // 0 = zero-hop
      final zeroHopCmd = _createCommandForDevice(
        CMD_SEND_SELF_ADVERT,
        zeroHopPayload,
      );
      _debugLog.logInfo('📡 Sending zero-hop advertisement');
      await _sendBinaryToDevice(zeroHopCmd);

      // Small delay to let adverts propagate
      await Future.delayed(const Duration(milliseconds: 100));

      // Create Discovery request payload (prefixOnly=false to get full 32-byte keys for contact lookup)
      final discoveryPayload = _protocol.createDiscoveryRequestPayload(
        tag,
        prefixOnly: false,
      );
      _debugLog.logInfo(
        'Discovery payload: ${discoveryPayload.map((b) => b.toRadixString(16).padLeft(2, "0")).join(" ")}',
      );

      final controlCmd = _createCommandForDevice(
        CMD_SEND_CONTROL_DATA,
        discoveryPayload,
      );
      _debugLog.logInfo(
        'Full command frame: ${controlCmd.take(30).map((b) => b.toRadixString(16).padLeft(2, "0")).join(" ")}...',
      );

      _debugLog.logInfo(
        '📡 Sending DISCOVER_REQ with tag=0x${tag.toRadixString(16).padLeft(8, "0")}',
      );
      await _sendBinaryToDevice(controlCmd);

      _debugLog.logPing('📍 Discovery ping sent at ($latitude, $longitude)');
      _debugLog.logInfo(
        'Note: Repeaters rate-limit to 4 responses per 2 minutes',
      );
      debugPrint(
        '📍 Discovery ping sent, tag=0x${tag.toRadixString(16)}, waiting for responses...',
      );

      return await (waitForAllResponses
          ? tracker.collectedResult
          : tracker.result);
    } catch (e) {
      final failedAt = DateTime.now();
      final tracker = registeredTag == null
          ? null
          : _pendingPings[registeredTag];
      if (tracker?.hasResponse == true) {
        _removePendingPing(registeredTag!);
        return await (waitForAllResponses
            ? tracker!.collectedResult
            : tracker!.result);
      }
      final result =
          tracker?.fail(failedAt, e.toString()) ??
          PingResult(
            timestamp: failedAt,
            status: PingStatus.failed,
            latitude: latitude,
            longitude: longitude,
            error: e.toString(),
          );
      if (registeredTag != null) {
        _removePendingPing(registeredTag);
      }
      _pingResultController.add(result);
      return result;
    } finally {
      _startingPing = false;
    }
  }

  /// Send command/data to LoRa device
  Future<void> _sendToDevice(String data) async {
    if (_connectionType == ConnectionType.bluetooth &&
        _txCharacteristic != null) {
      await _txCharacteristic!.write(utf8.encode(data));
    } else if (_connectionType == ConnectionType.usb && _usbPort != null) {
      await _usbPort!.write(Uint8List.fromList(utf8.encode(data)));
    }
  }

  /// Handle binary data from LoRa device
  void _handleDeviceData(Uint8List data) {
    try {
      _debugLog.logLoRa(
        '📶 Raw RX: ${data.length} bytes - ${data.map((b) => b.toRadixString(16).padLeft(2, '0')).take(20).join(' ')}${data.length > 20 ? '...' : ''}',
      );
      debugPrint('📶 Raw RX: ${data.length} bytes');

      final frames = _protocol.parseIncomingData(data);
      for (final frame in frames) {
        _handleFrame(frame);
      }
    } catch (e) {
      _debugLog.logError('Frame parse error: $e');
    }
  }

  /// Route incoming frames to appropriate handlers
  void _handleFrame(MeshCoreFrame frame) {
    _debugLog.logLoRa(
      '📥 RX Frame: code=0x${frame.code.toRadixString(16).padLeft(2, '0')} (${frame.code}) len=${frame.length}',
    );
    debugPrint(
      '📥 RX Frame: code=0x${frame.code.toRadixString(16).padLeft(2, '0')} (${frame.code}) len=${frame.length}',
    );

    switch (frame.code) {
      case PUSH_CODE_ADVERT:
        unawaited(_handleAdvertPush(frame.data));
        break;
      case RESP_CODE_CONTACT:
        _handleContactResponse(frame.data);
        break;
      case PUSH_CODE_NEW_ADVERT:
        _debugLog.logInfo('New contact advertisement received');
        _handleContactResponse(frame.data);
        break;
      case RESP_CODE_CONTACTS_START:
        _debugLog.logInfo('Contact list transfer started');
        break;
      case RESP_CODE_END_OF_CONTACTS:
        _debugLog.logInfo('Contact list complete');
        break;
      case RESP_CODE_SELF_INFO:
        _handleSelfInfo(frame.data);
        break;
      case RESP_CODE_DEVICE_INFO:
        _handleDeviceInfo(frame.data);
        break;
      case RESP_CODE_OK:
        _debugLog.logInfo('✅ Command OK');
        break;
      case RESP_CODE_ERR:
        final errorCode = frame.data.isEmpty ? null : frame.data.first;
        _debugLog.logError(
          'Command ERROR${errorCode == null ? '' : ' (code $errorCode)'}',
        );
        break;
      case RESP_CODE_SENT:
        _debugLog.logInfo('✅ Message sent');
        _carpeaterPayloadCallback?.call(RESP_CODE_SENT, frame.data);
        break;
      case PUSH_CODE_LOGIN_SUCCESS:
        _debugLog.logInfo('✅ Login success (0x85)');
        _carpeaterPayloadCallback?.call(PUSH_CODE_LOGIN_SUCCESS, frame.data);
        break;
      case PUSH_CODE_LOGIN_FAIL:
        _debugLog.logError('❌ Login failed (0x86)');
        _carpeaterPayloadCallback?.call(PUSH_CODE_LOGIN_FAIL, frame.data);
        break;
      case PUSH_CODE_BINARY_RESPONSE:
        _debugLog.logLoRa(
          '📦 Binary response (0x8C), len=${frame.data.length}',
        );
        _carpeaterPayloadCallback?.call(PUSH_CODE_BINARY_RESPONSE, frame.data);
        break;
      case RESP_CODE_BATT_AND_STORAGE:
        _handleBatteryResponse(frame.data);
        break;
      case PUSH_CODE_RAW_DATA:
        final rawData = _protocol.parseRawDataPush(frame.data);
        if (rawData == null) {
          _debugLog.logLoRa('Invalid raw data push (0x84)');
        } else {
          final payload = rawData['payload'] as Uint8List;
          _debugLog.logLoRa(
            'Raw data received (0x84), SNR=${rawData['snr']}, '
            'RSSI=${rawData['rssi']}, payload=${payload.length} bytes',
          );
        }
        break;
      case PUSH_CODE_LOG_RX_DATA:
        _debugLog.logLoRa('RF log data received (0x88), ignored');
        break;
      case PUSH_CODE_CONTROL_DATA:
        _debugLog.logLoRa(
          '🔍 Control data received (0x8E), payload len=${frame.data.length}',
        );
        _debugLog.logLoRa(
          'Control data hex: ${frame.data.take(50).map((b) => b.toRadixString(16).padLeft(2, "0")).join(" ")}${frame.data.length > 50 ? "..." : ""}',
        );
        debugPrint(
          '🔍 Control data: ${frame.data.take(50).map((b) => b.toRadixString(16).padLeft(2, "0")).join(" ")}',
        );
        _handleControlDataPush(frame.data);
        break;
      default:
        // Log other frame types for debugging
        _debugLog.logLoRa(
          'Unhandled frame type: 0x${frame.code.toRadixString(16)}',
        );
    }
  }

  /// Handle PUSH_CODE_ADVERT - advertisement from nearby node
  Future<void> _handleAdvertPush(Uint8List data) async {
    final publicKey = _protocol.parseAdvertFrame(data);
    if (publicKey == null) return;

    final keyHexFull = publicKey
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join('');
    final keyPrefix = keyHexFull.substring(0, 8).toUpperCase();
    _debugLog.logInfo('📡 Advertisement from $keyPrefix');

    // A regular advert only carries the key. Fetch the updated contact record;
    // newly auto-added contacts instead arrive as a full 0x8A contact frame.
    await _requestContactDetails(publicKey);
  }

  /// Request full contact list
  Future<void> _requestAllContacts() async {
    try {
      _debugLog.logInfo('📒 Requesting full contact list...');
      final cmd = _createCommandForDevice(CMD_GET_CONTACTS);
      await _sendBinaryToDevice(cmd);
    } catch (e) {
      _debugLog.logError('Failed to request full contact list: $e');
    }
  }

  /// Refresh contact list (public method for UI)
  Future<void> refreshContactList() async {
    await _requestAllContacts();
  }

  /// Request contact details for a specific public key
  Future<void> _requestContactDetails(Uint8List publicKey) async {
    final keyHex = publicKey
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join('');
    final keyPrefix = keyHex.substring(0, 8).toUpperCase();

    // Avoid duplicate in-flight requests
    if (_pendingContactRequests.contains(keyHex)) {
      debugPrint('⏭️ Skipping duplicate contact request for $keyPrefix');
      return;
    }

    // Throttle by time window
    final last = _lastContactRequestAt[keyPrefix];
    final now = DateTime.now();
    if (last != null && now.difference(last) <= _contactRequestCooldown) {
      debugPrint(
        '⏭️ Skipping contact request for $keyPrefix (within cooldown)',
      );
      return;
    }
    _lastContactRequestAt[keyPrefix] = now;
    _pendingContactRequests.add(keyHex);

    debugPrint('📞 Requesting contact details for $keyPrefix');
    _debugLog.logInfo('Requesting contact for $keyPrefix');

    final payload = _protocol.createGetContactByKeyPayload(publicKey);
    final cmd = _createCommandForDevice(CMD_GET_CONTACT_BY_KEY, payload);
    await _sendBinaryToDevice(cmd);
  }

  /// Handle PUSH_CODE_CONTROL_DATA - control data packet (e.g., Discovery responses)
  Future<void> _handleControlDataPush(Uint8List data) async {
    try {
      // Parse the control data frame (extracts SNR, RSSI, path, payload)
      final controlData = _protocol.parseControlDataPush(data);
      if (controlData == null) {
        _debugLog.logError('⚠️ Failed to parse control data push');
        return;
      }

      // Persistence/UI models store whole-dB SNR. Keep the protocol parser
      // lossless and convert through the shared quarter-dB helper so this
      // boundary matches every other sample source.
      final snr = snrQuarterDbToWholeDb(controlData['snr'])!;
      final rssi = controlData['rssi'] as int;
      final payload = controlData['payload'] as Uint8List;

      // Parse the payload as a Discovery response
      final discovery = _protocol.parseDiscoveryResponse(payload);
      if (discovery == null) {
        _debugLog.logLoRa('Control data is not a Discovery response');
        return;
      }

      final tag = discovery['tag'] as int;
      final nodeType = discovery['node_type'] as int;
      final pubkey = discovery['pubkey'] as String;
      final pubkeyShort = pubkey.substring(0, 8).toUpperCase();
      _debugLog.logInfo(
        '🔍 DISCOVER_RESP: tag=0x${tag.toRadixString(16)}, node=$pubkeyShort, type=$nodeType, SNR=$snr, RSSI=$rssi',
      );
      debugPrint(
        '🔍 Discovery response from $pubkeyShort (SNR=$snr, RSSI=$rssi)',
      );

      // Check if this repeater should be ignored (mobile companion)
      final shouldIgnore = _isIgnoredRepeater(pubkeyShort);

      // Record the radio response before any follow-up device request. Contact
      // lookup writes can be slow over BLE and must not delay ping feedback.
      if (!shouldIgnore) {
        final tracker = _pendingPings[tag];
        if (tracker != null && tracker.isAcceptingResponses) {
          _addPingResponse(
            tag,
            PingResponse(nodeId: pubkey, snr: snr, rssi: rssi),
          );
          _debugLog.logPing(
            '📡 Repeater $pubkeyShort responded (SNR=$snr, RSSI=$rssi)',
          );
        } else {
          _debugLog.logLoRa(
            '⚠️ Discovery response for unknown/completed tag: 0x${tag.toRadixString(16)}',
          );
        }
      }

      // Always request contact details so the pubkey gets cached (needed for Carpeater login)
      if (!_knownRepeaters.containsKey(pubkeyShort) &&
          discovery['pubkey_bytes'] != null) {
        final pubkeyBytes = discovery['pubkey_bytes'] as Uint8List;
        _debugLog.logInfo('📞 Requesting position for $pubkeyShort');
        await _requestContactDetails(pubkeyBytes);
      }

      if (shouldIgnore) {
        _debugLog.logInfo(
          '⛔ Ignoring discovery response from mobile repeater: $pubkeyShort',
        );
        return;
      }

      // Check if this is a NEW repeater we've never seen (in DB history)
      if (!_knownRepeaterIds.contains(pubkeyShort)) {
        _knownRepeaterIds.add(pubkeyShort);
        if (_newRepeaterAlertsEnabled) {
          _newRepeaterController.add(pubkeyShort);
          _debugLog.logInfo('🆕 NEW repeater discovered: $pubkeyShort');
        }
      }
    } catch (e) {
      _debugLog.logError('Error handling control data push: $e');
    }
  }

  /// Handle RESP_CODE_CONTACT - contact details response
  void _handleContactResponse(Uint8List data) {
    final contact = _protocol.parseContactFrame(data);
    if (contact == null) {
      _debugLog.logError('Failed to parse contact frame');
      return;
    }

    // Clear from pending
    _pendingContactRequests.remove(contact.publicKeyHex);

    // Store node type for filtering
    _nodeTypes[contact.publicKeyPrefix] = contact.advType;

    // Cache full public key for Carpeater mode
    _contactPubKeyCache[contact.publicKeyPrefix] = Uint8List.fromList(
      contact.publicKey,
    );

    _debugLog.logInfo(
      'Contact: ${contact.advName ?? contact.publicKeyPrefix} (type: ${contact.advType})',
    );

    // Remember every repeater/room-server contact by name so pickers can
    // offer previously found repeaters even without a known position.
    final advName = contact.advName;
    final isRepeaterType =
        contact.advType == ADV_TYPE_REPEATER ||
        contact.advType == ADV_TYPE_ROOM_SERVER;
    if (isRepeaterType && advName != null && advName.isNotEmpty) {
      _repeaterContactNames[contact.publicKeyPrefix] = advName;
    }

    // Only show repeaters (2) and room servers (3) on the map, and only if they have a position
    if (!contact.hasPosition ||
        (contact.advType != ADV_TYPE_REPEATER &&
            contact.advType != ADV_TYPE_ROOM_SERVER)) {
      return;
    }

    // Check if this repeater should be ignored (mobile companion)
    if (_isIgnoredRepeater(contact.publicKeyPrefix)) {
      _debugLog.logInfo(
        '⛔ Ignoring mobile repeater: ${contact.advName ?? contact.publicKeyPrefix}',
      );
      return;
    }

    final repeater = Repeater(
      id: contact.publicKeyPrefix,
      position: LatLng(contact.advLat!, contact.advLon!),
      name: contact.advName,
      timestamp: DateTime.now(),
    );

    // If scanning, cache only; otherwise show immediately on map
    if (_scanCompleter != null && !_scanCompleter!.isCompleted) {
      _repeaterContactCache[repeater.id] = repeater;
      _knownRepeaters[repeater.id] = repeater; // mark as known
      _debugLog.logInfo('📋 Cached: ${repeater.name ?? repeater.id}');
      return;
    }

    // Mark as known
    _knownRepeaters[repeater.id] = repeater;

    if (!_discoveredRepeaters.any((r) => r.id == repeater.id)) {
      _discoveredRepeaters.add(repeater);
      _debugLog.logInfo(
        '✅ Added to map: ${repeater.name ?? repeater.id} at (${contact.advLat}, ${contact.advLon})',
      );
    } else {
      // Update existing repeater's timestamp
      final idx = _discoveredRepeaters.indexWhere((r) => r.id == repeater.id);
      if (idx != -1) {
        _discoveredRepeaters[idx] = repeater;
      }
    }
  }

  /// Handle RESP_CODE_BATT_AND_STORAGE
  void _handleBatteryResponse(Uint8List data) {
    if (data.length >= 2) {
      final milliVolts = data[0] | (data[1] << 8);
      // Rough battery percentage from voltage (adjust as needed)
      if (milliVolts > 3000) {
        final percent = ((milliVolts - 3000) / 1200 * 100)
            .clamp(0, 100)
            .toInt();
        _batteryPercent = percent;
        _batteryController.add(percent);
        _debugLog.logInfo('Battery: $percent% ($milliVolts mV)');
      }
    }
  }

  void _addPingResponse(int tag, PingResponse response) {
    final tracker = _pendingPings[tag];
    if (tracker == null) return;

    final isFirstResponse = !tracker.hasResponse;
    final result = tracker.addResponse(response, DateTime.now());
    if (result == null) return;

    if (isFirstResponse) {
      if (!tracker.collectUntilTimeout) {
        _pingTimeoutTimers.remove(tag)?.cancel();
        _pingCollectionTimers[tag] = Timer(
          _pingResponseCollectionWindow,
          () => _removePendingPing(tag),
        );
      }
      _debugLog.logPing(
        tracker.collectUntilTimeout
            ? 'Ping response received in ${result.responseTimeMs}ms; collecting until discovery timeout'
            : 'Ping response received in ${result.responseTimeMs}ms; collecting for 3 more seconds',
      );
    }

    // The first result unblocks ping() immediately. Updated aggregate results
    // are streamed as more repeaters answer during the collection window.
    _pingResultController.add(result);
  }

  void _removePendingPing(int tag) {
    _pingTimeoutTimers.remove(tag)?.cancel();
    _pingCollectionTimers.remove(tag)?.cancel();
    _pendingPings.remove(tag)?.close(DateTime.now());
  }

  void _failPendingPings(String error) {
    final failedAt = DateTime.now();
    for (final tracker in _pendingPings.values) {
      final result = tracker.fail(failedAt, error);
      if (result != null) {
        _pingResultController.add(result);
      }
    }
    for (final timer in _pingTimeoutTimers.values) {
      timer.cancel();
    }
    for (final timer in _pingCollectionTimers.values) {
      timer.cancel();
    }
    _pingTimeoutTimers.clear();
    _pingCollectionTimers.clear();
    _pendingPings.clear();
    _startingPing = false;
  }

  Future<void> _sendProtocolHandshake() async {
    final appStart = _createCommandForDevice(
      CMD_APP_START,
      _protocol.createAppStartPayload(),
    );
    await _sendBinaryToDevice(appStart);
    await Future.delayed(const Duration(milliseconds: 100));

    final query = _createCommandForDevice(
      CMD_DEVICE_QUERY,
      _protocol.createDeviceQueryPayload(),
    );
    await _sendBinaryToDevice(query);
    _debugLog.logInfo(
      'Sent companion app-target v$COMPANION_APP_TARGET_VERSION handshake',
    );
  }

  /// Create command frame based on connection type (BLE vs USB)
  Uint8List _createCommandForDevice(int commandCode, [Uint8List? payload]) {
    if (_connectionType == ConnectionType.bluetooth) {
      return _protocol.createCommandFrameBLE(commandCode, payload);
    } else {
      return _protocol.createCommandFrame(commandCode, payload);
    }
  }

  /// Send binary frame to device (handles BLE vs USB frame formats)
  Future<void> _sendBinaryToDevice(Uint8List data) async {
    try {
      _debugLog.logLoRa(
        '📤 TX: ${data.length} bytes - ${data.map((b) => b.toRadixString(16).padLeft(2, '0')).take(20).join(' ')}${data.length > 20 ? '...' : ''}',
      );

      if (_connectionType == ConnectionType.bluetooth &&
          _txCharacteristic != null) {
        // BLE: Send the raw frame data without wrapper
        await _txCharacteristic!.write(data.toList());
        _debugLog.logLoRa('✅ BLE write complete');
      } else if (_connectionType == ConnectionType.usb && _usbPort != null) {
        // USB: Data should already have '< + length' wrapper
        await _usbPort!.write(data);
        _debugLog.logLoRa('✅ USB write complete');
      }
    } catch (e) {
      _debugLog.logError('Send error: $e');
    }
  }

  /// Process a complete line from LoRa device (legacy text mode)
  void _processDeviceLine(String line) {
    _debugLog.logLoRa(line);
    debugPrint('LoRa device: $line');

    // Try to parse battery percentage from device messages
    // Common formats:
    // - "Battery: 85%"
    // - "Batt=85%"
    // - "bat:85"
    final batteryRegex = RegExp(
      r'(?:battery|batt?|pwr)[:\s=]+?(\d+)',
      caseSensitive: false,
    );
    final match = batteryRegex.firstMatch(line);
    if (match != null) {
      final percent = int.tryParse(match.group(1)!);
      if (percent != null && percent >= 0 && percent <= 100) {
        _batteryPercent = percent;
        _batteryController.add(_batteryPercent);
        debugPrint('Battery from device message: $percent%');
      }
    }

    // Parse repeater/node information if we're scanning
    if (_scanCompleter != null && !_scanCompleter!.isCompleted) {
      _parseRepeaterLine(line);
    }
  }

  /// Decrypt AES-ECB encrypted channel message
  Uint8List? _decryptChannelMessage(Uint8List encrypted, Uint8List key) {
    try {
      if (encrypted.length % 16 != 0) return null; // Must be block-aligned

      final cipher = AESEngine();
      cipher.init(false, KeyParameter(key));

      final decrypted = Uint8List(encrypted.length);
      for (int i = 0; i < encrypted.length; i += 16) {
        cipher.processBlock(encrypted, i, decrypted, i);
      }

      return decrypted;
    } catch (e) {
      debugPrint('Decryption error: $e');
      return null;
    }
  }

  // ============================================================================
  // BATTERY MONITORING
  // ============================================================================

  Timer? _batteryMonitorTimer;
  BluetoothCharacteristic? _batteryCharacteristic;

  void _startBatteryMonitoring() {
    // Poll battery every 30 seconds if we have a battery characteristic
    _batteryMonitorTimer?.cancel();
    _batteryMonitorTimer = Timer.periodic(const Duration(seconds: 30), (
      _,
    ) async {
      if (_connectionType == ConnectionType.bluetooth &&
          _batteryCharacteristic != null) {
        try {
          final value = await _batteryCharacteristic!.read();
          if (value.isNotEmpty) {
            _batteryPercent = value[0];
            _batteryController.add(_batteryPercent);
          }
        } catch (e) {
          debugPrint('Error reading battery: $e');
        }
      }
    });
  }

  void _stopBatteryMonitoring() {
    _batteryMonitorTimer?.cancel();
    _batteryMonitorTimer = null;
    _batteryCharacteristic = null;
    _batteryPercent = null;
    _batteryController.add(null);
  }

  // ============================================================================
  // UTILITIES
  // ============================================================================

  String _generateId() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(
      8,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  // ============================================================================
  // DISCONNECT
  // ============================================================================

  // Stream for broadcasting disconnect events
  final _disconnectController = StreamController<void>.broadcast();
  Stream<void> get disconnectStream => _disconnectController.stream;

  /// Handle unexpected USB disconnection
  void _handleUsbDisconnection() {
    if (_connectionType != ConnectionType.usb) return;
    debugPrint('⚠️ USB device disconnected');
    _debugLog.logError('USB disconnected');

    _stopBatteryMonitoring();
    _deviceSubscription?.cancel();
    _deviceSubscription = null;

    _usbPort = null;
    _connectionType = ConnectionType.none;
    _deviceName = null;
    _forgetNodeAdvertName();

    _failPendingPings('USB connection lost');

    // Notify listeners of disconnect
    _disconnectController.add(null);

    // The user did not ask for this: try to restore the connection.
    _beginAutoReconnect();
  }

  /// Handle unexpected Bluetooth disconnection
  void _handleBluetoothDisconnection() {
    if (_connectionType != ConnectionType.bluetooth) return;
    debugPrint('⚠️ Bluetooth device disconnected unexpectedly');
    _debugLog.logError('Bluetooth disconnected');

    _stopBatteryMonitoring();
    _connectionStateSubscription?.cancel();
    _deviceSubscription?.cancel();
    _connectionStateSubscription = null;
    _deviceSubscription = null;

    _bluetoothDevice = null;
    _txCharacteristic = null;
    _rxCharacteristic = null;
    _connectionType = ConnectionType.none;
    _deviceName = null;
    _forgetNodeAdvertName();

    _failPendingPings('Bluetooth connection lost');

    // Notify listeners of disconnect
    _disconnectController.add(null);

    // The user did not ask for this: try to restore the connection.
    _beginAutoReconnect();
  }

  Future<void> disconnectDevice() async {
    try {
      // User-initiated disconnect: the device must not be reconnected
      // automatically afterwards.
      _userDisconnectRequested = true;
      _stopAutoReconnect();

      _stopBatteryMonitoring();
      await _connectionStateSubscription?.cancel();
      await _deviceSubscription?.cancel();

      if (_connectionType == ConnectionType.bluetooth &&
          _bluetoothDevice != null) {
        await _bluetoothDevice!.disconnect();
      } else if (_connectionType == ConnectionType.usb && _usbPort != null) {
        await _usbPort!.close();
      }

      _bluetoothDevice = null;
      _txCharacteristic = null;
      _rxCharacteristic = null;
      _usbPort = null;
      _connectionType = ConnectionType.none;
      _deviceName = null;
      _forgetNodeAdvertName();
      _connectionStateSubscription = null;
      _deviceSubscription = null;
      debugPrint('LoRa device disconnected');

      // Notify listeners of disconnect
      _disconnectController.add(null);
    } catch (e) {
      debugPrint('Error disconnecting device: $e');
    }
  }

  // ============================================================================
  // AUTOMATIC RECONNECT
  // ============================================================================

  /// Starts the automatic reconnection loop after an unexpected disconnect.
  void _beginAutoReconnect() {
    if (_userDisconnectRequested) return;
    if (_lastBluetoothRemoteId == null && _lastUsbDevice == null) return;
    if (_autoReconnectActive) return;

    _autoReconnectActive = true;
    _reconnectAttempts = 0;
    _debugLog.logInfo(
      'Auto-reconnect started for ${reconnectDeviceName ?? 'device'}',
    );
    _scheduleNextReconnectAttempt();
  }

  /// Schedules the next reconnect attempt using exponential backoff.
  void _scheduleNextReconnectAttempt() {
    if (_userDisconnectRequested || isDeviceConnected) return;

    _reconnectTimer?.cancel();
    final attempt = _reconnectAttempts + 1;
    final delay = _reconnectBackoff.delayForAttempt(attempt);
    debugPrint(
      '⏳ Reconnecting to LoRa device in ${delay.inSeconds}s (attempt $attempt)',
    );
    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      unawaited(_attemptReconnect());
    });
    _emitReconnectStatus(active: true, nextAttempt: attempt);
  }

  /// Runs one reconnect attempt against the remembered device and reschedules
  /// itself with backoff until the connection is restored or the user
  /// disconnects (or connects manually) in the meantime.
  Future<void> _attemptReconnect() async {
    if (_userDisconnectRequested || isDeviceConnected || _connectInFlight) {
      return;
    }
    final bluetoothRemoteId = _lastBluetoothRemoteId;
    final usbTarget = _lastUsbDevice;
    if (bluetoothRemoteId == null && usbTarget == null) return;

    _debugLog.logInfo(
      'Reconnect attempt ${_reconnectAttempts + 1} '
      '(${bluetoothRemoteId != null ? 'bluetooth' : 'usb'})...',
    );

    try {
      if (bluetoothRemoteId != null) {
        await _connectBluetoothDevice(
          BluetoothDevice.fromId(bluetoothRemoteId),
        );
      } else {
        // deviceId changes on every replug, so re-scan and match on stable
        // attributes instead of reusing the stale UsbDevice instance.
        final attached = await scanUsbDevices();
        final match = matchUsbDevice(attached, usbTarget!);
        if (match != null) {
          await _connectUsbDevice(match);
        } else {
          _debugLog.logInfo('Remembered USB device is not attached yet');
        }
      }
    } catch (e) {
      _debugLog.logError('Reconnect attempt failed: $e');
    }

    // A user disconnect may have raced the in-flight attempt.
    if (_userDisconnectRequested) {
      if (isDeviceConnected) await disconnectDevice();
      return;
    }

    if (isDeviceConnected) {
      _debugLog.logInfo('✅ LoRa device reconnected automatically');
      _autoReconnectActive = false;
      _emitReconnectStatus(active: false, restored: true);
      return;
    }

    _reconnectAttempts += 1;
    _scheduleNextReconnectAttempt();
  }

  /// Stops the automatic reconnection loop (user disconnect or manual
  /// connect) and reports the loop as inactive.
  void _stopAutoReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    if (!_autoReconnectActive) return;
    _autoReconnectActive = false;
    _emitReconnectStatus(active: false);
  }

  /// Records a successfully established connection and re-arms the
  /// automatic reconnection for future unexpected losses.
  ///
  /// Never clears [_userDisconnectRequested]: if the user asked to disconnect
  /// while a connect attempt was still in flight, the caller is responsible
  /// for tearing the connection down again.
  void _onConnectionEstablished({
    String? bluetoothRemoteId,
    String? bluetoothName,
    UsbDevice? usbDevice,
  }) {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    _autoReconnectActive = false;
    _lastBluetoothRemoteId = bluetoothRemoteId;
    _lastBluetoothName = bluetoothName;
    _lastUsbDevice = usbDevice;
  }

  void _notifyConnectionEstablished() {
    if (!_connectedController.isClosed) {
      _connectedController.add(null);
    }
  }

  void _emitReconnectStatus({
    required bool active,
    int nextAttempt = 0,
    bool restored = false,
  }) {
    if (_reconnectStateController.isClosed) return;
    _reconnectStateController.add(
      ReconnectStatus(
        active: active,
        nextAttempt: nextAttempt,
        deviceName: reconnectDeviceName,
        restored: restored,
      ),
    );
  }

  Future<void> disconnectMqtt() async {
    // MQTT removed - no-op
  }

  // ============================================================================
  // CARPEATER MODE - PUBLIC METHODS FOR REPEATER CONTROL
  // ============================================================================

  /// Send a login command to a target repeater
  Future<bool> sendRepeaterLogin({
    required Uint8List targetPubKey,
    required String password,
  }) async {
    if (!isDeviceConnected) {
      _debugLog.logError('Cannot send login: Device not connected');
      return false;
    }
    try {
      _debugLog.logInfo('Sending login to repeater...');
      final payload = _protocol.createLoginPayload(targetPubKey, password);
      final cmd = _createCommandForDevice(CMD_SEND_LOGIN, payload);
      await _sendBinaryToDevice(cmd);
      _debugLog.logInfo('Login command sent');
      return true;
    } catch (e) {
      _debugLog.logError('Failed to send login: $e');
      return false;
    }
  }

  /// Send a CLI command to a logged-in repeater
  Future<bool> sendRepeaterCliCommand({
    required Uint8List targetPubKey,
    required String command,
  }) async {
    if (!isDeviceConnected) {
      _debugLog.logError('Cannot send CLI command: Device not connected');
      return false;
    }
    try {
      _debugLog.logInfo('Sending CLI command to repeater: $command');
      final payload = _protocol.createCliCommandPayload(targetPubKey, command);
      final cmd = _createCommandForDevice(CMD_SEND_MESSAGE, payload);
      await _sendBinaryToDevice(cmd);
      _debugLog.logInfo('CLI command sent');
      return true;
    } catch (e) {
      _debugLog.logError('Failed to send CLI command: $e');
      return false;
    }
  }

  /// Request neighbours from a target repeater (requires login first)
  Future<bool> sendRepeaterGetNeighbours({
    required Uint8List targetPubKey,
  }) async {
    if (!isDeviceConnected) {
      _debugLog.logError('Cannot request neighbours: Device not connected');
      return false;
    }
    try {
      _debugLog.logInfo('Requesting neighbours via CMD_SEND_BINARY_REQ...');
      final requestData = _protocol.createGetNeighboursRequestData();
      final payload = _protocol.createBinaryReqPayload(
        targetPubKey,
        requestData,
      );
      final cmd = _createCommandForDevice(CMD_SEND_BINARY_REQ, payload);
      await _sendBinaryToDevice(cmd);
      _debugLog.logInfo('Binary neighbours request sent');
      return true;
    } catch (e) {
      _debugLog.logError('Failed to send binary neighbours request: $e');
      return false;
    }
  }

  /// Get the full 32-byte public key for a contact by its ID prefix.
  Uint8List? getContactPubKey(String prefix) {
    final upperPrefix = prefix.toUpperCase();
    for (final entry in _contactPubKeyCache.entries) {
      if (entry.key.toUpperCase().startsWith(upperPrefix)) {
        return Uint8List.fromList(entry.value);
      }
    }
    return null;
  }

  /// Register/unregister a callback for Carpeater push frames.
  void setCarpeaterCallback(
    void Function(int pushCode, Uint8List data)? callback,
  ) {
    _carpeaterPayloadCallback = callback;
  }

  void dispose() {
    _stopAutoReconnect();
    disconnectDevice();
    _pingResultController.close();
    _batteryController.close();
    _disconnectController.close();
    _reconnectStateController.close();
    _connectedController.close();
  }
}
