import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/database_service.dart';

class DeviceComparisonScreen extends StatefulWidget {
  const DeviceComparisonScreen({super.key});

  @override
  State<DeviceComparisonScreen> createState() => _DeviceComparisonScreenState();
}

class _DeviceComparisonScreenState extends State<DeviceComparisonScreen> {
  List<Map<String, dynamic>> _devices = [];
  Map<String, Map<String, dynamic>> _deviceStats = {};
  bool _loading = true;
  String? _compareA;
  String? _compareB;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = DatabaseService();
    final devices = await db.getAllDevices();
    final keys = [for (final d in devices) d['public_key'] as String];
    final statsList = await Future.wait([
      for (final key in keys) db.getDeviceStats(key),
    ]);
    final stats = <String, Map<String, dynamic>>{
      for (var i = 0; i < keys.length; i++) keys[i]: statsList[i],
    };

    setState(() {
      _devices = devices;
      _deviceStats = stats;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsDeviceComparison)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _devices.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l10n.deviceComparisonEmpty,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Device list
                  Text(
                    l10n.deviceComparisonTracked(_devices.length),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._devices.map((d) => _buildDeviceCard(d)),

                  // Comparison section
                  if (_devices.length >= 2) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      l10n.deviceComparisonCompareDevices,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            value: _compareA,
                            hint: Text(
                              l10n.deviceComparisonDeviceA,
                              style: const TextStyle(fontSize: 13),
                            ),
                            isExpanded: true,
                            items: _devices.map((d) {
                              final key = d['public_key'] as String;
                              return DropdownMenuItem(
                                value: key,
                                child: Text(
                                  d['name'] as String? ?? key,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (v) => setState(() => _compareA = v),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            l10n.deviceComparisonVs,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: DropdownButton<String>(
                            value: _compareB,
                            hint: Text(
                              l10n.deviceComparisonDeviceB,
                              style: const TextStyle(fontSize: 13),
                            ),
                            isExpanded: true,
                            items: _devices.map((d) {
                              final key = d['public_key'] as String;
                              return DropdownMenuItem(
                                value: key,
                                child: Text(
                                  d['name'] as String? ?? key,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (v) => setState(() => _compareB = v),
                          ),
                        ),
                      ],
                    ),
                    if (_compareA != null &&
                        _compareB != null &&
                        _compareA != _compareB)
                      _buildComparisonTable(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildDeviceCard(Map<String, dynamic> device) {
    final key = device['public_key'] as String;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final name = device['name'] as String? ?? l10n.settingsUnknown;
    final connType = device['connection_type'] as String? ?? '?';
    final firstUsed = DateTime.fromMillisecondsSinceEpoch(
      device['first_used'] as int,
    );
    final lastUsed = DateTime.fromMillisecondsSinceEpoch(
      device['last_used'] as int,
    );
    final stats = _deviceStats[key];

    final totalPings = stats?['totalPings'] ?? 0;
    final successRate = stats?['successRate'] ?? 0.0;
    final cells = stats?['uniqueCells'] ?? 0;

    final rateColor = successRate > 0.7
        ? Colors.green
        : successRate > 0.3
        ? Colors.orange
        : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  connType == 'bluetooth' ? Icons.bluetooth : Icons.usb,
                  size: 18,
                  color: connType == 'bluetooth' ? Colors.blue : Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (totalPings > 0)
                  Text(
                    '${(successRate * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: rateColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _miniStat(l10n.deviceComparisonMiniPings, '$totalPings'),
                _miniStat(l10n.deviceComparisonMiniCells, '$cells'),
                _miniStat(
                  l10n.deviceComparisonMiniAvgResp,
                  stats?['avgResponseMs'] != null
                      ? l10n.deviceComparisonAvgRespMs(
                          stats!['avgResponseMs'].toStringAsFixed(0),
                        )
                      : '—',
                ),
                _miniStat(
                  l10n.deviceComparisonMiniAvgSnr,
                  stats?['avgSnr'] != null
                      ? '${stats!['avgSnr'].toStringAsFixed(1)}'
                      : '—',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.deviceComparisonFirstLast(
                DateFormat.MMMd(locale).format(firstUsed),
                DateFormat.MMMd(locale).format(lastUsed),
              ),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonTable() {
    final l10n = AppLocalizations.of(context);
    final a = _deviceStats[_compareA!] ?? {};
    final b = _deviceStats[_compareB!] ?? {};
    final nameA =
        _devices.firstWhere((d) => d['public_key'] == _compareA)['name']
            as String? ??
        _compareA!;
    final nameB =
        _devices.firstWhere((d) => d['public_key'] == _compareB)['name']
            as String? ??
        _compareB!;

    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    l10n.deviceComparisonStat,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    nameA,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    nameB,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    l10n.deviceComparisonWinner,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const Divider(),
            _compRow(
              l10n.deviceComparisonTotalPings,
              a['totalPings'] ?? 0,
              b['totalPings'] ?? 0,
              higher: true,
            ),
            _compRow(
              l10n.deviceComparisonSuccessRate,
              a['successRate'] ?? 0.0,
              b['successRate'] ?? 0.0,
              higher: true,
              pct: true,
            ),
            _compRow(
              l10n.deviceComparisonFailures,
              a['failures'] ?? 0,
              b['failures'] ?? 0,
              higher: false,
            ),
            _compRow(
              l10n.deviceComparisonUniqueCells,
              a['uniqueCells'] ?? 0,
              b['uniqueCells'] ?? 0,
              higher: true,
            ),
            _compRow(
              l10n.deviceComparisonAvgResponse,
              a['avgResponseMs'],
              b['avgResponseMs'],
              higher: false,
              suffix: 'ms',
            ),
            _compRow(
              l10n.deviceComparisonAvgSnr,
              a['avgSnr'],
              b['avgSnr'],
              higher: true,
              suffix: 'dB',
            ),
            _compRow(
              l10n.deviceComparisonAvgRssi,
              a['avgRssi'],
              b['avgRssi'],
              higher: true,
              suffix: 'dBm',
            ),
          ],
        ),
      ),
    );
  }

  Widget _compRow(
    String label,
    dynamic valA,
    dynamic valB, {
    bool higher = true,
    bool pct = false,
    String? suffix,
  }) {
    String fmt(dynamic v) {
      if (v == null) return '—';
      if (pct) return '${(v * 100).toStringAsFixed(1)}%';
      if (v is double) return '${v.toStringAsFixed(1)}${suffix ?? ''}';
      return '$v${suffix ?? ''}';
    }

    String winner = '—';
    Color winColor = Colors.grey;
    final l10n = AppLocalizations.of(context);
    if (valA != null && valB != null) {
      final a = (valA is int) ? valA.toDouble() : (valA as double);
      final b = (valB is int) ? valB.toDouble() : (valB as double);
      if (a != b) {
        final aWins = higher ? a > b : a < b;
        final nameA =
            _devices.firstWhere((d) => d['public_key'] == _compareA)['name']
                as String? ??
            l10n.deviceComparisonDeviceA;
        final nameB =
            _devices.firstWhere((d) => d['public_key'] == _compareB)['name']
                as String? ??
            l10n.deviceComparisonDeviceB;
        winner = aWins ? nameA : nameB;
        winColor = Colors.green;
      } else {
        winner = l10n.deviceComparisonTie;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              fmt(valA),
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              fmt(valB),
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              winner,
              style: TextStyle(
                fontSize: 11,
                color: winColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
