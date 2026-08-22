import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../services/radio_position_estimator.dart';

/// Displays a coarse radio-derived position and its uncertainty area.
class RadioPositionLayer extends StatelessWidget {
  const RadioPositionLayer({
    required this.estimate,
    required this.onTap,
    super.key,
  });

  final RadioPositionEstimate estimate;

  /// Called with the localized message describing the estimate.
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    const color = Colors.grey;
    final l10n = AppLocalizations.of(context);
    final uncertaintyText = estimate.uncertaintyMeters >= 1000
        ? '${(estimate.uncertaintyMeters / 1000).toStringAsFixed(1)} km'
        : '${estimate.uncertaintyMeters.round()} m';
    final snackMessage = l10n.mapApproxRadioPositionSnack(
      estimate.repeaterCount,
      uncertaintyText,
    );

    return Stack(
      children: [
        PolygonLayer(
          polygons: [
            Polygon(
              points: _circlePoints(
                estimate.position,
                estimate.uncertaintyMeters,
              ),
              color: color.withValues(alpha: 0.12),
              borderColor: color.withValues(alpha: 0.7),
              borderStrokeWidth: 2,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: estimate.position,
              width: 28,
              height: 28,
              child: Semantics(
                label: l10n.mapApproxRadioPositionUncertainty(uncertaintyText),
                button: true,
                child: GestureDetector(
                  onTap: () => onTap(snackMessage),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.wifi_tethering,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<LatLng> _circlePoints(
    LatLng center,
    double radiusMeters, {
    int segments = 72,
  }) {
    const distance = Distance();
    return List.generate(segments, (index) {
      final bearing = (360.0 / segments) * index;
      return distance.offset(center, radiusMeters, bearing);
    });
  }
}
