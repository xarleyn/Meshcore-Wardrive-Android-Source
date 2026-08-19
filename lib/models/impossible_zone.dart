import 'dart:math';

/// Circular area the user cannot physically occupy.
///
/// A GPS or Wi-Fi fix inside any such zone is treated as invalid.
class ImpossibleZone {
  const ImpossibleZone({
    this.id,
    required this.lat,
    required this.lon,
    required this.radiusMeters,
    this.label,
  });

  final int? id;
  final double lat;
  final double lon;
  final double radiusMeters;
  final String? label;

  bool contains(double pointLat, double pointLon) {
    final dlat = (pointLat - lat) * 111320;
    final dlon = (pointLon - lon) * 111320 * cos(pointLat * pi / 180);
    final dist = sqrt(dlat * dlat + dlon * dlon);
    return dist <= radiusMeters;
  }

  /// Diagnostic reason used when a location fix is discarded.
  String get rejectionReason {
    final name = label;
    if (name == null || name.isEmpty) {
      return 'inside impossible zone';
    }
    return 'inside impossible zone: $name';
  }

  /// First zone that contains [pointLat]/[pointLon], or null.
  static ImpossibleZone? containing(
    Iterable<ImpossibleZone> zones,
    double pointLat,
    double pointLon,
  ) {
    for (final zone in zones) {
      if (zone.contains(pointLat, pointLon)) return zone;
    }
    return null;
  }

  factory ImpossibleZone.fromMap(Map<String, dynamic> map) {
    return ImpossibleZone(
      id: map['id'] as int?,
      lat: (map['lat'] as num).toDouble(),
      lon: (map['lon'] as num).toDouble(),
      radiusMeters: (map['radius_meters'] as num).toDouble(),
      label: map['label'] as String?,
    );
  }
}
