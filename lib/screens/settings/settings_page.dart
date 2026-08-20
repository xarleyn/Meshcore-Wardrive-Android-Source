part of '../map_screen.dart';

typedef _SettingsCategoryBuilder =
    List<Widget> Function(BuildContext context, StateSetter setPageState);

class _SettingsCategory {
  const _SettingsCategory({
    required this.title,
    required this.icon,
    required this.builder,
  });

  final String title;
  final IconData icon;
  final _SettingsCategoryBuilder builder;
}

extension _SettingsPageNavigation on _MapScreenState {
  void _showSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SettingsScreen(
          version: appVersion,
          contentBuilder: (context, setPageState, scrollController) {
            final categories = _buildSettingsCategories(context);

            return ListView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                24 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              children: [
                _buildSettingsOverviewCard(context, categories.take(4)),
                const SizedBox(height: 16),
                _buildSettingsOverviewCard(context, categories.skip(4).take(4)),
                const SizedBox(height: 16),
                _buildSettingsOverviewCard(context, categories.skip(8).take(4)),
              ],
            );
          },
        ),
      ),
    );
  }

  List<_SettingsCategory> _buildSettingsCategories(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return [
      _SettingsCategory(
        title: l10n.settingsSectionMapDisplay,
        icon: Icons.map_outlined,
        builder: (_, setPageState) => _buildMapDisplaySettings(setPageState),
      ),
      _SettingsCategory(
        title: l10n.settingsSectionLocation,
        icon: Icons.my_location_outlined,
        builder: (context, setPageState) =>
            _buildLocationSettings(context, setPageState),
      ),
      _SettingsCategory(
        title: l10n.settingsSectionDiscovery,
        icon: Icons.radar_outlined,
        builder: (context, setPageState) =>
            _buildDiscoverySettings(context, setPageState),
      ),
      _SettingsCategory(
        title: l10n.settingsSectionFeedback,
        icon: Icons.notifications_outlined,
        builder: (_, setPageState) => _buildFeedbackSettings(setPageState),
      ),
      _SettingsCategory(
        title: l10n.settingsSectionCarpeater,
        icon: Icons.cell_tower,
        builder: (context, setPageState) =>
            _buildCarpeaterSettings(context, setPageState),
      ),
      _SettingsCategory(
        title: l10n.settingsSectionAppDevice,
        icon: Icons.tune,
        builder: (context, setPageState) =>
            _buildAppDeviceSettings(context, setPageState),
      ),
      _SettingsCategory(
        title: l10n.settingsSectionOnlineMap,
        icon: Icons.cloud_outlined,
        builder: (context, _) => _buildOnlineMapSettings(context),
      ),
      _SettingsCategory(
        title: l10n.settingsSectionStatistics,
        icon: Icons.query_stats,
        builder: (context, setPageState) =>
            _buildStatisticsSettings(context, setPageState),
      ),
      _SettingsCategory(
        title: l10n.settingsSectionDataManagement,
        icon: Icons.storage_outlined,
        builder: (context, setPageState) =>
            _buildDataManagementSettings(context, setPageState),
      ),
      _SettingsCategory(
        title: l10n.settingsSectionBackup,
        icon: Icons.settings_backup_restore,
        builder: (context, _) => _buildBackupSettings(context),
      ),
      _SettingsCategory(
        title: l10n.settingsSectionDiagnostics,
        icon: Icons.bug_report_outlined,
        builder: (context, _) => _buildDiagnosticsSettings(context),
      ),
      _SettingsCategory(
        title: l10n.settingsSectionAbout,
        icon: Icons.info_outline,
        builder: (context, _) => _buildAboutSettings(context),
      ),
    ];
  }

  Widget _buildSettingsOverviewCard(
    BuildContext context,
    Iterable<_SettingsCategory> categories,
  ) {
    return SettingsOverviewCard(
      children: [
        for (final category in categories)
          SettingsCategoryTile(
            title: category.title,
            icon: category.icon,
            onTap: () => _openSettingsCategory(context, category),
          ),
      ],
    );
  }

  void _openSettingsCategory(BuildContext context, _SettingsCategory category) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SettingsScreen.category(
          title: category.title,
          contentBuilder: (context, setPageState, scrollController) {
            final children = category.builder(context, setPageState).toList();
            if (children.isNotEmpty &&
                children.first is SettingsSectionHeader) {
              children.removeAt(0);
            }

            return ListView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                24 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              children: [SettingsContentCard(children: children)],
            );
          },
        ),
      ),
    );
  }
}
