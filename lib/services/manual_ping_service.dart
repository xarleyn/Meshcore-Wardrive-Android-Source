import 'package:latlong2/latlong.dart';

import '../models/models.dart';
import '../utils/geohash_utils.dart';
import 'database_service.dart';
import 'lora_companion_service.dart';
import '../models/ping_result.dart';
import 'settings_service.dart';
import 'sound_service.dart';

/// Outcome of a manual ping, for the caller to present to the user.
class ManualPingOutcome {
  const ManualPingOutcome({required this.result, required this.pingSuccess});

  /// Raw companion ping result (status, responses, timing, error).
  final PingResult result;

  /// Whether the ping succeeded and produced at least one response sample.
  final bool pingSuccess;
}

/// Sends a manual LoRa ping and persists the resulting samples.
///
/// Owns the business side of the manual ping flow: the ping request, the
/// result sounds, and Sample construction/insertion into the database.
/// Presentation (snackbars, sample list reloads) stays with the caller, who
/// inspects the returned [ManualPingOutcome].
class ManualPingService {
  ManualPingService({
    required this.loraCompanion,
    required this.databaseService,
  });

  final LoRaCompanionService loraCompanion;
  final DatabaseService databaseService;

  /// Sends a ping from [position], plays the result sounds, and stores one
  /// sample per response (or a single failed sample).
  Future<ManualPingOutcome> ping({
    required LatLng position,
    required int timeoutSeconds,
    required String responseCollectionMode,
  }) async {
    SoundService().playPingSent();

    // Send ping via LoRa companion
    final result = await loraCompanion.ping(
      latitude: position.latitude,
      longitude: position.longitude,
      timeoutSeconds: timeoutSeconds,
      waitForAllResponses: true,
      collectUntilTimeout:
          responseCollectionMode == SettingsService.responseCollectionModeFull,
    );

    final responses = result.responses;
    final pingSuccess =
        result.status == PingStatus.success && responses.isNotEmpty;

    if (pingSuccess) {
      for (final response in responses) {
        await SoundService().playForPingResult(
          success: true,
          snr: response.snr,
          rssi: response.rssi,
        );
      }
    } else {
      await SoundService().playForPingResult(success: false);
    }

    // Create and save sample
    final geohash = GeohashUtils.sampleKey(
      position.latitude,
      position.longitude,
    );

    if (pingSuccess) {
      for (var index = 0; index < responses.length; index++) {
        final response = responses[index];
        final sample = Sample(
          id: '${DateTime.now().microsecondsSinceEpoch}_${index}_$geohash',
          position: position,
          timestamp: DateTime.now(),
          path: response.nodeId,
          geohash: geohash,
          rssi: response.rssi,
          snr: response.snr,
          pingSuccess: true,
          responseTimeMs: response.responseTimeMs,
          deviceId: loraCompanion.connectedDeviceId,
        );
        await databaseService.insertSample(sample);
      }
    } else {
      final sample = Sample(
        id: '${DateTime.now().microsecondsSinceEpoch}_$geohash',
        position: position,
        timestamp: DateTime.now(),
        geohash: geohash,
        pingSuccess: false,
        responseTimeMs: result.responseTimeMs,
        deviceId: loraCompanion.connectedDeviceId,
      );
      await databaseService.insertSample(sample);
    }

    return ManualPingOutcome(result: result, pingSuccess: pingSuccess);
  }
}
