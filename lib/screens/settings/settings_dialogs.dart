part of '../map_screen.dart';

extension _SettingsDialogs on _MapScreenState {
  String _getPingIntervalDescription() {
    final l10n = AppLocalizations.of(context);
    if (_pingIntervalMeters < 100) {
      return l10n.settingsPingIntervalMetersFrequent(
        _pingIntervalMeters.toInt(),
      );
    } else if (_pingIntervalMeters < 1000) {
      return l10n.settingsPingIntervalMeters(_pingIntervalMeters.toInt());
    } else {
      final miles = (_pingIntervalMeters / 1609.34).toStringAsFixed(1);
      return l10n.settingsPingIntervalMiles(miles, _pingIntervalMeters.toInt());
    }
  }

  Future<void> _setPingInterval() async {
    final l10n = AppLocalizations.of(context);
    String? selected = await showDialog<String>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.settingsPingInterval),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.settingsPingIntervalPrompt),
              const SizedBox(height: 16),
              ListTile(
                title: Text(l10n.settingsPingFrequent),
                subtitle: Text(l10n.settingsPingFrequentSubtitle),
                onTap: () => Navigator.pop(context, '50'),
              ),
              ListTile(
                title: Text(l10n.settingsPingNormal),
                subtitle: Text(l10n.settingsPingNormalSubtitle),
                onTap: () => Navigator.pop(context, '200'),
              ),
              ListTile(
                title: Text(l10n.settingsPingSparse),
                subtitle: Text(l10n.settingsPingSparseSubtitle),
                onTap: () => Navigator.pop(context, '805'),
              ),
              ListTile(
                title: Text(l10n.settingsPingVerySparse),
                subtitle: Text(l10n.settingsPingVerySparseSubtitle),
                onTap: () => Navigator.pop(context, '1609'),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      final interval = double.parse(selected);
      _updateMapState(() {
        _pingIntervalMeters = interval;
      });
      // Update location service ping interval
      _locationService.setPingInterval(_pingIntervalMeters);
      await _settingsService.setPingInterval(interval);
      _showSnackBar(
        l10n.settingsPingIntervalSet(_getPingIntervalDescription()),
      );
    }
  }

  String _getCoverageResolutionDescription() {
    final l10n = AppLocalizations.of(context);
    switch (_coveragePrecision) {
      case 4:
        return l10n.settingsCoverageRegionalDesc;
      case 5:
        return l10n.settingsCoverageCityDesc;
      case 6:
        return l10n.settingsCoverageNeighborhoodDesc;
      case 7:
        return l10n.settingsCoverageStreetDesc;
      case 8:
        return l10n.settingsCoverageBuildingDesc;
      default:
        return l10n.settingsUnknown;
    }
  }

  Future<void> _setCoverageResolution() async {
    final l10n = AppLocalizations.of(context);
    String? selected = await showDialog<String>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.settingsCoverageResolution),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.settingsCoverageResolutionPrompt),
              const SizedBox(height: 16),
              ListTile(
                title: Text(l10n.settingsCoverageRegional),
                subtitle: Text(l10n.settingsCoverageRegionalSubtitle),
                onTap: () => Navigator.pop(context, '4'),
              ),
              ListTile(
                title: Text(l10n.settingsCoverageCity),
                subtitle: Text(l10n.settingsCoverageCitySubtitle),
                onTap: () => Navigator.pop(context, '5'),
              ),
              ListTile(
                title: Text(l10n.settingsCoverageNeighborhood),
                subtitle: Text(l10n.settingsCoverageNeighborhoodSubtitle),
                onTap: () => Navigator.pop(context, '6'),
              ),
              ListTile(
                title: Text(l10n.settingsCoverageStreet),
                subtitle: Text(l10n.settingsCoverageStreetSubtitle),
                onTap: () => Navigator.pop(context, '7'),
              ),
              ListTile(
                title: Text(l10n.settingsCoverageBuilding),
                subtitle: Text(l10n.settingsCoverageBuildingSubtitle),
                onTap: () => Navigator.pop(context, '8'),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      final precision = int.parse(selected);
      _updateMapState(() {
        _coveragePrecision = precision;
      });
      await _settingsService.setCoveragePrecision(precision);
      // Force reaggregation with new precision
      _mapDataController.invalidate();
      await _loadSamples();
      _showSnackBar(
        l10n.settingsCoverageResolutionSet(_getCoverageResolutionDescription()),
      );
    }
  }

  Future<void> _setIgnoredRepeater() async {
    final l10n = AppLocalizations.of(context);
    final input = await showSettingsTextInputDialog(
      context: context,
      title: l10n.settingsIgnoreRepeaters,
      initialValue: _ignoredRepeaterPrefix ?? '',
      labelText: l10n.settingsRepeaterPrefixes,
      hintText: l10n.settingsIgnoreRepeaterHint,
      description: l10n.settingsIgnoreRepeaterDescription,
      textCapitalization: TextCapitalization.characters,
      maxLines: 2,
    );

    if (input != null) {
      final prefix = input.trim().isEmpty ? null : input.trim();
      _updateMapState(() {
        _ignoredRepeaterPrefix = prefix;
      });
      _locationService.loraCompanion.setIgnoredRepeaterPrefix(
        _ignoredRepeaterPrefix,
      );
      await _settingsService.setIgnoredRepeaterPrefix(prefix);
      _showSnackBar(l10n.settingsRepeaterPrefixUpdated);
    }
  }

  Future<void> _setIncludeOnlyRepeaters() async {
    final l10n = AppLocalizations.of(context);
    final input = await showSettingsTextInputDialog(
      context: context,
      title: l10n.settingsIncludeOnlyRepeaters,
      initialValue: _includeOnlyRepeaters ?? '',
      labelText: l10n.settingsRepeaterPrefixes,
      hintText: l10n.settingsIncludeOnlyHint,
      description: l10n.settingsIncludeOnlyDescription,
      textCapitalization: TextCapitalization.characters,
      maxLines: 2,
    );

    if (input != null) {
      final prefixes = input.trim().isEmpty ? null : input.trim();
      _updateMapState(() {
        _includeOnlyRepeaters = prefixes;
      });
      await _settingsService.setIncludeOnlyRepeaters(prefixes);
      _showSnackBar(l10n.settingsRepeaterWhitelistUpdated);
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
    final l10n = AppLocalizations.of(context);
    final input = await showSettingsTextInputDialog(
      context: context,
      title: title,
      initialValue: _formatLocationQualityValue(displayedValue),
      labelText: title,
      description: description,
      suffixText: unit,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (text) {
        final parsed = double.tryParse(
          (text ?? '').trim().replaceAll(',', '.'),
        );
        if (parsed == null || !parsed.isFinite || parsed <= 0) {
          return l10n.settingsEnterNumberGreaterThanZero;
        }
        return null;
      },
    );
    if (input == null || !mounted) return;

    final value = double.parse(input.trim().replaceAll(',', '.'));
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
    _showSnackBar(
      AppLocalizations.of(context).settingsLocationQualityResetSnack,
    );
  }
}
