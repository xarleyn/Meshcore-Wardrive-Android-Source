part of '../../map_screen.dart';

extension _LocationQualitySettingsSection on _MapScreenState {
  void _openLocationQualitySettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SettingsScreen.category(
          title: 'Location Quality Filters',
          contentBuilder: (context, setPageState, scrollController) => ListView(
            controller: scrollController,
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            children: _buildLocationQualitySettings(setPageState),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLocationQualitySettings(StateSetter setPageState) => [
    const SettingsSectionHeader(title: 'Thresholds', icon: Icons.gps_fixed),
    ListTile(
      title: const Text('Maximum Horizontal Error'),
      subtitle: const Text('Reject positions with worse reported accuracy'),
      trailing: Text(
        '${_formatLocationQualityValue(_locationQualitySettings.maxHorizontalAccuracyMeters)} m',
      ),
      onTap: () => _editLocationQualityValue(
        title: 'Maximum Horizontal Error',
        description:
            'Positions whose reported horizontal error is larger than this '
            'value are ignored.',
        unit: 'm',
        displayedValue: _locationQualitySettings.maxHorizontalAccuracyMeters,
        update: (value) => _locationQualitySettings.copyWith(
          maxHorizontalAccuracyMeters: value,
        ),
        setModalState: setPageState,
      ),
    ),
    ListTile(
      title: const Text('Airborne Altitude'),
      subtitle: const Text('Altitude used together with airborne speed'),
      trailing: Text(
        '${_formatLocationQualityValue(_locationQualitySettings.airborneAltitudeMeters)} m',
      ),
      onTap: () => _editLocationQualityValue(
        title: 'Airborne Altitude',
        description:
            'At or above this altitude, a position is ignored only when it '
            'also exceeds the airborne speed.',
        unit: 'm',
        displayedValue: _locationQualitySettings.airborneAltitudeMeters,
        update: (value) =>
            _locationQualitySettings.copyWith(airborneAltitudeMeters: value),
        setModalState: setPageState,
      ),
    ),
    ListTile(
      title: const Text('Airborne Speed'),
      subtitle: const Text('Speed used together with airborne altitude'),
      trailing: Text(
        '${_formatLocationQualityValue(_locationQualitySettings.airborneSpeedMetersPerSecond * 3.6)} km/h',
      ),
      onTap: () => _editLocationQualityValue(
        title: 'Airborne Speed',
        description:
            'At or above this speed, a high-altitude position is treated as '
            'a probable flight.',
        unit: 'km/h',
        displayedValue:
            _locationQualitySettings.airborneSpeedMetersPerSecond * 3.6,
        update: (value) => _locationQualitySettings.copyWith(
          airborneSpeedMetersPerSecond: value / 3.6,
        ),
        setModalState: setPageState,
      ),
    ),
    ListTile(
      title: const Text('Maximum Wardrive Speed'),
      subtitle: const Text('Reject positions moving faster than this'),
      trailing: Text(
        '${_formatLocationQualityValue(_locationQualitySettings.maxWardriveSpeedMetersPerSecond * 3.6)} km/h',
      ),
      onTap: () => _editLocationQualityValue(
        title: 'Maximum Wardrive Speed',
        description:
            'Positions moving at or above this speed are ignored as '
            'implausible wardrive data.',
        unit: 'km/h',
        displayedValue:
            _locationQualitySettings.maxWardriveSpeedMetersPerSecond * 3.6,
        update: (value) => _locationQualitySettings.copyWith(
          maxWardriveSpeedMetersPerSecond: value / 3.6,
        ),
        setModalState: setPageState,
      ),
    ),
    Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, bottom: 8),
        child: TextButton.icon(
          onPressed: () => _resetLocationQualitySettings(setPageState),
          icon: const Icon(Icons.restore),
          label: const Text('Restore Defaults'),
        ),
      ),
    ),
  ];
}
