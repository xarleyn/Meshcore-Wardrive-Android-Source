class HeadingUtils {
  const HeadingUtils._();

  static double normalize(double heading) {
    return (heading % 360 + 360) % 360;
  }

  static double shortestDelta(double from, double to) {
    return (normalize(to) - normalize(from) + 540) % 360 - 180;
  }

  static double interpolate(double from, double to, {double factor = 0.3}) {
    assert(factor >= 0 && factor <= 1);
    return normalize(from + shortestDelta(from, to) * factor);
  }

  static double mapRotationForHeading(double heading) {
    return normalize(-heading);
  }
}
