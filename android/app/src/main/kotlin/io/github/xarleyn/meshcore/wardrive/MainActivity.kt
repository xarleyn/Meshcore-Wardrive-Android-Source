package io.github.xarleyn.meshcore.wardrive

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.provider.Settings
import android.util.Log
import android.net.wifi.WifiManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val TAG = "MeshcoreFeedback"
    private val CHANNEL = "io.github.xarleyn.meshcore.wardrive/feedback"
    private val WIFI_CHANNEL = "io.github.xarleyn.meshcore.wardrive/wifi_location"
    private val TRACKING_SETTINGS_CHANNEL =
        "io.github.xarleyn.meshcore.wardrive/tracking_settings"
    private var toneGenerator: ToneGenerator? = null

    private fun getVibrator(): Vibrator {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val mgr = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            mgr.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        toneGenerator = try {
            ToneGenerator(AudioManager.STREAM_MUSIC, 100)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create ToneGenerator", e)
            null
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "playTone" -> {
                        val tone = call.argument<Int>("tone") ?: ToneGenerator.TONE_PROP_BEEP
                        val durationMs = call.argument<Int>("durationMs") ?: 150
                        toneGenerator?.startTone(tone, durationMs)
                        result.success(null)
                    }
                    "vibrate" -> {
                        try {
                            val durationMs = (call.argument<Int>("durationMs") ?: 100).toLong()
                            val amplitude = call.argument<Int>("amplitude") ?: VibrationEffect.DEFAULT_AMPLITUDE
                            val vibrator = getVibrator()
                            Log.d(TAG, "Vibrator hasVibrator=${vibrator.hasVibrator()}, SDK=${Build.VERSION.SDK_INT}")
                            val effect = VibrationEffect.createOneShot(durationMs, amplitude)
                            if (Build.VERSION.SDK_INT >= 33) {
                                // Use ALARM usage so vibration isn't blocked by "touch vibration" setting
                                val attrs = VibrationAttributes.Builder()
                                    .setUsage(VibrationAttributes.USAGE_ALARM)
                                    .build()
                                vibrator.vibrate(effect, attrs)
                                Log.d(TAG, "Vibrate (ALARM attrs): ${durationMs}ms, amp=$amplitude")
                            } else {
                                vibrator.vibrate(effect)
                                Log.d(TAG, "Vibrate (default): ${durationMs}ms, amp=$amplitude")
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e(TAG, "Vibrate failed", e)
                            result.error("VIBRATE_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIFI_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getWifiScanResults" -> getWifiScanResults(result)
                    else -> result.notImplemented()
                }
            }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            TRACKING_SETTINGS_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isWifiScanThrottlingEnabled" -> {
                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
                        result.success(false)
                    } else {
                        try {
                            result.success(
                                Settings.Global.getInt(
                                    contentResolver,
                                    "wifi_scan_throttle_enabled",
                                    1,
                                ) != 0,
                            )
                        } catch (e: SecurityException) {
                            Log.w(TAG, "Could not read Wi-Fi scan throttling setting", e)
                            result.success(null)
                        }
                    }
                }
                "openWifiScanThrottlingSettings" -> {
                    result.success(openWifiScanThrottlingSettings())
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun openWifiScanThrottlingSettings(): Boolean {
        val developerSettings = Intent(Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS)
        val intent = if (developerSettings.resolveActivity(packageManager) != null) {
            developerSettings
        } else {
            Intent(Settings.ACTION_SETTINGS)
        }

        return try {
            startActivity(intent)
            true
        } catch (e: Exception) {
            Log.e(TAG, "Could not open Wi-Fi scan throttling settings", e)
            false
        }
    }

    @Suppress("DEPRECATION")
    private fun getWifiScanResults(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) !=
                PackageManager.PERMISSION_GRANTED
        ) {
            result.error("LOCATION_PERMISSION", "Fine location permission is required", null)
            return
        }

        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        val scanStarted = try {
            wifiManager.startScan()
        } catch (e: SecurityException) {
            result.error("WIFI_PERMISSION", e.message, null)
            return
        } catch (e: Exception) {
            Log.w(TAG, "Wi-Fi scan could not be started", e)
            false
        }

        // Android may throttle startScan(). Cached/passively refreshed results
        // are still useful, and each result carries its age for Dart to check.
        val delayMs = if (scanStarted) 1_500L else 0L
        Handler(Looper.getMainLooper()).postDelayed({
            try {
                val nowMicros = SystemClock.elapsedRealtimeNanos() / 1_000L
                val scans = wifiManager.scanResults.map { scan ->
                    mapOf(
                        "bssid" to scan.BSSID,
                        "ssid" to scan.SSID,
                        "signalStrength" to scan.level,
                        "frequency" to scan.frequency,
                        "ageMillis" to ((nowMicros - scan.timestamp).coerceAtLeast(0L) / 1_000L),
                    )
                }
                result.success(scans)
            } catch (e: SecurityException) {
                result.error("WIFI_PERMISSION", e.message, null)
            } catch (e: Exception) {
                result.error("WIFI_SCAN", e.message, null)
            }
        }, delayMs)
    }

    override fun onDestroy() {
        toneGenerator?.release()
        toneGenerator = null
        super.onDestroy()
    }
}
