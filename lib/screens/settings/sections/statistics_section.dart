import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../widgets/settings_section_header.dart';
import '../widgets/settings_text_input_dialog.dart';

class DrivingStatisticsValues {
  const DrivingStatisticsValues({
    required this.totalMeters,
    required this.vehicleMpg,
    required this.gasPricePerGallon,
  });

  final double totalMeters;
  final double? vehicleMpg;
  final double gasPricePerGallon;
}

List<Widget> buildStatisticsSettings(
  BuildContext context, {
  required Future<DrivingStatisticsValues> values,
  required double sessionMeters,
  required String distanceUnit,
  required String fuelUnit,
  required FutureOr<void> Function() onResetDistance,
  required FutureOr<void> Function(double? value) onVehicleMpgChanged,
  required FutureOr<void> Function(double value) onGasPriceChanged,
}) {
  final l10n = AppLocalizations.of(context);
  return [
    SettingsSectionHeader(
      title: l10n.settingsSectionStatistics,
      icon: Icons.query_stats,
    ),
    FutureBuilder<DrivingStatisticsValues>(
      future: values,
      builder: (context, snapshot) {
        final l10n = AppLocalizations.of(context);
        final loaded = snapshot.data;
        final totalMeters = loaded?.totalMeters ?? 0;
        final vehicleMpg = loaded?.vehicleMpg;
        final gasPrice = loaded?.gasPricePerGallon ?? 3.50;
        final grandTotalMeters = totalMeters + sessionMeters;
        final distanceDisplay = distanceUnit == 'miles'
            ? '${(grandTotalMeters / 1609.34).toStringAsFixed(2)} mi'
            : '${(grandTotalMeters / 1000).toStringAsFixed(2)} km';
        final fuelDisplay = _formatFuelUsage(
          l10n,
          totalMeters: grandTotalMeters,
          vehicleMpg: vehicleMpg,
          gasPricePerGallon: gasPrice,
          fuelUnit: fuelUnit,
        );

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
                    builder: (context) => AlertDialog(
                      title: Text(l10n.settingsResetDistance),
                      content: Text(l10n.settingsResetDistanceConfirm),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(l10n.settingsCancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(l10n.settingsReset),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) await onResetDistance();
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
                    ? (fuelUnit == 'metric'
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
                final isMetric = fuelUnit == 'metric';
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
                  await onVehicleMpgChanged(null);
                } else {
                  final inputValue = _parseNumber(input);
                  await onVehicleMpgChanged(
                    isMetric ? 235.215 / inputValue : inputValue,
                  );
                }
              },
            ),
            ListTile(
              title: Text(
                fuelUnit == 'metric'
                    ? l10n.settingsFuelPrice
                    : l10n.settingsGasPrice,
              ),
              subtitle: Text(
                fuelUnit == 'metric'
                    ? l10n.settingsFuelPriceDisplay(
                        (gasPrice / 3.78541).toStringAsFixed(2),
                      )
                    : l10n.settingsGasPriceDisplay(gasPrice.toStringAsFixed(2)),
              ),
              leading: const Icon(Icons.attach_money),
              trailing: const Icon(Icons.edit, size: 20),
              onTap: () async {
                final isMetric = fuelUnit == 'metric';
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
                  prefixText: r'$ ',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (text) => _validatePositiveNumber(text, l10n),
                );
                if (input == null) return;
                final inputPrice = _parseNumber(input);
                await onGasPriceChanged(
                  isMetric ? inputPrice * 3.78541 : inputPrice,
                );
              },
            ),
          ],
        );
      },
    ),
  ];
}

String? _formatFuelUsage(
  AppLocalizations l10n, {
  required double totalMeters,
  required double? vehicleMpg,
  required double gasPricePerGallon,
  required String fuelUnit,
}) {
  if (vehicleMpg == null || vehicleMpg <= 0) return null;
  final gallonsUsed = (totalMeters / 1609.34) / vehicleMpg;
  if (fuelUnit == 'metric') {
    final litresUsed = gallonsUsed * 3.78541;
    final pricePerLitre = gasPricePerGallon / 3.78541;
    return l10n.settingsFuelUsedLitres(
      litresUsed.toStringAsFixed(2),
      (litresUsed * pricePerLitre).toStringAsFixed(2),
      pricePerLitre.toStringAsFixed(2),
    );
  }
  return l10n.settingsFuelUsedGallons(
    gallonsUsed.toStringAsFixed(2),
    (gallonsUsed * gasPricePerGallon).toStringAsFixed(2),
    gasPricePerGallon.toStringAsFixed(2),
  );
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
