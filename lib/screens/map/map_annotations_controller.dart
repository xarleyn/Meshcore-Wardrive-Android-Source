import '../../models/impossible_zone.dart';
import '../../services/database_service.dart';

/// Annotation CRUD for the map screen: planned markers, privacy and
/// impossible zones, and delete-mode removals.
///
/// The controller is not a widget and holds no BuildContext: it coordinates
/// database access and delegates list updates, sample reloads, and the
/// sample/coverage removal mechanics to callbacks owned by the screen.
class MapAnnotationsController {
  const MapAnnotationsController({
    required this.databaseService,
    required this.onMarkersLoaded,
    required this.onPrivacyZonesLoaded,
    required this.onImpossibleZonesLoaded,
    required this.loadSamples,
    required this.deleteSampleById,
    required this.deleteCoverageById,
  });

  final DatabaseService databaseService;

  /// Applies freshly loaded markers and zones to the screen state; the owner
  /// guards these callbacks with its own mounted check.
  final Future<void> Function(List<Map<String, dynamic>> markers)
  onMarkersLoaded;
  final Future<void> Function(List<Map<String, dynamic>> zones)
  onPrivacyZonesLoaded;
  final Future<void> Function(List<ImpossibleZone> zones)
  onImpossibleZonesLoaded;

  /// Reloads samples after a delete-mode removal.
  final Future<void> Function() loadSamples;

  /// Removes a sample or a coverage cell through the screen data controller.
  final Future<void> Function(String sampleId) deleteSampleById;
  final Future<int> Function(String geohashPrefix) deleteCoverageById;

  Future<void> loadMarkers() async {
    final markers = await databaseService.getAllMarkers();
    await onMarkersLoaded(markers);
  }

  Future<void> loadPrivacyZones() async {
    final zones = await databaseService.getAllPrivacyZones();
    await onPrivacyZonesLoaded(zones);
  }

  Future<void> loadImpossibleZones() async {
    final zones = await databaseService.getAllImpossibleZones();
    await onImpossibleZonesLoaded(zones);
  }

  Future<void> addPlannedMarker({
    required double latitude,
    required double longitude,
    required String? label,
  }) async {
    await databaseService.addMarker(latitude, longitude, label);
    await loadMarkers();
  }

  Future<void> deleteMarker(int id) async {
    await databaseService.deleteMarker(id);
    await loadMarkers();
  }

  Future<void> addPrivacyZone({
    required double latitude,
    required double longitude,
    required double radiusMeters,
    required String? label,
  }) async {
    await databaseService.addPrivacyZone(
      latitude,
      longitude,
      radiusMeters,
      label,
    );
    await loadPrivacyZones();
  }

  Future<void> addImpossibleZone({
    required double latitude,
    required double longitude,
    required double radiusMeters,
    required String? label,
  }) async {
    await databaseService.addImpossibleZone(
      latitude,
      longitude,
      radiusMeters,
      label,
    );
    await loadImpossibleZones();
  }

  /// Removes a sample and reloads the screen samples.
  Future<void> deleteSample(String sampleId) async {
    await deleteSampleById(sampleId);
    await loadSamples();
  }

  /// Removes a coverage cell and reloads the screen samples.
  Future<int> deleteCoverageCell(String geohashPrefix) async {
    final deleted = await deleteCoverageById(geohashPrefix);
    await loadSamples();
    return deleted;
  }
}
