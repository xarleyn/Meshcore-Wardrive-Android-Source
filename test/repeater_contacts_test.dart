import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_wardrive/models/models.dart';
import 'package:meshcore_wardrive/utils/repeater_contacts.dart';

void main() {
  Repeater repeater(String id, {String? name, double lat = 55.0}) =>
      Repeater(id: id, position: LatLng(lat, 32.0), name: name);

  test('merges name-only stubs with positioned repeaters', () {
    final merged = mergeRepeaterContacts(
      nameOnly: const {'BBBB0002': 'zeta', 'CCCC0003': 'unnamed later'},
      positioned: [
        repeater('AAAA0001', name: 'alpha'),
        // Positioned entry wins over the same-ID name-only stub.
        repeater('BBBB0002', name: 'Bravo', lat: 56.0),
      ],
    );

    expect(merged, hasLength(3));
    expect(merged.map((r) => r.id).toList(), [
      'AAAA0001', // alpha
      'BBBB0002', // Bravo
      'CCCC0003', // unnamed last
    ]);
    expect(merged[1].name, 'Bravo');
    expect(merged[1].position.latitude, 56.0);
    expect(merged[2].position.latitude, 0.0);
  });

  test('later positioned entries override earlier ones by ID', () {
    final merged = mergeRepeaterContacts(
      nameOnly: const {},
      positioned: [
        repeater('AAAA0001', name: 'stale', lat: 55.0),
        repeater('AAAA0001', name: 'fresh', lat: 57.5),
      ],
    );

    expect(merged, hasLength(1));
    expect(merged.single.name, 'fresh');
    expect(merged.single.position.latitude, 57.5);
  });

  test('sorts case-insensitively with unnamed contacts last', () {
    final merged = mergeRepeaterContacts(
      nameOnly: const {'DDDD0004': 'delta'},
      positioned: [
        repeater('FFFF0006'),
        repeater('EEEE0005', name: 'Charlie'),
      ],
    );

    expect(merged.map((r) => r.name).toList(), ['Charlie', 'delta', null]);
  });
}
