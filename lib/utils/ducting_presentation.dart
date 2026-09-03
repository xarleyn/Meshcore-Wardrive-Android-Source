import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/ducting_service.dart';

/// Presentation helpers for ducting risk values.

/// Localized label for a ducting risk value.
String localizedDuctingRisk(AppLocalizations l10n, String risk) {
  switch (risk) {
    case DuctingRisk.none:
      return l10n.settingsNone;
    case DuctingRisk.possible:
      return l10n.mapDuctingPossible;
    case DuctingRisk.likely:
      return l10n.mapDuctingLikely;
    default:
      return l10n.settingsUnknown;
  }
}

/// Color used to render a ducting risk value.
Color ductingRiskColor(String risk) {
  switch (risk) {
    case 'none':
      return Colors.green;
    case 'possible':
      return Colors.orange;
    case 'likely':
      return Colors.red;
    default:
      return Colors.grey;
  }
}
