part of '../../map_screen.dart';

extension _StatisticsSettingsSection on _MapScreenState {
  List<Widget> _buildStatisticsSettings(
    BuildContext context,
    StateSetter setModalState,
  ) {
    final l10n = AppLocalizations.of(context);
    return [
      SettingsSectionHeader(
        title: l10n.settingsSectionStatistics,
        icon: Icons.query_stats,
      ),
      FutureBuilder<List<double?>>(
        future: Future.wait([
          _settingsService.getTotalDistanceDriven(),
          _settingsService.getVehicleMpg(),
          _settingsService.getGasPrice(),
        ]),
        builder: (context, snapshot) {
          final l10n = AppLocalizations.of(context);
          final totalMeters = snapshot.data?[0] ?? 0.0;
          final vehicleMpg = snapshot.data?[1];
          final gasPrice = snapshot.data?[2] ?? 3.50;
          final sessionMeters = _isTracking
              ? _locationService.totalDistanceMeters
              : 0.0;
          final grandTotalMeters = totalMeters + sessionMeters;
          final distanceDisplay = _distanceUnit == 'miles'
              ? '${(grandTotalMeters / 1609.34).toStringAsFixed(2)} mi'
              : '${(grandTotalMeters / 1000.0).toStringAsFixed(2)} km';

          // Estimate fuel usage
          String? fuelDisplay;
          if (vehicleMpg != null && vehicleMpg > 0) {
            final totalMiles = grandTotalMeters / 1609.34;
            final gallonsUsed = totalMiles / vehicleMpg;
            if (_fuelUnit == 'metric') {
              final litresUsed = gallonsUsed * 3.78541;
              final pricePerLitre = gasPrice / 3.78541;
              fuelDisplay = l10n.settingsFuelUsedLitres(
                litresUsed.toStringAsFixed(2),
                (litresUsed * pricePerLitre).toStringAsFixed(2),
                pricePerLitre.toStringAsFixed(2),
              );
            } else {
              fuelDisplay = l10n.settingsFuelUsedGallons(
                gallonsUsed.toStringAsFixed(2),
                (gallonsUsed * gasPrice).toStringAsFixed(2),
                gasPrice.toStringAsFixed(2),
              );
            }
          }

          return Column(
            children: [
              ListTile(
                title: Text(l10n.settingsTotalDistanceDriven),
                subtitle: Text(distanceDisplay),
                leading: const Icon(Icons.straighten),
                trailing: IconButton(
                  icon: const Icon(Icons.restart_alt, size: 20),
                  tooltip: l10n.settingsResetTooltip,
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) {
                        final l10n = AppLocalizations.of(ctx);
                        return AlertDialog(
                          title: Text(l10n.settingsResetDistance),
                          content: Text(l10n.settingsResetDistanceConfirm),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(l10n.settingsCancel),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(l10n.settingsReset),
                            ),
                          ],
                        );
                      },
                    );
                    if (confirmed == true) {
                      await _settingsService.resetTotalDistanceDriven();
                      setModalState(() {});
                    }
                  },
                ),
              ),
              if (fuelDisplay != null)
                ListTile(
                  title: Text(l10n.settingsEstimatedFuelUsed),
                  subtitle: Text(fuelDisplay),
                  leading: const Icon(Icons.local_gas_station),
                ),
              ListTile(
                title: Text(l10n.settingsVehicleFuelEconomy),
                subtitle: Text(
                  vehicleMpg != null
                      ? (_fuelUnit == 'metric'
                            ? l10n.settingsFuelEconomyMetric(
                                (235.215 / vehicleMpg).toStringAsFixed(1),
                              )
                            : l10n.settingsFuelEconomyImperial(
                                vehicleMpg.toStringAsFixed(1),
                              ))
                      : l10n.settingsNotSet,
                ),
                leading: const Icon(Icons.directions_car),
                trailing: const Icon(Icons.edit, size: 20),
                onTap: () async {
                  final isMetric = _fuelUnit == 'metric';
                  final displayValue = vehicleMpg != null && isMetric
                      ? (235.215 / vehicleMpg).toStringAsFixed(1)
                      : vehicleMpg?.toStringAsFixed(1) ?? '';
                  final input = await showSettingsTextInputDialog(
                    context: context,
                    title: l10n.settingsVehicleFuelEconomy,
                    initialValue: displayValue,
                    labelText: isMetric
                        ? l10n.settingsLitresPer100km
                        : l10n.settingsMilesPerGallon,
                    hintText: isMetric
                        ? l10n.settingsHintMetricEconomy
                        : l10n.settingsHintImperialEconomy,
                    allowClear: vehicleMpg != null,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (text) => _validatePositiveNumber(text, l10n),
                  );
                  if (input == null) return;
                  if (input.isEmpty) {
                    await _settingsService.setVehicleMpg(null);
                  } else {
                    final inputValue = _parseNumber(input);
                    final mpgToStore = isMetric
                        ? 235.215 / inputValue
                        : inputValue;
                    await _settingsService.setVehicleMpg(mpgToStore);
                  }
                  setModalState(() {});
                },
              ),
              ListTile(
                title: Text(
                  _fuelUnit == 'metric'
                      ? l10n.settingsFuelPrice
                      : l10n.settingsGasPrice,
                ),
                subtitle: Text(
                  _fuelUnit == 'metric'
                      ? l10n.settingsFuelPriceDisplay(
                          (gasPrice / 3.78541).toStringAsFixed(2),
                        )
                      : l10n.settingsGasPriceDisplay(
                          gasPrice.toStringAsFixed(2),
                        ),
                ),
                leading: const Icon(Icons.attach_money),
                trailing: const Icon(Icons.edit, size: 20),
                onTap: () async {
                  final isMetric = _fuelUnit == 'metric';
                  final displayPrice = isMetric
                      ? (gasPrice / 3.78541).toStringAsFixed(2)
                      : gasPrice.toStringAsFixed(2);
                  final input = await showSettingsTextInputDialog(
                    context: context,
                    title: isMetric
                        ? l10n.settingsFuelPrice
                        : l10n.settingsGasPrice,
                    initialValue: displayPrice,
                    labelText: isMetric
                        ? l10n.settingsPricePerLitre
                        : l10n.settingsPricePerGallon,
                    hintText: isMetric
                        ? l10n.settingsHintFuelPrice
                        : l10n.settingsHintGasPrice,
                    prefixText: '\$ ',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (text) => _validatePositiveNumber(text, l10n),
                  );
                  if (input == null) return;
                  final inputPrice = _parseNumber(input);
                  final priceToStore = isMetric
                      ? inputPrice * 3.78541
                      : inputPrice;
                  await _settingsService.setGasPrice(priceToStore);
                  setModalState(() {});
                },
              ),
            ],
          );
        },
      ),
    ];
  }

  String? _validatePositiveNumber(String? text, AppLocalizations l10n) {
    final value = double.tryParse((text ?? '').trim().replaceAll(',', '.'));
    if (value == null || !value.isFinite || value <= 0) {
      return l10n.settingsEnterNumberGreaterThanZero;
    }
    return null;
  }

  double _parseNumber(String text) {
    return double.parse(text.trim().replaceAll(',', '.'));
  }
}
