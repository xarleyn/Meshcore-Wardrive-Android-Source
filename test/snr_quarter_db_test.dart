import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/services/meshcore_protocol.dart';

void main() {
  group('snrQuarterDbToWholeDb', () {
    test('passes a missing SNR through as null', () {
      expect(snrQuarterDbToWholeDb(null), isNull);
    });

    test('rounds quarter-dB values half away from zero', () {
      expect(snrQuarterDbToWholeDb(-2.75), -3);
      expect(snrQuarterDbToWholeDb(-2.5), -3);
      expect(snrQuarterDbToWholeDb(2.75), 3);
      expect(snrQuarterDbToWholeDb(0.75), 1);
    });

    test('never truncates negative SNR toward zero', () {
      // A Carpeater neighbour scan previously stored these with toInt(),
      // which turned -1.75 dB into -1 dB and made weak links look better.
      expect(snrQuarterDbToWholeDb(-7 / 4.0), -2);
      expect(snrQuarterDbToWholeDb(-1.75), isNot(-1));
    });

    test('accepts already-whole integer inputs', () {
      expect(snrQuarterDbToWholeDb(-2), -2);
      expect(snrQuarterDbToWholeDb(10), 10);
    });
  });
}
