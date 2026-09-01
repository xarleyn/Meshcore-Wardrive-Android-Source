import '../models/models.dart';

/// Groups samples that were persisted by a single ping discovery cycle.
///
/// One ping can be heard by several repeaters; every response is stored as
/// its own [Sample] sharing the same geohash and a nearly identical
/// timestamp. These helpers reconstruct that group from a flat sample list.
class PingBurst {
  const PingBurst._();

  /// Maximum spread between timestamps of samples saved by one ping cycle.
  static const Duration collectionWindow = Duration(seconds: 3);

  /// Returns the successful responses belonging to the same ping as
  /// [sample], strongest signal first.
  ///
  /// The tapped sample itself is part of the result when it recorded a
  /// successful response, so callers always render a complete responder
  /// list for the burst it belongs to.
  static List<Sample> responsesFor(Sample sample, Iterable<Sample> samples) {
    final responses =
        samples
            .where(
              (candidate) =>
                  candidate.geohash == sample.geohash &&
                  candidate.pingSuccess == true &&
                  candidate.path != null &&
                  candidate.timestamp.difference(sample.timestamp).abs() <=
                      collectionWindow,
            )
            .toList()
          ..sort(_bySignalStrength);
    return responses;
  }

  /// Best (highest) RSSI across [samples], or `null` when none report one.
  static int? bestRssi(Iterable<Sample> samples) {
    int? best;
    for (final sample in samples) {
      final rssi = sample.rssi;
      if (rssi != null && (best == null || rssi > best)) best = rssi;
    }
    return best;
  }

  static int _bySignalStrength(Sample a, Sample b) {
    final aRssi = a.rssi;
    final bRssi = b.rssi;
    if (aRssi == null && bRssi == null) {
      return a.timestamp.compareTo(b.timestamp);
    }
    if (aRssi == null) return 1;
    if (bRssi == null) return -1;
    return bRssi.compareTo(aRssi);
  }
}
