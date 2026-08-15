part of '../../map_screen.dart';

extension _StatisticsSettingsSection on _MapScreenState {
  List<Widget> _buildStatisticsSettings(
    BuildContext context,
    StateSetter setModalState,
  ) => [
    const SettingsSectionHeader(title: 'Statistics', icon: Icons.query_stats),
    FutureBuilder<List<double?>>(
      future: Future.wait([
        _settingsService.getTotalDistanceDriven(),
        _settingsService.getVehicleMpg(),
        _settingsService.getGasPrice(),
      ]),
      builder: (context, snapshot) {
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
            fuelDisplay =
                '${litresUsed.toStringAsFixed(2)} L (~\$${(litresUsed * pricePerLitre).toStringAsFixed(2)} @ \$${pricePerLitre.toStringAsFixed(2)}/L)';
          } else {
            fuelDisplay =
                '${gallonsUsed.toStringAsFixed(2)} gal (~\$${(gallonsUsed * gasPrice).toStringAsFixed(2)} @ \$${gasPrice.toStringAsFixed(2)}/gal)';
          }
        }

        return Column(
          children: [
            ListTile(
              title: const Text('Total Distance Driven'),
              subtitle: Text(distanceDisplay),
              leading: const Icon(Icons.straighten),
              trailing: IconButton(
                icon: const Icon(Icons.restart_alt, size: 20),
                tooltip: 'Reset',
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Reset Distance'),
                      content: const Text(
                        'Reset total distance driven to zero?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
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
                title: const Text('Estimated Fuel Used'),
                subtitle: Text(fuelDisplay),
                leading: const Icon(Icons.local_gas_station),
              ),
            ListTile(
              title: const Text('Vehicle Fuel Economy'),
              subtitle: Text(
                vehicleMpg != null
                    ? (_fuelUnit == 'metric'
                          ? '${(235.215 / vehicleMpg).toStringAsFixed(1)} L/100km'
                          : '${vehicleMpg.toStringAsFixed(1)} MPG')
                    : 'Not set',
              ),
              leading: const Icon(Icons.directions_car),
              trailing: const Icon(Icons.edit, size: 20),
              onTap: () async {
                final isMetric = _fuelUnit == 'metric';
                final displayValue = vehicleMpg != null && isMetric
                    ? (235.215 / vehicleMpg).toStringAsFixed(1)
                    : vehicleMpg?.toStringAsFixed(1) ?? '';
                final controller = TextEditingController(text: displayValue);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Vehicle Fuel Economy'),
                    content: TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: isMetric
                            ? 'Litres per 100km (L/100km)'
                            : 'Miles Per Gallon (MPG)',
                        hintText: isMetric ? 'e.g., 9.4' : 'e.g., 25.0',
                      ),
                      autofocus: true,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      if (vehicleMpg != null)
                        TextButton(
                          onPressed: () async {
                            await _settingsService.setVehicleMpg(null);
                            Navigator.pop(ctx, true);
                          },
                          child: const Text('Clear'),
                        ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && controller.text.isNotEmpty) {
                  final inputValue = double.tryParse(controller.text);
                  if (inputValue != null && inputValue > 0) {
                    // Convert L/100km to MPG for internal storage
                    final mpgToStore = isMetric
                        ? 235.215 / inputValue
                        : inputValue;
                    await _settingsService.setVehicleMpg(mpgToStore);
                  }
                }
                setModalState(() {});
              },
            ),
            ListTile(
              title: Text(_fuelUnit == 'metric' ? 'Fuel Price' : 'Gas Price'),
              subtitle: Text(
                _fuelUnit == 'metric'
                    ? '\$${(gasPrice / 3.78541).toStringAsFixed(2)}/L'
                    : '\$${gasPrice.toStringAsFixed(2)}/gal',
              ),
              leading: const Icon(Icons.attach_money),
              trailing: const Icon(Icons.edit, size: 20),
              onTap: () async {
                final isMetric = _fuelUnit == 'metric';
                final displayPrice = isMetric
                    ? (gasPrice / 3.78541).toStringAsFixed(2)
                    : gasPrice.toStringAsFixed(2);
                final controller = TextEditingController(text: displayPrice);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(isMetric ? 'Fuel Price' : 'Gas Price'),
                    content: TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: isMetric
                            ? 'Price per Litre'
                            : 'Price per Gallon',
                        hintText: isMetric ? 'e.g., 1.85' : 'e.g., 3.50',
                        prefixText: '\$ ',
                      ),
                      autofocus: true,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && controller.text.isNotEmpty) {
                  final inputPrice = double.tryParse(controller.text);
                  if (inputPrice != null && inputPrice > 0) {
                    // Convert $/L to $/gal for internal storage
                    final priceToStore = isMetric
                        ? inputPrice * 3.78541
                        : inputPrice;
                    await _settingsService.setGasPrice(priceToStore);
                  }
                }
                setModalState(() {});
              },
            ),
          ],
        );
      },
    ),
  ];
}
