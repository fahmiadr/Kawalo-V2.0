package com.example.kawalo_mobile

import android.Manifest
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.view.KeyEvent
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.example.kawalo_mobile.auth.AuthTokenChannel
import com.example.kawalo_mobile.ptt.PttForegroundService
import com.example.kawalo_mobile.ptt.bridge.PttPlatformChannelBridge
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        // OEM PTT Hardware Key Codes (e.g. Zebra, Sonim, Cat, Blackview)
        const val KEYCODE_OEM_PTT = 284
        const val KEYCODE_OEM_PTT_ALT = 286
        const val REQUEST_RECORD_AUDIO_PERMISSION = 7001
        private const val REQUEST_NOTIFICATION_PERMISSION = 7002
        private const val REQUEST_IGNORE_BATTERY_OPTIMIZATIONS = 7003

        private const val BACKGROUND_ACCESS_CHANNEL = "kawalo/background_access"
        private const val BACKGROUND_ACCESS_PREFS = "kawalo_background_access"

        // One engine per process instead of one per activity. When the task is swiped away (or the activity
        // is destroyed for any other reason) the PTT foreground service keeps the process alive, and Dart stays
        // alive with it, so the PTT transcript upload queue and the session handling keep running. Token
        // refresh no longer depends on it (AuthTokenVault).
        private var processEngine: FlutterEngine? = null
    }

    private val pendingPermissionResults = mutableMapOf<Int, MethodChannel.Result>()
    private var pendingBatteryResult: MethodChannel.Result? = null

    override fun provideFlutterEngine(context: Context): FlutterEngine =
        processEngine ?: FlutterEngine(context.applicationContext).also { processEngine = it }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        AuthTokenChannel.init(this, flutterEngine.dartExecutor.binaryMessenger)
        // Initialize PTT Platform Channels with Activity reference
        PttPlatformChannelBridge.init(this, flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BACKGROUND_ACCESS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "status" -> result.success(backgroundAccessStatus())
                    "request" -> requestBackgroundAccess(call.argument<String>("item"), result)
                    "skip" -> {
                        backgroundAccessPrefs().edit().putBoolean("skipped", true).apply()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    fun requestRecordAudioPermission(result: MethodChannel.Result) =
        requestRuntimePermission(Manifest.permission.RECORD_AUDIO, REQUEST_RECORD_AUDIO_PERMISSION, result)

    private fun requestRuntimePermission(permission: String, requestCode: Int, result: MethodChannel.Result) {
        if (ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED) {
            result.success(true)
            return
        }
        pendingPermissionResults.remove(requestCode)?.success(false)
        pendingPermissionResults[requestCode] = result
        ActivityCompat.requestPermissions(this, arrayOf(permission), requestCode)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
        pendingPermissionResults.remove(requestCode)?.success(granted)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_IGNORE_BATTERY_OPTIMIZATIONS) {
            pendingBatteryResult?.success(isIgnoringBatteryOptimizations())
            pendingBatteryResult = null
        }
    }

    /* ---------------- Background access (asked once after login) ---------------- */

    private fun backgroundAccessPrefs() = getSharedPreferences(BACKGROUND_ACCESS_PREFS, MODE_PRIVATE)

    private fun isIgnoringBatteryOptimizations(): Boolean =
        (getSystemService(Context.POWER_SERVICE) as PowerManager).isIgnoringBatteryOptimizations(packageName)

    /**
     * Each item is "granted", "askable" or "refused". The prompt asks for an item at most once: an item that
     * was asked and is still missing counts as refused, and so does a notification block below Android 13,
     * where only the system settings can lift it.
     */
    private fun backgroundAccessStatus(): Map<String, Any> {
        val prefs = backgroundAccessPrefs()
        fun state(item: String, granted: Boolean, canAsk: Boolean = true) = when {
            granted -> "granted"
            canAsk && !prefs.getBoolean("asked_$item", false) -> "askable"
            else -> "refused"
        }
        return mapOf(
            "notifications" to state(
                "notifications",
                NotificationManagerCompat.from(this).areNotificationsEnabled(),
                canAsk = Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU
            ),
            "microphone" to state(
                "microphone",
                ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) ==
                    PackageManager.PERMISSION_GRANTED
            ),
            "battery" to state("battery", isIgnoringBatteryOptimizations()),
            "skipped" to prefs.getBoolean("skipped", false),
        )
    }

    private fun requestBackgroundAccess(item: String?, result: MethodChannel.Result) {
        if (item == null) {
            result.error("INVALID_ARGS", "item is required", null)
            return
        }
        backgroundAccessPrefs().edit().putBoolean("asked_$item", true).apply()
        when (item) {
            "notifications" -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                requestRuntimePermission(Manifest.permission.POST_NOTIFICATIONS, REQUEST_NOTIFICATION_PERMISSION, result)
            } else {
                result.success(NotificationManagerCompat.from(this).areNotificationsEnabled())
            }
            "microphone" -> requestRecordAudioPermission(result)
            "battery" -> requestIgnoreBatteryOptimizations(result)
            else -> result.error("INVALID_ARGS", "unknown item $item", null)
        }
    }

    private fun requestIgnoreBatteryOptimizations(result: MethodChannel.Result) {
        if (isIgnoringBatteryOptimizations()) {
            result.success(true)
            return
        }
        try {
            pendingBatteryResult?.success(false)
            pendingBatteryResult = result
            @Suppress("DEPRECATION")
            startActivityForResult(
                Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, Uri.parse("package:$packageName")),
                REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
            )
        } catch (_: ActivityNotFoundException) {
            // Some OEM builds drop the direct dialog; the list screen still lets the user exempt the app.
            pendingBatteryResult = null
            try {
                startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
            } catch (_: ActivityNotFoundException) {}
            result.success(false)
        }
    }

    private fun isPttKey(keyCode: Int): Boolean {
        return keyCode == KEYCODE_OEM_PTT ||
               keyCode == KEYCODE_OEM_PTT_ALT ||
               keyCode == KeyEvent.KEYCODE_HEADSETHOOK
    }

    /**
     * In-App Foreground Hardware Key Handling Fallback.
     * Note: Background pocket interception is handled by MediaSessionCompat and OEM BroadcastReceiver
     * inside PttForegroundService.
     */
    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (isPttKey(keyCode)) {
            val intent = Intent(this, PttForegroundService::class.java).apply {
                action = PttForegroundService.ACTION_START_TRANSMISSION
                putExtra(PttForegroundService.EXTRA_REQUEST_ID, "req_hw_${System.currentTimeMillis()}")
            }
            startService(intent)
            return true
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun onKeyUp(keyCode: Int, event: KeyEvent?): Boolean {
        if (isPttKey(keyCode)) {
            val intent = Intent(this, PttForegroundService::class.java).apply {
                action = PttForegroundService.ACTION_STOP_TRANSMISSION
            }
            startService(intent)
            return true
        }
        return super.onKeyUp(keyCode, event)
    }
}
