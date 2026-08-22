import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

export 'widgets/settings_section_header.dart';
export 'widgets/settings_text_input_dialog.dart';
export 'widgets/upload_endpoint_selection_dialog.dart';

typedef SettingsContentBuilder =
    Widget Function(
      BuildContext context,
      StateSetter setPageState,
      ScrollController scrollController,
    );

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.version,
    required this.contentBuilder,
    this.title,
    super.key,
  });

  const SettingsScreen.category({
    required String this.title,
    required this.contentBuilder,
    super.key,
  }) : version = null;

  final String? title;
  final String? version;
  final SettingsContentBuilder contentBuilder;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final isOverview = widget.version != null;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        toolbarHeight: isOverview ? 76 : 64,
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(widget.title ?? l10n.settingsTitle),
        titleTextStyle:
            (isOverview
                    ? Theme.of(context).textTheme.headlineMedium
                    : Theme.of(context).textTheme.titleLarge)
                ?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
        actions: [
          if (widget.version case final version?)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Text(
                  'v$version',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: StatefulBuilder(
        builder: (context, setPageState) {
          return SafeArea(
            child: Scrollbar(
              controller: _scrollController,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: widget.contentBuilder(
                    context,
                    setPageState,
                    _scrollController,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SettingsOverviewGroup extends StatelessWidget {
  const SettingsOverviewGroup({
    required this.title,
    required this.children,
    super.key,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
          SettingsOverviewCard(children: children),
        ],
      ),
    );
  }
}

class SettingsOverviewCard extends StatelessWidget {
  const SettingsOverviewCard({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              Divider(
                height: 1,
                indent: 56,
                endIndent: 20,
                color: colors.outlineVariant.withValues(alpha: 0.55),
              ),
          ],
        ],
      ),
    );
  }
}

class SettingsCategoryTile extends StatelessWidget {
  const SettingsCategoryTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Icon(icon, color: colors.onSurfaceVariant, size: 24),
      title: Text(title),
      subtitle: Text(subtitle),
      titleTextStyle: theme.textTheme.titleMedium?.copyWith(
        color: colors.onSurface,
        fontWeight: FontWeight.w500,
      ),
      subtitleTextStyle: theme.textTheme.bodySmall?.copyWith(
        color: colors.onSurfaceVariant,
      ),
      trailing: Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
      onTap: onTap,
    );
  }
}

class SettingsContentCard extends StatelessWidget {
  const SettingsContentCard({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: ListTileTheme(
        data: ListTileThemeData(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          iconColor: colors.primary,
          minVerticalPadding: 12,
          titleTextStyle: theme.textTheme.titleMedium?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w500,
          ),
          subtitleTextStyle: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}
