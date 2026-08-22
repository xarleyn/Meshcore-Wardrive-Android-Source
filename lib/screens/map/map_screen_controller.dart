import '../../models/models.dart';
import '../../services/aggregation_service.dart';
import '../../services/database_service.dart';
import '../../services/map_lod_service.dart';
import '../../utils/session_map_view.dart';

abstract interface class MapDataStore {
  Future<int> getSampleCount();

  Future<List<Sample>> getAllSamples();

  Future<void> deleteSample(String sampleId);

  Future<int> deleteSamplesByGeohash(String geohashPrefix);

  Future<List<WSession>> getAllSessions();

  Future<void> deleteSession(int id);
}

class DatabaseMapDataStore implements MapDataStore {
  DatabaseMapDataStore(this.database);

  final DatabaseService database;

  @override
  Future<int> getSampleCount() => database.getSampleCount();

  @override
  Future<List<Sample>> getAllSamples() => database.getAllSamples();

  @override
  Future<void> deleteSample(String sampleId) => database.deleteSample(sampleId);

  @override
  Future<int> deleteSamplesByGeohash(String geohashPrefix) =>
      database.deleteSamplesByGeohash(geohashPrefix);

  @override
  Future<List<WSession>> getAllSessions() => database.getAllSessions();

  @override
  Future<void> deleteSession(int id) => database.deleteSession(id);
}

class MapCoverageLod {
  const MapCoverageLod({
    required this.precision,
    required this.coverages,
    required this.edges,
  });

  final int precision;
  final List<Coverage> coverages;
  final List<Edge> edges;
}

class MapScreenController {
  MapScreenController({required MapDataStore store}) : _store = store;

  final MapDataStore _store;

  int _sampleCount = 0;
  List<Sample> _samples = const [];
  AggregationResult? _aggregation;
  List<Repeater> _repeaters = const [];
  SessionMapView _sessionView = const SessionMapView.all();
  String? _sourceFilter;

  int? _aggregatedSampleCount;
  String? _aggregatedRepeaterFingerprint;
  int? _aggregatedCoveragePrecision;
  bool _invalidated = true;
  int _refreshGeneration = 0;

  AggregationResult? _lodAggregation;
  int? _lodPrecision;
  bool? _lodEnabled;
  MapCoverageLod? _coverageLod;

  List<Sample>? _clusterSamples;
  int? _clusterPrecision;
  String? _clusterFilter;
  List<SampleCluster> _clusters = const [];

  int get sampleCount => _sampleCount;
  List<Sample> get samples => _samples;
  AggregationResult? get aggregation => _aggregation;
  List<Repeater> get repeaters => _repeaters;
  SessionMapView get sessionView => _sessionView;
  String? get sourceFilter => _sourceFilter;

  Future<bool> refresh({
    required Iterable<Repeater> discoveredRepeaters,
    required int coveragePrecision,
    bool force = false,
  }) async {
    final generation = ++_refreshGeneration;
    final repeaters = List<Repeater>.unmodifiable(discoveredRepeaters);
    final repeaterFingerprint = _repeaterFingerprint(repeaters);
    final count = await _store.getSampleCount();
    if (generation != _refreshGeneration) return false;

    final needsAggregation =
        force ||
        _invalidated ||
        count != _aggregatedSampleCount ||
        repeaterFingerprint != _aggregatedRepeaterFingerprint ||
        coveragePrecision != _aggregatedCoveragePrecision;
    _sampleCount = count;
    if (!needsAggregation) return false;

    var samples = _sessionView.visibleSamples(await _store.getAllSamples());
    if (generation != _refreshGeneration) return false;
    final sourceFilter = _sourceFilter;
    if (sourceFilter != null) {
      samples = samples
          .where((sample) => sample.source == sourceFilter)
          .toList(growable: false);
    }

    final aggregation = AggregationService.buildIndexes(
      samples,
      repeaters,
      coveragePrecision: coveragePrecision,
    );
    final repeaterMap = <String, Repeater>{
      for (final repeater in aggregation.repeaters) repeater.id: repeater,
      for (final repeater in repeaters) repeater.id: repeater,
    };

    _samples = List<Sample>.unmodifiable(samples);
    _aggregation = aggregation;
    _repeaters = List<Repeater>.unmodifiable(repeaterMap.values);
    _aggregatedSampleCount = count;
    _aggregatedRepeaterFingerprint = repeaterFingerprint;
    _aggregatedCoveragePrecision = coveragePrecision;
    _invalidated = false;
    _clearLodCaches();
    return true;
  }

  void setSessionView(SessionMapView view) {
    _sessionView = view;
    invalidate();
  }

  void setSourceFilter(String? source) {
    _sourceFilter = source;
    invalidate();
  }

  void replaceRepeaters(Iterable<Repeater> repeaters) {
    _repeaters = List<Repeater>.unmodifiable(repeaters);
    invalidate();
  }

  void invalidate() {
    _invalidated = true;
    _clearLodCaches();
  }

  Future<void> deleteSample(String sampleId) async {
    await _store.deleteSample(sampleId);
    invalidate();
  }

  Future<int> deleteCoverage(String geohashPrefix) async {
    final deleted = await _store.deleteSamplesByGeohash(geohashPrefix);
    invalidate();
    return deleted;
  }

  Future<List<WSession>> getSessions() => _store.getAllSessions();

  Future<void> deleteSession(int id) async {
    await _store.deleteSession(id);
    invalidate();
  }

  int coverageLodPrecision({
    required double zoom,
    required bool enabled,
    required int maxPrecision,
  }) {
    if (!enabled) return maxPrecision;
    return MapLodService.precisionForZoom(zoom, maxPrecision: maxPrecision);
  }

  int sampleLodPrecision({required double zoom, required bool enabled}) {
    if (!enabled) return 8;
    return MapLodService.precisionForZoom(zoom, maxPrecision: 8);
  }

  MapCoverageLod coverageLod({
    required double zoom,
    required bool enabled,
    required int maxPrecision,
  }) {
    final aggregation = _aggregation;
    final precision = coverageLodPrecision(
      zoom: zoom,
      enabled: enabled,
      maxPrecision: maxPrecision,
    );
    if (aggregation == null) {
      return MapCoverageLod(
        precision: precision,
        coverages: const [],
        edges: const [],
      );
    }
    if (identical(_lodAggregation, aggregation) &&
        _lodPrecision == precision &&
        _lodEnabled == enabled &&
        _coverageLod != null) {
      return _coverageLod!;
    }

    final coverages = enabled
        ? MapLodService.aggregateCoverages(
            aggregation.coverages,
            precision: precision,
          )
        : aggregation.coverages;
    final edges = enabled
        ? MapLodService.aggregateEdges(
            aggregation.edges,
            coverages,
            precision: precision,
          )
        : aggregation.edges;
    _lodAggregation = aggregation;
    _lodPrecision = precision;
    _lodEnabled = enabled;
    return _coverageLod = MapCoverageLod(
      precision: precision,
      coverages: coverages,
      edges: edges,
    );
  }

  List<SampleCluster> sampleClusters({
    required double zoom,
    required bool lodEnabled,
    required bool showGpsSamples,
    required bool showSuccessfulOnly,
    required String? includeOnlyRepeaters,
  }) {
    final precision = sampleLodPrecision(zoom: zoom, enabled: lodEnabled);
    final filterKey = [
      showGpsSamples,
      showSuccessfulOnly,
      includeOnlyRepeaters ?? '',
      lodEnabled,
    ].join('|');
    if (identical(_clusterSamples, _samples) &&
        _clusterPrecision == precision &&
        _clusterFilter == filterKey) {
      return _clusters;
    }

    final allowedPrefixes = includeOnlyRepeaters
        ?.split(',')
        .map((value) => value.trim().toUpperCase())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    final filteredSamples = _samples.where((sample) {
      if (!showGpsSamples && sample.pingSuccess == null) return false;
      if (showSuccessfulOnly && sample.pingSuccess != true) return false;
      if (allowedPrefixes != null && allowedPrefixes.isNotEmpty) {
        final sampleNodeId = sample.path?.toUpperCase() ?? '';
        if (!allowedPrefixes.any(sampleNodeId.startsWith)) return false;
      }
      return true;
    });

    _clusterSamples = _samples;
    _clusterPrecision = precision;
    _clusterFilter = filterKey;
    return _clusters = lodEnabled
        ? MapLodService.aggregateSamples(filteredSamples, precision: precision)
        : MapLodService.individualSamples(filteredSamples);
  }

  void _clearLodCaches() {
    _lodAggregation = null;
    _lodPrecision = null;
    _lodEnabled = null;
    _coverageLod = null;
    _clusterSamples = null;
    _clusterPrecision = null;
    _clusterFilter = null;
    _clusters = const [];
  }

  static String _repeaterFingerprint(List<Repeater> repeaters) {
    final entries =
        repeaters
            .map(
              (repeater) => [
                repeater.id,
                repeater.position.latitude,
                repeater.position.longitude,
                repeater.name ?? '',
              ].join(':'),
            )
            .toList()
          ..sort();
    return entries.join('|');
  }
}
