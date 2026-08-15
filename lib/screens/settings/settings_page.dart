part of '../map_screen.dart';

extension _SettingsPageNavigation on _MapScreenState {
  void _showSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SettingsScreen(
          version: appVersion,
          contentBuilder: (context, setModalState, scrollController) => Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 0,
              bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._buildMapDisplaySettings(setModalState),
                  ..._buildLocationSettings(context, setModalState),
                  ..._buildFeedbackSettings(setModalState),
                  ..._buildCarpeaterSettings(context, setModalState),
                  ..._buildAppDeviceSettings(context, setModalState),
                  ..._buildDiscoverySettings(context, setModalState),
                  ..._buildStatisticsSettings(context, setModalState),
                  ..._buildDataManagementSettings(context, setModalState),
                  ..._buildBackupSettings(context),
                  ..._buildDiagnosticsSettings(context),
                  ..._buildOnlineMapSettings(context),
                  ..._buildAboutSettings(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
