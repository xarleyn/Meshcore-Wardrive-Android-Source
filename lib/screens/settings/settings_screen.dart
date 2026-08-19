import 'package:flutter/material.dart';

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
    this.title = 'Settings',
    super.key,
  });

  const SettingsScreen.category({
    required this.title,
    required this.contentBuilder,
    super.key,
  }) : version = null;

  final String title;
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
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
