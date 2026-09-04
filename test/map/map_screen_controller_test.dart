import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_wardrive/models/models.dart';
import 'package:meshcore_wardrive/screens/map/map_screen_controller.dart';
import 'package:meshcore_wardrive/services/map_lod_service.dart';
import 'package:meshcore_wardrive/utils/geohash_utils.dart';
import 'package:meshcore_wardrive/utils/session_map_view.dart';

void main() {
  group('MapScreenController', () {
    test(
      'refresh applies session and source filters before aggregation',
      () async {
        final start = DateTime(2026, 8, 20, 10);
        final store = FakeMapDataStore([
          _sample(
            'visible',
            start.add(const Duration(minutes: 5)),
            source: 'A',
          ),
          _sample(
            'other-source',
            start.add(const Duration(minutes: 6)),
            source: 'B',
          ),
          _sample(
            'outside',
            start.subtract(const Duration(minutes: 5)),
            source: 'A',
          ),
        ]);
        final controller = MapScreenController(store: store)
          ..setSessionView(
            SessionMapView.session(
              WSession(
                id: 7,
                startTime: start,
                endTime: start.add(const Duration(hours: 1)),
              ),
            ),
          )
          ..setSourceFilter('A');
        final repeater = Repeater(
          id: 'AABBCCDDEEFF',
          position: const LatLng(55.76, 37.63),
          name: 'Tower',
        );

        final changed = await controller.refresh(
          discoveredRepeaters: [repeater],
          coveragePrecision: 7,
        );

        expect(changed, isTrue);
        expect(controller.sampleCount, 3);
        expect(controller.samples.map((sample) => sample.id), ['visible']);
        expect(controller.repeaters, [repeater]);
        expect(controller.aggregation?.coverages, hasLength(1));
      },
    );

    test('unchanged refresh reuses the existing sample snapshot', () async {
      final store = FakeMapDataStore([_sample('one', DateTime(2026, 8, 20))]);
      final controller = MapScreenController(store: store);

      expect(
        await controller.refresh(
          discoveredRepeaters: const [],
          coveragePrecision: 7,
        ),
        isTrue,
      );
      expect(
        await controller.refresh(
          discoveredRepeaters: const [],
          coveragePrecision: 7,
        ),
        isFalse,
      );

      expect(store.allSamplesReads, 1);
    });

    test('flipping optimistic display re-aggregates coverage', () async {
      final now = DateTime.now();
      final store = FakeMapDataStore([
        _sample('failure', now, pingSuccess: false),
        _sample(
          'success',
          now.subtract(const Duration(days: 2)),
          pingSuccess: true,
        ),
      ]);
      final controller = MapScreenController(store: store);
      final repeaters = const <Repeater>[];

      await controller.refresh(
        discoveredRepeaters: repeaters,
        coveragePrecision: 7,
        optimisticDisplay: false,
      );
      final pessimisticLost =
          controller.aggregation?.coverages.single.lost ?? -1;
      expect(pessimisticLost, greaterThan(0));

      expect(
        await controller.refresh(
          discoveredRepeaters: repeaters,
          coveragePrecision: 7,
          optimisticDisplay: true,
        ),
        isTrue,
      );
      expect(controller.aggregation?.coverages.single.lost, 0);

      // Same setting again changes nothing and keeps the cached snapshot.
      expect(
        await controller.refresh(
          discoveredRepeaters: repeaters,
          coveragePrecision: 7,
          optimisticDisplay: true,
        ),
        isFalse,
      );
    });

    test('changing coverage precision re-aggregates coverage', () async {
      // Two samples inside one precision-6 neighborhood cell but in different
      // precision-7 street cells. A 0.001° latitude offset is ~111 m from the
      // cell center, safely inside the ~0.0055° tall precision-6 interval,
      // and the ~222 m gap must cross at least one ~0.0007° tall
      // precision-7 interval.
      final cellCenter = GeohashUtils.posFromHash('ucftpv');
      const latOffset = 0.001;
      final north = LatLng(
        cellCenter.latitude + latOffset,
        cellCenter.longitude,
      );
      final south = LatLng(
        cellCenter.latitude - latOffset,
        cellCenter.longitude,
      );
      expect(
        GeohashUtils.coverageKey(north.latitude, north.longitude, precision: 6),
        GeohashUtils.coverageKey(south.latitude, south.longitude, precision: 6),
      );
      expect(
        GeohashUtils.coverageKey(north.latitude, north.longitude, precision: 7),
        isNot(
          GeohashUtils.coverageKey(
            south.latitude,
            south.longitude,
            precision: 7,
          ),
        ),
      );

      final store = FakeMapDataStore([
        _sample('north', DateTime(2026, 8, 20), position: north),
        _sample(
          'south',
          DateTime(2026, 8, 20, 0, 1),
          pingSuccess: false,
          position: south,
        ),
      ]);
      final controller = MapScreenController(store: store);

      expect(
        await controller.refresh(
          discoveredRepeaters: const [],
          coveragePrecision: 7,
        ),
        isTrue,
      );
      expect(controller.aggregation?.coverages, hasLength(2));

      // Lowering the resolution merges the street cells into one square that
      // keeps both the success and the failure.
      expect(
        await controller.refresh(
          discoveredRepeaters: const [],
          coveragePrecision: 6,
        ),
        isTrue,
      );
      expect(controller.aggregation?.coverages, hasLength(1));
      expect(controller.aggregation?.coverages.single.lost, greaterThan(0));

      // Same precision again changes nothing and keeps the cached snapshot.
      expect(
        await controller.refresh(
          discoveredRepeaters: const [],
          coveragePrecision: 6,
        ),
        isFalse,
      );
    });

    test('LOD and sample filter results are cached by their inputs', () async {
      final store = FakeMapDataStore([
        _sample('success', DateTime(2026, 8, 20), path: 'AABBCCDDEEFF'),
        _sample('gps', DateTime(2026, 8, 20, 0, 1), pingSuccess: null),
      ]);
      final controller = MapScreenController(store: store);
      await controller.refresh(
        discoveredRepeaters: const [],
        coveragePrecision: 7,
      );

      final firstLod = controller.coverageLod(
        zoom: 10,
        enabled: true,
        maxPrecision: 7,
        successfulOnly: false,
      );
      final secondLod = controller.coverageLod(
        zoom: 10,
        enabled: true,
        maxPrecision: 7,
        successfulOnly: false,
      );
      final clusters = controller.sampleClusters(
        zoom: 16,
        lodEnabled: false,
        groupByGeohash: false,
        showGpsSamples: false,
        showSuccessfulOnly: true,
        includeOnlyRepeaters: 'AABB',
      );

      expect(identical(firstLod, secondLod), isTrue);
      expect(clusters, hasLength(1));
      expect(clusters.single.newestSample.id, 'success');
    });

    test('LOD precision honors the configured bounds', () async {
      final store = FakeMapDataStore([_sample('one', DateTime(2026, 8, 20))]);
      final controller = MapScreenController(store: store);
      await controller.refresh(
        discoveredRepeaters: const [],
        coveragePrecision: 7,
      );

      // A raised floor keeps far zooms from merging into huge cells.
      expect(
        controller.coverageLodPrecision(
          zoom: 6,
          enabled: true,
          maxPrecision: 7,
          minLodPrecision: 5,
          maxLodPrecision: 7,
        ),
        5,
      );
      // A lowered ceiling keeps close zooms from fragmenting samples.
      expect(
        controller.sampleLodPrecision(
          zoom: 18,
          enabled: true,
          minLodPrecision: 3,
          maxLodPrecision: 6,
        ),
        6,
      );
      // The LOD ceiling never exceeds the per-layer maximum.
      expect(
        controller.coverageLodPrecision(
          zoom: 18,
          enabled: true,
          maxPrecision: 5,
          minLodPrecision: 3,
          maxLodPrecision: 8,
        ),
        5,
      );
      // Disabled LOD ignores the bounds entirely.
      expect(
        controller.coverageLodPrecision(
          zoom: 6,
          enabled: false,
          maxPrecision: 7,
          minLodPrecision: 5,
          maxLodPrecision: 7,
        ),
        7,
      );
      expect(
        controller.sampleLodPrecision(
          zoom: 6,
          enabled: false,
          minLodPrecision: 5,
          maxLodPrecision: 7,
        ),
        8,
      );
    });

    test('successful-pings-only hides dead-zone coverage squares', () async {
      final start = DateTime(2026, 8, 20);
      final store = FakeMapDataStore([
        _sample(
          'success',
          start,
          path: 'AABBCCDDEEFF',
          position: const LatLng(55.75, 37.62),
        ),
        _sample(
          'failure',
          start.add(const Duration(minutes: 1)),
          pingSuccess: false,
          position: const LatLng(55.76, 37.64),
        ),
      ]);
      final controller = MapScreenController(store: store);
      await controller.refresh(
        discoveredRepeaters: const [],
        coveragePrecision: 7,
      );

      // LOD is disabled so every aggregated cell stays its own square
      // instead of being merged by low-zoom buckets.
      final allLod = controller.coverageLod(
        zoom: 10,
        enabled: false,
        maxPrecision: 7,
        successfulOnly: false,
      );
      expect(allLod.coverages, hasLength(2));

      final successOnlyLod = controller.coverageLod(
        zoom: 10,
        enabled: false,
        maxPrecision: 7,
        successfulOnly: true,
      );
      expect(successOnlyLod.coverages, hasLength(1));
      expect(successOnlyLod.coverages.single.received, greaterThan(0));

      // Flipping the toggle back restores the dead-zone square.
      expect(
        controller
            .coverageLod(
              zoom: 10,
              enabled: false,
              maxPrecision: 7,
              successfulOnly: false,
            )
            .coverages
            .length,
        2,
      );
    });

    test(
      'displaySamples keeps only successful pings under the filter',
      () async {
        final store = FakeMapDataStore([
          _sample('success', DateTime(2026, 8, 20)),
          _sample('failure', DateTime(2026, 8, 20), pingSuccess: false),
          _sample('gps', DateTime(2026, 8, 20), pingSuccess: null),
        ]);
        final controller = MapScreenController(store: store);
        await controller.refresh(
          discoveredRepeaters: const [],
          coveragePrecision: 7,
        );

        expect(controller.displaySamples(showSuccessfulOnly: false).length, 3);

        final filtered = controller.displaySamples(showSuccessfulOnly: true);
        expect(filtered.map((sample) => sample.id), ['success']);
        expect(controller.samples.length, 3);

        // Repeated reads reuse the cached filtered snapshot.
        expect(
          identical(
            filtered,
            controller.displaySamples(showSuccessfulOnly: true),
          ),
          isTrue,
        );
      },
    );

    test(
      'geohash grouping merges same-cell samples even with LOD off',
      () async {
        final store = FakeMapDataStore([
          Sample(
            id: 'a',
            position: const LatLng(55.7500, 37.6100),
            timestamp: DateTime(2026, 8, 20),
            geohash: 'ucftpv11',
            path: 'AABBCCDDEEFF',
            pingSuccess: true,
          ),
          Sample(
            id: 'b',
            position: const LatLng(55.7504, 37.6106),
            timestamp: DateTime(2026, 8, 20, 0, 1),
            geohash: 'ucftpv11',
            path: 'AABBCCDDEEFF',
            pingSuccess: false,
          ),
        ]);
        final controller = MapScreenController(store: store);
        await controller.refresh(
          discoveredRepeaters: const [],
          coveragePrecision: 7,
        );

        List<SampleCluster> clusters({
          required bool lodEnabled,
          required bool groupByGeohash,
        }) => controller.sampleClusters(
          zoom: 17,
          lodEnabled: lodEnabled,
          groupByGeohash: groupByGeohash,
          showGpsSamples: true,
          showSuccessfulOnly: false,
          includeOnlyRepeaters: null,
        );

        // Without grouping every measurement keeps its own marker.
        final individual = clusters(lodEnabled: false, groupByGeohash: false);
        expect(individual, hasLength(2));
        expect(individual.map((cluster) => cluster.newestSample.id).toSet(), {
          'a',
          'b',
        });

        // Grouping collapses the cell into one marker at the average position
        // while keeping every measurement reachable for the details list.
        final grouped = clusters(lodEnabled: false, groupByGeohash: true);
        expect(grouped, hasLength(1));
        expect(grouped.single.sampleCount, 2);
        expect(grouped.single.position.latitude, closeTo(55.7502, 1e-9));
        expect(grouped.single.position.longitude, closeTo(37.6103, 1e-9));
        expect(
          grouped.single.samples.map((sample) => sample.id),
          unorderedEquals(['a', 'b']),
        );

        // LOD on (precision saturated to 8 anyway) groups into the same cell.
        final lodOnGrouped = clusters(lodEnabled: true, groupByGeohash: true);
        expect(lodOnGrouped, hasLength(1));
        expect(lodOnGrouped.single.sampleCount, 2);
        expect(
          lodOnGrouped.single.samples.map((sample) => sample.id),
          unorderedEquals(['a', 'b']),
        );
      },
    );

    test(
      'delete commands use the injected store and invalidate data',
      () async {
        final store = FakeMapDataStore([_sample('one', DateTime(2026, 8, 20))]);
        final controller = MapScreenController(store: store);
        await controller.refresh(
          discoveredRepeaters: const [],
          coveragePrecision: 7,
        );

        await controller.deleteSample('one');
        final deleted = await controller.deleteCoverage('ucf');
        await controller.deleteSession(9);

        expect(store.deletedSampleIds, ['one']);
        expect(store.deletedCoveragePrefixes, ['ucf']);
        expect(store.deletedSessionIds, [9]);
        expect(deleted, 4);
        expect(
          await controller.refresh(
            discoveredRepeaters: const [],
            coveragePrecision: 7,
          ),
          isTrue,
        );
      },
    );
  });
}

class FakeMapDataStore implements MapDataStore {
  FakeMapDataStore(this.samples);

  final List<Sample> samples;
  final List<String> deletedSampleIds = [];
  final List<String> deletedCoveragePrefixes = [];
  final List<int> deletedSessionIds = [];
  int allSamplesReads = 0;

  @override
  Future<List<Sample>> getAllSamples() async {
    allSamplesReads++;
    return List.of(samples);
  }

  @override
  Future<int> getSampleCount() async => samples.length;

  @override
  Future<void> deleteSample(String sampleId) async {
    deletedSampleIds.add(sampleId);
  }

  @override
  Future<int> deleteSamplesByGeohash(String geohashPrefix) async {
    deletedCoveragePrefixes.add(geohashPrefix);
    return 4;
  }

  @override
  Future<List<WSession>> getAllSessions() async => const [];

  @override
  Future<void> deleteSession(int id) async {
    deletedSessionIds.add(id);
  }
}

Sample _sample(
  String id,
  DateTime timestamp, {
  String? source,
  String? path = 'AABBCCDDEEFF',
  bool? pingSuccess = true,
  LatLng position = const LatLng(55.75, 37.62),
}) {
  return Sample(
    id: id,
    position: position,
    timestamp: timestamp,
    path: path,
    geohash: 'ucftpv1',
    pingSuccess: pingSuccess,
    source: source,
  );
}
