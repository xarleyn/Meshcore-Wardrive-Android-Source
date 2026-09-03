import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../widgets/discovery_timeout_options.dart';
import '../../../widgets/ping_distance_options.dart';

class MapQuickSettingsPanel extends StatelessWidget {
  const MapQuickSettingsPanel({
    required this.pingIntervalMeters,
    required this.discoveryTimeoutSeconds,
    required this.pingMode,
    required this.onClose,
    required this.onPingIntervalChanged,
    required this.onDiscoveryTimeoutChanged,
    required this.onPingModeChanged,
    super.key,
  });

  final double pingIntervalMeters;
  final int discoveryTimeoutSeconds;
  final String pingMode;
  final VoidCallback onClose;
  final ValueChanged<double> onPingIntervalChanged;
  final ValueChanged<int> onDiscoveryTimeoutChanged;
  final ValueChanged<String> onPingModeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Positioned(
      bottom: 80,
      right: 88,
      child: Card(
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.mapQuickSettings,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onClose,
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.mapPingDist, style: const TextStyle(fontSize: 12)),
                  PingDistanceDropdown(
                    value: pingIntervalMeters,
                    onChanged: onPingIntervalChanged,
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.mapTimeout, style: const TextStyle(fontSize: 12)),
                  DiscoveryTimeoutDropdown(
                    value: discoveryTimeoutSeconds,
                    onChanged: onDiscoveryTimeoutChanged,
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.mapMode, style: const TextStyle(fontSize: 12)),
                  DropdownButton<String>(
                    value: pingMode,
                    isDense: true,
                    items: [
                      DropdownMenuItem(
                        value: 'distance',
                        child: Text(
                          l10n.settingsPingModeDistance,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'time',
                        child: Text(
                          l10n.settingsPingModeTime,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'both',
                        child: Text(
                          l10n.settingsPingModeBoth,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) onPingModeChanged(value);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
