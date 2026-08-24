import 'generated/app_localizations.dart';

class AchievementCopy {
  const AchievementCopy({required this.title, required this.description});

  final String title;
  final String description;
}

/// Localized word for the user's [distanceUnit] ('miles' or 'km') used in
/// distance achievement descriptions.
String achievementDistanceUnitWord(AppLocalizations l10n, String distanceUnit) {
  return distanceUnit == 'km'
      ? l10n.achievementDistanceUnitKm
      : l10n.achievementDistanceUnitMiles;
}

/// Localized title and description for a persisted achievement [id].
///
/// Distance achievements describe their thresholds in [distanceUnit] — the
/// selected distance unit ('miles' or 'km'). Threshold numbers are shared by
/// both units (100 miles == 100 km), so no conversion is applied.
AchievementCopy achievementCopy(
  AppLocalizations l10n,
  String id, {
  String distanceUnit = 'km',
}) {
  final unitWord = achievementDistanceUnitWord(l10n, distanceUnit);
  return switch (id) {
    'first_ping' => AchievementCopy(
      title: l10n.achievementFirstPingTitle,
      description: l10n.achievementFirstPingDescription,
    ),
    'pings_100' => AchievementCopy(
      title: l10n.achievementPings100Title,
      description: l10n.achievementPings100Description,
    ),
    'pings_1000' => AchievementCopy(
      title: l10n.achievementPings1000Title,
      description: l10n.achievementPings1000Description,
    ),
    'pings_10000' => AchievementCopy(
      title: l10n.achievementPings10000Title,
      description: l10n.achievementPings10000Description,
    ),
    'first_repeater' => AchievementCopy(
      title: l10n.achievementFirstRepeaterTitle,
      description: l10n.achievementFirstRepeaterDescription,
    ),
    'repeaters_10' => AchievementCopy(
      title: l10n.achievementRepeaters10Title,
      description: l10n.achievementRepeaters10Description,
    ),
    'repeaters_50' => AchievementCopy(
      title: l10n.achievementRepeaters50Title,
      description: l10n.achievementRepeaters50Description,
    ),
    'miles_10' => AchievementCopy(
      title: l10n.achievementMiles10Title,
      description: l10n.achievementMiles10Description(unitWord),
    ),
    'miles_100' => AchievementCopy(
      title: l10n.achievementMiles100Title,
      description: l10n.achievementMiles100Description(unitWord),
    ),
    'miles_500' => AchievementCopy(
      title: l10n.achievementMiles500Title,
      description: l10n.achievementMiles500Description(unitWord),
    ),
    'cells_50' => AchievementCopy(
      title: l10n.achievementCells50Title,
      description: l10n.achievementCells50Description,
    ),
    'cells_500' => AchievementCopy(
      title: l10n.achievementCells500Title,
      description: l10n.achievementCells500Description,
    ),
    'first_session' => AchievementCopy(
      title: l10n.achievementFirstSessionTitle,
      description: l10n.achievementFirstSessionDescription,
    ),
    'sessions_50' => AchievementCopy(
      title: l10n.achievementSessions50Title,
      description: l10n.achievementSessions50Description,
    ),
    'smolensk_legend' => AchievementCopy(
      title: l10n.achievementSmolenskLegendTitle,
      description: l10n.achievementSmolenskLegendDescription,
    ),
    _ => throw ArgumentError.value(id, 'id', 'Unknown achievement id'),
  };
}
