import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';

import '../l10n/app_locale.dart';
import '../l10n/generated/app_localizations.dart';
import 'settings_service.dart';

/// Wraps HomeWidget calls to push app state to the Android home screen widget.
class WidgetService {
  static const String _androidWidgetName = 'WardriveWidgetProvider';
  static const String _appGroupId = 'io.github.xarleyn.meshcore.wardrive';

  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  static Future<AppLocalizations> _l10n() async {
    return AppLocale.lookup(
      await SettingsService().getAppLocalePreference(),
      WidgetsBinding.instance.platformDispatcher.locale,
    );
  }

  /// Push current stats to the widget.
  static Future<void> update({
    required int sampleCount,
    required bool isTracking,
    required String connectionLabel,
    String successRate = '--',
    String distance = '--',
  }) async {
    final l10n = await _l10n();
    await HomeWidget.saveWidgetData('samples', sampleCount.toString());
    await HomeWidget.saveWidgetData(
      'status',
      isTracking ? l10n.widgetStatusTracking : l10n.widgetStatusIdle,
    );
    await HomeWidget.saveWidgetData('connection', connectionLabel);
    await HomeWidget.saveWidgetData('success_rate', successRate);
    await HomeWidget.saveWidgetData('distance', distance);
    await HomeWidget.updateWidget(androidName: _androidWidgetName);
  }

  /// Convenience: update only tracking status.
  static Future<void> updateTrackingStatus(bool isTracking) async {
    final l10n = await _l10n();
    await HomeWidget.saveWidgetData(
      'status',
      isTracking ? l10n.widgetStatusTracking : l10n.widgetStatusIdle,
    );
    await HomeWidget.updateWidget(androidName: _androidWidgetName);
  }

  /// Convenience: update only connection label.
  static Future<void> updateConnection(String label) async {
    await HomeWidget.saveWidgetData('connection', label);
    await HomeWidget.updateWidget(androidName: _androidWidgetName);
  }
}
