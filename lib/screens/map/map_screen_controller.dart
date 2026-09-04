import 'dart:math' as math;

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
  MapScreenController({required this.store});

  final MapDataStore store;

  int _sampleCount = 0;
  List<Sample> _samples = const [];
  AggregationResult? _aggregation;
  List<Repeater> _repeaters = const [];
  SessionMapView _sessionView = const SessionMapView.all();
  String? _sourceFilter;

  int? _aggregatedSampleCount;
  String? _aggregatedRepeaterFingerprint;
  int? _aggregatedCoveragePrecision;
  bool? _aggregatedOptimisticDisplay;
  bool _invalidated = true;
  int _refreshGeneration = 0;

  AggregationResult? _lodAggregation;
  int? _lodPrecision;
  bool? _lodEnabled;
  bool? _lodSuccessfulOnly;
  MapCoverageLod? _coverageLod;

  List<Sample>? _clusterSamples;
  int? _clusterPrecision;
  String? _clusterFilter;
  List<SampleCluster> _clusters = const [];

  List<Sample>? _successfulOnlySamples;
  List<Sample>? _successfulOnlySamplesSource;

  int get sampleCount => _sampleCount;
  List<Sample> get samples => _samples;

  /// Samples the display filters let onto the map.
  ///
  /// With [showSuccessfulOnly] only successful pings remain, so every
  /// sample-derived layer (route trail, heatmap, prediction rings) hides
  /// failed pings and GPS-only samples just like the round sample markers do.
  /// [samples] keeps returning the unfiltered snapshot for stats and export.
  List<Sample> displaySamples({required bool showSuccessfulOnly}) {
    if (!showSuccessfulOnly) return _samples;
    final source = _samples;
    if (_successfulOnlySamples != null &&
        identical(_successfulOnlySamplesSource, source)) {
      return _successfulOnlySamples!;
    }
    final filtered = List<Sample>.unmodifiable(
      source.where((sample) => sample.pingSuccess == true),
    );
    _successfulOnlySamplesSource = source;
    return _successfulOnlySamples = filtered;
  }

  AggregationResult? get aggregation => _aggregation;
  List<Repeater> get repeaters => _repeaters;
  SessionMapView get sessionView => _sessionView;
  String? get sourceFilter => _sourceFilter;

  Future<bool> refresh({
    required Iterable<Repeater> discoveredRepeaters,
    required int coveragePrecision,
    bool optimisticDisplay = false,
    bool force = false,
  }) async {
    final generation = ++_refreshGeneration;
    final repeaters = List<Repeater>.unmodifiable(discoveredRepeaters);
    final repeaterFingerprint = _repeaterFingerprint(repeaters);
    final count = await store.getSampleCount();
    if (generation != _refreshGeneration) return false;

    final needsAggregation =
        force ||
        _invalidated ||
        count != _aggregatedSampleCount ||
        repeaterFingerprint != _aggregatedRepeaterFingerprint ||
        coveragePrecision != _aggregatedCoveragePrecision ||
        optimisticDisplay != _aggregatedOptimisticDisplay;
    _sampleCount = count;
    if (!needsAggregation) return false;

    var samples = _sessionView.visibleSamples(await store.getAllSamples());
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
      optimisticDisplay: optimisticDisplay,
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
    _aggregatedOptimisticDisplay = optimisticDisplay;
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
    await store.deleteSample(sampleId);
    invalidate();
  }

  Future<int> deleteCoverage(String geohashPrefix) async {
    final deleted = await store.deleteSamplesByGeohash(geohashPrefix);
    invalidate();
    return deleted;
  }

  Future<List<WSession>> getSessions() => store.getAllSessions();

  Future<void> deleteSession(int id) async {
    await store.deleteSession(id);
    invalidate();
  }

  int coverageLodPrecision({
    required double zoom,
    required bool enabled,
    required int maxPrecision,
    int minLodPrecision = MapLodService.defaultMinPrecision,
    int maxLodPrecision = MapLodService.defaultMaxPrecision,
  }) {
    if (!enabled) return maxPrecision;
    return MapLodService.precisionForZoom(
      zoom,
      maxPrecision: math.min(maxPrecision, maxLodPrecision),
      minPrecision: minLodPrecision,
    );
  }

  int sampleLodPrecision({
    required double zoom,
    required bool enabled,
    int minLodPrecision = MapLodService.defaultMinPrecision,
    int maxLodPrecision = MapLodService.defaultMaxPrecision,
  }) {
    if (!enabled) return 8;
    return MapLodService.precisionForZoom(
      zoom,
      maxPrecision: math.min(8, maxLodPrecision),
      minPrecision: minLodPrecision,
    );
  }

  MapCoverageLod coverageLod({
    required double zoom,
    required bool enabled,
    required int maxPrecision,
    required bool successfulOnly,
    int minLodPrecision = MapLodService.defaultMinPrecision,
    int maxLodPrecision = MapLodService.defaultMaxPrecision,
  }) {
    final aggregation = _aggregation;
    final precision = coverageLodPrecision(
      zoom: zoom,
      enabled: enabled,
      maxPrecision: maxPrecision,
      minLodPrecision: minLodPrecision,
      maxLodPrecision: maxLodPrecision,
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
        _lodSuccessfulOnly == successfulOnly &&
        _coverageLod != null) {
      return _coverageLod!;
    }

    // "Successful pings only" also hides dead-zone squares whose every ping
    // failed. A cell with at least one success has weighted received > 0 and
    // keeps its color computed from the full ping history.
    final visibleCoverages = successfulOnly
        ? aggregation.coverages
              .where((coverage) => coverage.received > 0)
              .toList(growable: false)
        : aggregation.coverages;
    final coverages = enabled
        ? MapLodService.aggregateCoverages(
            visibleCoverages,
            precision: precision,
          )
        : visibleCoverages;
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
    _lodSuccessfulOnly = successfulOnly;
    return _coverageLod = MapCoverageLod(
      precision: precision,
      coverages: coverages,
      edges: edges,
    );
  }

  List<SampleCluster> sampleClusters({
    required double zoom,
    required bool lodEnabled,
    required bool groupByGeohash,
    required bool showGpsSamples,
    required bool showSuccessfulOnly,
    required String? includeOnlyRepeaters,
    int minLodPrecision = MapLodService.defaultMinPrecision,
    int maxLodPrecision = MapLodService.defaultMaxPrecision,
  }) {
    // Geohash grouping always buckets by the native sample key, so every
    // measurement recorded inside one geohash cell shares one marker even
    // while zoomed in and while low-zoom simplification stays off.
    final precision = groupByGeohash
        ? 8
        : sampleLodPrecision(
            zoom: zoom,
            enabled: lodEnabled,
            minLodPrecision: minLodPrecision,
            maxLodPrecision: maxLodPrecision,
          );
    final filterKey = [
      showGpsSamples,
      showSuccessfulOnly,
      includeOnlyRepeaters ?? '',
      lodEnabled,
      groupByGeohash,
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
    return _clusters = lodEnabled || groupByGeohash
        ? MapLodService.aggregateSamples(
            filteredSamples,
            precision: precision,
            anchorAtCentroid: groupByGeohash,
          )
        : MapLodService.individualSamples(filteredSamples);
  }

  void _clearLodCaches() {
    _lodAggregation = null;
    _lodPrecision = null;
    _lodEnabled = null;
    _lodSuccessfulOnly = null;
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
