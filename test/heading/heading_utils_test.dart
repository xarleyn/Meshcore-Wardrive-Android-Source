import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/utils/heading_utils.dart';

void main() {
  group('HeadingUtils', () {
    test('normalizes headings to zero through 360 degrees', () {
      expect(HeadingUtils.normalize(361), 1);
      expect(HeadingUtils.normalize(-1), 359);
    });

    test('uses the shortest turn across north', () {
      expect(HeadingUtils.shortestDelta(350, 10), 20);
      expect(HeadingUtils.shortestDelta(10, 350), -20);
    });

    test('interpolates across north without a full rotation', () {
      expect(HeadingUtils.interpolate(350, 10, factor: 0.5), 0);
      expect(HeadingUtils.interpolate(10, 350, factor: 0.5), 0);
    });

    test('rotates the map opposite to the current heading', () {
      expect(HeadingUtils.mapRotationForHeading(0), 0);
      expect(HeadingUtils.mapRotationForHeading(90), 270);
      expect(HeadingUtils.mapRotationForHeading(350), 10);
    });
  });
}
