part of '../../map_screen.dart';

extension _DiagnosticsSettingsSection on _MapScreenState {
  List<Widget> _buildDiagnosticsSettings(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      SettingsSectionHeader(
        title: l10n.settingsSectionDiagnostics,
        icon: Icons.bug_report_outlined,
      ),
      ListTile(
        title: Text(l10n.settingsRepeaterHealth),
        subtitle: Text(l10n.settingsRepeaterHealthSubtitle),
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
        title: Text(l10n.settingsSignalTrends),
        subtitle: Text(l10n.settingsSignalTrendsSubtitle),
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
        title: Text(l10n.settingsDebugDiagnostics),
        subtitle: Text(l10n.settingsDebugDiagnosticsSubtitle),
        leading: const Icon(Icons.bug_report),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () {
          Navigator.pop(context);
          _openDebugDiagnostics();
        },
      ),
    ];
  }
}
