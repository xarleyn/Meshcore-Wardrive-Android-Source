const meshCoreNordicUartServiceUuid = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';

const _companionNameKeywords = [
  'lora',
  'meshtastic',
  'meshcore',
  'whisper',
  't-beam',
  'tbeam',
  'heltec',
];

String normalizeBluetoothId(String id) {
  return id.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '').toUpperCase();
}

/// Converts a stored companion device id (MAC without colons) into a BLE
/// remote id. USB ids and other non-MAC values return null.
String? bluetoothRemoteIdFromStoredId(String stored) {
  final hex = normalizeBluetoothId(stored);
  if (hex.length != 12) return null;
  final parts = <String>[];
  for (var index = 0; index < 12; index += 2) {
    parts.add(hex.substring(index, index + 2));
  }
  return parts.join(':');
}

bool isLikelyLoRaCompanion({
  required String name,
  String remoteId = '',
  Iterable<String> serviceUuids = const [],
  Iterable<String> knownRemoteIds = const [],
}) {
  final normalizedId = normalizeBluetoothId(remoteId);
  if (normalizedId.isNotEmpty) {
    final known = knownRemoteIds.map(normalizeBluetoothId).toSet();
    if (known.contains(normalizedId)) return true;
  }

  for (final uuid in serviceUuids) {
    if (uuid.toLowerCase() == meshCoreNordicUartServiceUuid) return true;
  }

  final lower = name.toLowerCase();
  return _companionNameKeywords.any(lower.contains);
}

class KnownBluetoothDevice {
  const KnownBluetoothDevice({required this.remoteId, required this.name});

  final String remoteId;
  final String name;

  KnownBluetoothDevice copyWith({String? remoteId, String? name}) {
    return KnownBluetoothDevice(
      remoteId: remoteId ?? this.remoteId,
      name: name ?? this.name,
    );
  }
}

class DiscoveredBluetoothDevice {
  const DiscoveredBluetoothDevice({
    required this.remoteId,
    required this.name,
    this.serviceUuids = const [],
  });

  final String remoteId;
  final String name;
  final List<String> serviceUuids;
}

class BluetoothScanEntry {
  const BluetoothScanEntry({
    required this.remoteId,
    required this.name,
    this.previouslyUsed = false,
    this.currentlyVisible = false,
  });

  final String remoteId;
  final String name;
  final bool previouslyUsed;
  final bool currentlyVisible;

  String get displayName => name.trim().isEmpty ? 'Unknown device' : name;

  String get statusLabel {
    if (previouslyUsed) return 'Previously used';
    if (currentlyVisible) return 'Nearby';
    return '';
  }
}

class BluetoothScanSnapshot {
  const BluetoothScanSnapshot({
    required this.devices,
    this.isScanning = false,
    this.error,
  });

  final List<BluetoothScanEntry> devices;
  final bool isScanning;
  final String? error;

  BluetoothScanSnapshot copyWith({
    List<BluetoothScanEntry>? devices,
    bool? isScanning,
    String? error,
    bool clearError = false,
  }) {
    return BluetoothScanSnapshot(
      devices: devices ?? this.devices,
      isScanning: isScanning ?? this.isScanning,
      error: clearError ? null : error ?? this.error,
    );
  }
}

List<KnownBluetoothDevice> collectKnownBluetoothDevices({
  required List<KnownBluetoothDevice> recent,
  List<KnownBluetoothDevice> tracked = const [],
  List<KnownBluetoothDevice> bonded = const [],
}) {
  final byId = <String, KnownBluetoothDevice>{};
  final order = <String>[];

  void add(KnownBluetoothDevice device) {
    final id = normalizeBluetoothId(device.remoteId);
    if (id.isEmpty) return;
    final existing = byId[id];
    if (existing == null) {
      byId[id] = device;
      order.add(id);
      return;
    }
    if (existing.name.trim().isEmpty && device.name.trim().isNotEmpty) {
      byId[id] = existing.copyWith(name: device.name);
    }
  }

  for (final device in [...recent, ...tracked, ...bonded]) {
    add(device);
  }
  return [for (final id in order) byId[id]!];
}

List<BluetoothScanEntry> mergeBluetoothScanResults({
  required List<KnownBluetoothDevice> known,
  required List<DiscoveredBluetoothDevice> discovered,
}) {
  final knownById = <String, KnownBluetoothDevice>{};
  final order = <String>[];

  for (final device in known) {
    final id = normalizeBluetoothId(device.remoteId);
    if (id.isEmpty || knownById.containsKey(id)) continue;
    knownById[id] = device;
    order.add(id);
  }

  final discoveredById = <String, DiscoveredBluetoothDevice>{};
  for (final device in discovered) {
    final id = normalizeBluetoothId(device.remoteId);
    if (id.isEmpty) continue;
    discoveredById[id] = device;
    if (!knownById.containsKey(id) && !order.contains(id)) {
      order.add(id);
    }
  }

  return [
    for (final id in order)
      BluetoothScanEntry(
        remoteId: discoveredById[id]?.remoteId ?? knownById[id]!.remoteId,
        name: _preferredName(discoveredById[id]?.name, knownById[id]?.name),
        previouslyUsed: knownById.containsKey(id),
        currentlyVisible: discoveredById.containsKey(id),
      ),
  ];
}

String _preferredName(String? liveName, String? knownName) {
  final live = liveName?.trim() ?? '';
  if (live.isNotEmpty) return liveName!;
  return knownName ?? '';
}
