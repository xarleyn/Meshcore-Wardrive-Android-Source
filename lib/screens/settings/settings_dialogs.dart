part of '../map_screen.dart';

extension _SettingsDialogs on _MapScreenState {
  String _getPingIntervalDescription() {
    if (_pingIntervalMeters < 100) {
      return '${_pingIntervalMeters.toInt()} meters (frequent)';
    } else if (_pingIntervalMeters < 1000) {
      return '${_pingIntervalMeters.toInt()} meters';
    } else {
      final miles = (_pingIntervalMeters / 1609.34).toStringAsFixed(1);
      return '$miles miles (${_pingIntervalMeters.toInt()}m)';
    }
  }

  Future<void> _setPingInterval() async {
    String? selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ping Interval'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How often should pings be sent?'),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Frequent'),
              subtitle: const Text('Every 50 meters'),
              onTap: () => Navigator.pop(context, '50'),
            ),
            ListTile(
              title: const Text('Normal'),
              subtitle: const Text('Every 200 meters (~0.12 miles)'),
              onTap: () => Navigator.pop(context, '200'),
            ),
            ListTile(
              title: const Text('Sparse'),
              subtitle: const Text('Every 0.5 miles (805 meters)'),
              onTap: () => Navigator.pop(context, '805'),
            ),
            ListTile(
              title: const Text('Very Sparse'),
              subtitle: const Text('Every 1 mile (1609 meters)'),
              onTap: () => Navigator.pop(context, '1609'),
            ),
          ],
        ),
      ),
    );

    if (selected != null) {
      final interval = double.parse(selected);
      _updateMapState(() {
        _pingIntervalMeters = interval;
      });
      // Update location service ping interval
      _locationService.setPingInterval(_pingIntervalMeters);
      await _settingsService.setPingInterval(interval);
      _showSnackBar('Ping interval: ${_getPingIntervalDescription()}');
    }
  }

  String _getCoverageResolutionDescription() {
    switch (_coveragePrecision) {
      case 4:
        return 'Regional (~20km squares)';
      case 5:
        return 'City-level (~5km squares)';
      case 6:
        return 'Neighborhood (~1.2km squares)';
      case 7:
        return 'Street-level (~153m squares)';
      case 8:
        return 'Building-level (~38m squares)';
      default:
        return 'Unknown';
    }
  }

  Future<void> _setCoverageResolution() async {
    String? selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coverage Resolution'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose the size of coverage squares:'),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Regional'),
              subtitle: const Text('~20km squares (precision 4)'),
              onTap: () => Navigator.pop(context, '4'),
            ),
            ListTile(
              title: const Text('City-level'),
              subtitle: const Text('~5km squares (precision 5)'),
              onTap: () => Navigator.pop(context, '5'),
            ),
            ListTile(
              title: const Text('Neighborhood'),
              subtitle: const Text('~1.2km squares (precision 6, default)'),
              onTap: () => Navigator.pop(context, '6'),
            ),
            ListTile(
              title: const Text('Street-level'),
              subtitle: const Text('~153m squares (precision 7)'),
              onTap: () => Navigator.pop(context, '7'),
            ),
            ListTile(
              title: const Text('Building-level'),
              subtitle: const Text('~38m squares (precision 8, detailed)'),
              onTap: () => Navigator.pop(context, '8'),
            ),
          ],
        ),
      ),
    );

    if (selected != null) {
      final precision = int.parse(selected);
      _updateMapState(() {
        _coveragePrecision = precision;
      });
      await _settingsService.setCoveragePrecision(precision);
      // Force reaggregation with new precision
      _lastAggregatedSampleCount = -1;
      await _loadSamples();
      _showSnackBar(
        'Coverage resolution: ${_getCoverageResolutionDescription()}',
      );
    }
  }

  Future<void> _setIgnoredRepeater() async {
    final controller = TextEditingController(
      text: _ignoredRepeaterPrefix ?? '',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ignore Repeaters'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Filter out responses from your mobile repeater(s) to avoid false coverage.\n\n'
              'Enter repeater prefixes separated by commas:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Repeater Prefixes',
                hintText: 'e.g., 7E, A4F, BAD5',
                isDense: true,
              ),
              textCapitalization: TextCapitalization.characters,
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefix = controller.text.isEmpty ? null : controller.text;
      _updateMapState(() {
        _ignoredRepeaterPrefix = prefix;
      });
      _locationService.loraCompanion.setIgnoredRepeaterPrefix(
        _ignoredRepeaterPrefix,
      );
      await _settingsService.setIgnoredRepeaterPrefix(prefix);
      _showSnackBar('Repeater prefix updated');
    }
  }

  Future<void> _setIncludeOnlyRepeaters() async {
    final controller = TextEditingController(text: _includeOnlyRepeaters ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Include Only Repeaters'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Show ONLY samples from specific repeaters (whitelist). Useful for testing your own infrastructure.\n\n'
              'Enter repeater prefixes separated by commas:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Repeater Prefixes',
                hintText: 'e.g., 7E3A, A4F2, 8B',
                isDense: true,
              ),
              textCapitalization: TextCapitalization.characters,
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefixes = controller.text.isEmpty ? null : controller.text;
      _updateMapState(() {
        _includeOnlyRepeaters = prefixes;
      });
      await _settingsService.setIncludeOnlyRepeaters(prefixes);
      _showSnackBar('Repeater whitelist updated');
    }
  }

  String _formatLocationQualityValue(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }

  Future<void> _editLocationQualityValue({
    required String title,
    required String description,
    required String unit,
    required double displayedValue,
    required LocationQualitySettings Function(double value) update,
    required StateSetter setModalState,
  }) async {
    final controller = TextEditingController(
      text: _formatLocationQualityValue(displayedValue),
    );
    final formKey = GlobalKey<FormState>();
    final value = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(description),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(suffixText: unit),
                validator: (text) {
                  final parsed = double.tryParse(
                    (text ?? '').trim().replaceAll(',', '.'),
                  );
                  if (parsed == null || !parsed.isFinite || parsed <= 0) {
                    return 'Enter a number greater than zero';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              Navigator.pop(
                dialogContext,
                double.parse(controller.text.trim().replaceAll(',', '.')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || !mounted) return;

    final settings = update(value);
    await _settingsService.setLocationQualitySettings(settings);
    if (!mounted) return;
    _updateMapState(() => _locationQualitySettings = settings);
    _locationService.setLocationQualitySettings(settings);
    setModalState(() {});
  }

  Future<void> _resetLocationQualitySettings(StateSetter setModalState) async {
    const settings = LocationQualitySettings();
    await _settingsService.setLocationQualitySettings(settings);
    if (!mounted) return;
    _updateMapState(() => _locationQualitySettings = settings);
    _locationService.setLocationQualitySettings(settings);
    setModalState(() {});
    _showSnackBar('Location quality filters reset');
  }
}
