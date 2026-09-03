import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../services/carpeater_service.dart';
import '../../../services/lora_companion_service.dart';
import 'map_screen_actions.dart';

class MapControlPanel extends StatelessWidget {
  const MapControlPanel({
    required this.loraConnected,
    required this.isConnecting,
    required this.connectionType,
    required this.batteryPercent,
    required this.sampleCount,
    required this.isTracking,
    required this.totalDistance,
    required this.currentSpeed,
    required this.distanceUnit,
    required this.carpeaterEnabled,
    required this.carpeaterState,
    required this.ductingLabel,
    required this.ductingColor,
    required this.batterySaverActive,
    required this.actions,
    super.key,
  });

  final bool loraConnected;
  final bool isConnecting;
  final ConnectionType connectionType;
  final int? batteryPercent;
  final int sampleCount;
  final bool isTracking;
  final double totalDistance;
  final double currentSpeed;
  final String distanceUnit;
  final bool carpeaterEnabled;
  final CarpeaterState carpeaterState;
  final String? ductingLabel;
  final Color? ductingColor;
  final bool batterySaverActive;
  final MapPanelCallbacks actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                loraConnected
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth_disabled,
                size: 16,
                color: loraConnected ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                loraConnected
                    ? (connectionType == ConnectionType.usb ? 'USB' : 'BT')
                    : l10n.mapNoLora,
                style: TextStyle(
                  fontSize: 12,
                  color: loraConnected ? Colors.green : Colors.grey,
                ),
              ),
              if (loraConnected && batteryPercent != null) ...[
                const SizedBox(width: 4),
                Icon(
                  _batteryIcon(batteryPercent!),
                  size: 14,
                  color: _batteryColor(batteryPercent!),
                ),
                const SizedBox(width: 2),
                Text(
                  '$batteryPercent%',
                  style: TextStyle(
                    fontSize: 11,
                    color: _batteryColor(batteryPercent!),
                  ),
                ),
              ],
              const SizedBox(width: 12),
              const Text('•', style: TextStyle(color: Colors.grey)),
              const SizedBox(width: 12),
              Flexible(child: _buildStats(context)),
              const Spacer(),
              if (!loraConnected)
                TextButton(
                  onPressed: isConnecting ? null : actions.onConnect,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    isConnecting ? l10n.mapConnecting : l10n.mapConnect,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              if (loraConnected) ...[
                IconButton(
                  icon: const Icon(Icons.link_off, size: 16),
                  onPressed: actions.onDisconnect,
                  tooltip: l10n.mapDisconnect,
                  color: Colors.red,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.send, size: 18),
                  onPressed: actions.onManualPing,
                  tooltip: l10n.mapManualPing,
                  color: Colors.blue,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final carpeaterColor = _carpeaterColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.mapSamplesCount('$sampleCount'),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        if (isTracking)
          Text(
            '${totalDistance.toStringAsFixed(2)} '
            '${distanceUnit == 'miles' ? 'mi' : 'km'} • '
            '${currentSpeed.toStringAsFixed(1)} '
            '${distanceUnit == 'miles' ? 'mph' : 'km/h'}',
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        if (carpeaterEnabled && carpeaterState != CarpeaterState.disabled)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: GestureDetector(
              onTap: carpeaterState == CarpeaterState.error
                  ? actions.onCarpeaterRetry
                  : null,
              child: _StatusBadge(
                color: carpeaterColor,
                label: l10n.mapCarpeaterStatus(_carpeaterStateLabel(l10n)),
                trailing: carpeaterState == CarpeaterState.error
                    ? const Icon(Icons.refresh, size: 10, color: Colors.red)
                    : null,
              ),
            ),
          ),
        if (ductingLabel != null && ductingColor != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: _StatusBadge(
              color: ductingColor!,
              label: l10n.mapDuctingStatus(ductingLabel!),
            ),
          ),
        if (batterySaverActive)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: _StatusBadge(
              color: Colors.orange,
              label: l10n.mapBatterySaverBadge,
            ),
          ),
      ],
    );
  }

  Color get _carpeaterColor {
    if (carpeaterState == CarpeaterState.error) return Colors.red;
    if (carpeaterState == CarpeaterState.loggedIn ||
        carpeaterState == CarpeaterState.discovering ||
        carpeaterState == CarpeaterState.fetchingNeighbours) {
      return Colors.green;
    }
    return Colors.orange;
  }

  String _carpeaterStateLabel(AppLocalizations l10n) {
    return switch (carpeaterState) {
      CarpeaterState.disabled => l10n.mapCarpeaterOff,
      CarpeaterState.connecting => l10n.mapCarpeaterConnecting,
      CarpeaterState.loggingIn => l10n.mapCarpeaterLogin,
      CarpeaterState.loggedIn => l10n.mapCarpeaterReady,
      CarpeaterState.discovering => l10n.mapCarpeaterScanning,
      CarpeaterState.fetchingNeighbours => l10n.mapCarpeaterFetching,
      CarpeaterState.error => l10n.mapCarpeaterError,
    };
  }

  IconData _batteryIcon(int percent) {
    if (percent > 90) return Icons.battery_full;
    if (percent > 70) return Icons.battery_5_bar;
    if (percent > 50) return Icons.battery_4_bar;
    if (percent > 30) return Icons.battery_3_bar;
    if (percent > 15) return Icons.battery_2_bar;
    return Icons.battery_1_bar;
  }

  Color _batteryColor(int percent) {
    if (percent > 30) return Colors.green;
    if (percent > 15) return Colors.orange;
    return Colors.red;
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.color, required this.label, this.trailing});

  final Color color;
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 4), trailing!],
        ],
      ),
    );
  }
}
