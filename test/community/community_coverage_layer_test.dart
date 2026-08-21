import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_wardrive/screens/map/layers/community_coverage_layer.dart';
import 'package:meshcore_wardrive/utils/geohash_utils.dart';

void main() {
  test('returns only non-empty cells that intersect the viewport', () {
    final visibleHash = GeohashUtils.coverageKey(
      47.7776,
      -122.4247,
      precision: 7,
    );
    final emptyHash = GeohashUtils.coverageKey(
      47.7786,
      -122.4247,
      precision: 7,
    );
    final hiddenHash = GeohashUtils.coverageKey(0, 0, precision: 7);

    final cells = visibleCommunityCoverageCells(
      rawCoverage: {
        visibleHash: {'received': 2, 'lost': 1},
        emptyHash: {'received': 0, 'lost': 0},
        hiddenHash: {'received': 4, 'lost': 1},
      },
      precision: 7,
      visibleBounds: LatLngBounds(
        const LatLng(47.7, -122.5),
        const LatLng(47.8, -122.3),
      ),
    );

    expect(cells.map((cell) => cell.hash), [visibleHash]);
  });
}
