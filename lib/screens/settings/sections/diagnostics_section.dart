import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../models/models.dart';
import '../../repeater_health_screen.dart';
import '../../signal_trend_screen.dart';
import '../widgets/settings_section_header.dart';

List<Widget> buildDiagnosticsSettings(
  BuildContext context, {
  required List<Sample> samples,
  required VoidCallback onOpenDebugDiagnostics,
}) {
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
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => RepeaterHealthScreen(samples: samples),
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
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => SignalTrendScreen(samples: samples),
          ),
        );
      },
    ),
    ListTile(
      title: Text(l10n.settingsDebugDiagnostics),
      subtitle: Text(l10n.settingsDebugDiagnosticsSubtitle),
      leading: const Icon(Icons.bug_report),
      trailing: const Icon(Icons.arrow_forward),
      onTap: onOpenDebugDiagnostics,
    ),
  ];
}
