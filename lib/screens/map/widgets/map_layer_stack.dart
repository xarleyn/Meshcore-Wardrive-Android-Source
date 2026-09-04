import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../models/impossible_zone.dart';
import '../../../models/models.dart';
import '../../../services/aggregation_service.dart';
import '../../../services/location_service.dart';
import '../../../services/map_lod_service.dart';
import '../../../services/radio_position_estimator.dart';
import '../../../services/settings_service.dart';
import '../map_screen_controller.dart';
import '../layers/community_coverage_layer.dart';
import '../layers/coverage_layer.dart';
import '../layers/coverage_prediction_layer.dart';
import '../layers/current_position_layer.dart';
import '../layers/edge_layer.dart';
import '../layers/planned_marker_layer.dart';
import '../layers/radio_position_layer.dart';
import '../layers/repeater_layer.dart';
import '../layers/route_trail_layer.dart';
import '../layers/sample_cluster_layer.dart';
import '../layers/sample_heatmap_layer.dart';
import '../layers/zone_overlay_layer.dart';

/// Preview of a zone being added, rendered as a temporary overlay.
typedef ZonePreview = ({LatLng center, double radiusMeters, Color color});

/// Assembles the map layer stack (everything above the tile layer).
///
/// The widget owns no state: the screen passes its current data, flags, hit
/// notifiers, and callbacks. [buildLayers] returns a flat list so the caller
/// keeps the exact layer ordering inside `FlutterMap.children`.
class MapLayerStack extends StatelessWidget {
  const MapLayerStack({
    required this.displaySamples,
    required this.samples,
    required this.repeaters,
    required this.plannedMarkers,
    required this.privacyZones,
    required this.impossibleZones,
    required this.aggregationResult,
    required this.mapDataController,
    required this.radioPositionEstimate,
    required this.communityCoverage,
    required this.zonePreview,
    required this.visibleBounds,
    required this.currentPosition,
    required this.showRouteTrail,
    required this.showHeatmap,
    required this.showPredictionRings,
    required this.showPrivacyZones,
    required this.showGpsExclusionZones,
    required this.showCommunityCoverage,
    required this.showCoverage,
    required this.showSamples,
    required this.showEdges,
    required this.showRepeaters,
    required this.showRadioPosition,
    required this.hideUiForScreenshot,
    required this.mapLodZoom,
    required this.mapLodEnabled,
    required this.mapLodMinPrecision,
    required this.mapLodMaxPrecision,
    required this.coveragePrecision,
    required this.coverageLodPrecision,
    required this.showSuccessfulOnly,
    required this.showGpsSamples,
    required this.sampleGeohashGrouping,
    required this.fixedSampleMarkerSizeEnabled,
    required this.sampleMarkerRadius,
    required this.filterEdgesByWhitelist,
    required this.includeOnlyRepeaters,
    required this.colorMode,
    required this.colorBlindMode,
    required this.currentLocationMarkerStyle,
    required this.positionSource,
    required this.currentHeading,
    required this.showPingPulse,
    required this.heatmapReset,
    required this.coverageHitNotifier,
    required this.sampleHitNotifier,
    required this.onCoverageTap,
    required this.onClusterTap,
    required this.onRepeaterTap,
    required this.onRadioPositionTap,
    required this.onMarkerTap,
    super.key,
  });

  final List<Sample> displaySamples;
  final List<Sample> samples;
  final List<Repeater> repeaters;
  final List<Map<String, dynamic>> plannedMarkers;
  final List<Map<String, dynamic>> privacyZones;
  final List<ImpossibleZone> impossibleZones;
  final AggregationResult? aggregationResult;
  final MapScreenController mapDataController;
  final RadioPositionEstimate? radioPositionEstimate;
  final Map<String, dynamic>? communityCoverage;
  final ZonePreview? zonePreview;
  final LatLngBounds visibleBounds;
  final LatLng? currentPosition;

  final bool showRouteTrail;
  final bool showHeatmap;
  final bool showPredictionRings;
  final bool showPrivacyZones;
  final bool showGpsExclusionZones;
  final bool showCommunityCoverage;
  final bool showCoverage;
  final bool showSamples;
  final bool showEdges;
  final bool showRepeaters;
  final bool showRadioPosition;
  final bool hideUiForScreenshot;

  final double mapLodZoom;
  final bool mapLodEnabled;
  final int mapLodMinPrecision;
  final int mapLodMaxPrecision;
  final int coveragePrecision;
  final int coverageLodPrecision;
  final bool showSuccessfulOnly;
  final bool showGpsSamples;
  final bool sampleGeohashGrouping;
  final bool fixedSampleMarkerSizeEnabled;
  final double sampleMarkerRadius;
  final bool filterEdgesByWhitelist;
  final String? includeOnlyRepeaters;
  final String colorMode;
  final String colorBlindMode;
  final CurrentLocationMarkerStyle currentLocationMarkerStyle;
  final LocationPositionSource positionSource;
  final double currentHeading;
  final bool showPingPulse;

  final Stream<void> heatmapReset;
  final LayerHitNotifier<Coverage> coverageHitNotifier;
  final LayerHitNotifier<SampleCluster> sampleHitNotifier;

  final ValueChanged<Coverage> onCoverageTap;
  final ValueChanged<SampleCluster> onClusterTap;
  final ValueChanged<Repeater> onRepeaterTap;
  final void Function(String message) onRadioPositionTap;
  final ValueChanged<Map<String, dynamic>> onMarkerTap;

  @override
  Widget build(BuildContext context) {
    return Stack(children: buildLayers());
  }

  /// All map layers above the tile layer, in render order.
  List<Widget> buildLayers() {
    return [
      if (showRouteTrail)
        RouteTrailLayer(
          samples: displaySamples,
          colorBlindMode: colorBlindMode,
        ),
      if (showHeatmap)
        SampleHeatmapLayer(samples: displaySamples, reset: heatmapReset),
      if (showPredictionRings)
        CoveragePredictionLayer(
          samples: displaySamples,
          repeaters: repeaters,
          includeOnlyRepeaters: includeOnlyRepeaters,
        ),
      if (showPrivacyZones)
        ZoneOverlayLayer(
          zones: [
            for (final zone in privacyZones)
              ZoneOverlay(
                center: LatLng(
                  (zone['lat'] as num).toDouble(),
                  (zone['lon'] as num).toDouble(),
                ),
                radiusMeters: (zone['radius_meters'] as num).toDouble(),
              ),
          ],
          color: Colors.blueGrey,
        ),
      if (showGpsExclusionZones)
        ZoneOverlayLayer(
          zones: [
            for (final zone in impossibleZones)
              ZoneOverlay(
                center: LatLng(zone.lat, zone.lon),
                radiusMeters: zone.radiusMeters,
              ),
          ],
          color: Colors.deepOrange,
        ),
      if (zonePreview != null)
        ZoneOverlayLayer(
          zones: [
            ZoneOverlay(
              center: zonePreview!.center,
              radiusMeters: zonePreview!.radiusMeters,
            ),
          ],
          color: zonePreview!.color,
        ),
      if (showCommunityCoverage && communityCoverage != null)
        CommunityCoverageLayer(
          rawCoverage: communityCoverage!,
          precision: coverageLodPrecision,
          visibleBounds: visibleBounds,
        ),
      if (showCoverage) ..._buildCoverageLayers(),
      if (showSamples) _buildSampleLayer(),
      if (showEdges) _buildEdgeLayer(),
      if (showRepeaters)
        RepeaterLayer(
          repeaters: repeaters,
          colorBlindMode: colorBlindMode,
          onRepeaterTap: onRepeaterTap,
        ),
      if (showRadioPosition && radioPositionEstimate != null)
        RadioPositionLayer(
          estimate: radioPositionEstimate!,
          onTap: onRadioPositionTap,
        ),
      PlannedMarkerLayer(markers: plannedMarkers, onMarkerTap: onMarkerTap),
      if (currentPosition != null && !hideUiForScreenshot)
        CurrentPositionLayer(
          position: currentPosition!,
          style: currentLocationMarkerStyle,
          source: positionSource,
          heading: currentHeading,
          showPingPulse: showPingPulse,
        ),
    ];
  }

  List<Widget> _buildCoverageLayers() {
    if (aggregationResult == null) return [];
    final lod = mapDataController.coverageLod(
      zoom: mapLodZoom,
      enabled: mapLodEnabled,
      maxPrecision: coveragePrecision,
      successfulOnly: showSuccessfulOnly,
      minLodPrecision: mapLodMinPrecision,
      maxLodPrecision: mapLodMaxPrecision,
    );
    return [
      CoverageLayer(
        coverages: lod.coverages,
        colorMode: colorMode,
        colorBlindMode: colorBlindMode,
        hitNotifier: coverageHitNotifier,
        onCoverageTap: onCoverageTap,
      ),
    ];
  }

  Widget _buildSampleLayer() {
    if (samples.isEmpty) return const SizedBox.shrink();
    final clusters = mapDataController.sampleClusters(
      zoom: mapLodZoom,
      lodEnabled: mapLodEnabled,
      groupByGeohash: sampleGeohashGrouping,
      showGpsSamples: showGpsSamples,
      showSuccessfulOnly: showSuccessfulOnly,
      includeOnlyRepeaters: includeOnlyRepeaters,
      minLodPrecision: mapLodMinPrecision,
      maxLodPrecision: mapLodMaxPrecision,
    );
    return SampleClusterLayer(
      clusters: clusters,
      colorBlindMode: colorBlindMode,
      fixedRadius: fixedSampleMarkerSizeEnabled ? sampleMarkerRadius : null,
      hitNotifier: sampleHitNotifier,
      onClusterTap: onClusterTap,
    );
  }

  Widget _buildEdgeLayer() {
    if (aggregationResult == null) return const SizedBox.shrink();
    final lod = mapDataController.coverageLod(
      zoom: mapLodZoom,
      enabled: mapLodEnabled,
      maxPrecision: coveragePrecision,
      successfulOnly: showSuccessfulOnly,
      minLodPrecision: mapLodMinPrecision,
      maxLodPrecision: mapLodMaxPrecision,
    );
    return EdgeLayer(
      edges: lod.edges,
      filterByWhitelist: filterEdgesByWhitelist,
      includeOnlyRepeaters: includeOnlyRepeaters,
    );
  }
}
