package com.example.kawalo_mobile

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.view.KeyEvent
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
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
    }

    private var pendingRecordAudioResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Initialize PTT Platform Channels with Activity reference
        PttPlatformChannelBridge.init(this, flutterEngine)
    }

    fun requestRecordAudioPermission(result: MethodChannel.Result) {
        if (ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.RECORD_AUDIO
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            result.success(true)
            return
        }

        pendingRecordAudioResult = result
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.RECORD_AUDIO),
            REQUEST_RECORD_AUDIO_PERMISSION
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_RECORD_AUDIO_PERMISSION) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingRecordAudioResult?.success(granted)
            pendingRecordAudioResult = null
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
