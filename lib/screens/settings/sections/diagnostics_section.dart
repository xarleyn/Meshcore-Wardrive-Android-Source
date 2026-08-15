part of '../../map_screen.dart';

extension _DiagnosticsSettingsSection on _MapScreenState {
  List<Widget> _buildDiagnosticsSettings(BuildContext context) => [
    const SettingsSectionHeader(
      title: 'Diagnostics',
      icon: Icons.bug_report_outlined,
    ),
    ListTile(
      title: const Text('Repeater Health'),
      subtitle: const Text('Per-repeater stats, trends & alerts'),
      leading: const Icon(Icons.health_and_safety),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RepeaterHealthScreen(samples: _samples),
          ),
        );
      },
    ),
    ListTile(
      title: const Text('Signal Trends'),
      subtitle: const Text('RSSI, SNR & response time charts'),
      leading: const Icon(Icons.show_chart),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SignalTrendScreen(samples: _samples),
          ),
        );
      },
    ),
    ListTile(
      title: const Text('Debug Diagnostics'),
      subtitle: const Text('View debug logs for troubleshooting'),
      leading: const Icon(Icons.bug_report),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () {
        Navigator.pop(context);
        _openDebugDiagnostics();
      },
    ),
  ];
}
