package com.example.kawalo_mobile.ptt

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.SoundPool
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import android.util.Log
import android.view.KeyEvent
import androidx.core.app.NotificationCompat
import com.example.kawalo_mobile.MainActivity
import com.example.kawalo_mobile.R
import com.example.kawalo_mobile.ptt.audio.PttAudioEngine
import com.example.kawalo_mobile.ptt.bridge.PttPlatformChannelBridge
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import okio.ByteString
import okio.ByteString.Companion.toByteString
import org.json.JSONObject
import java.util.concurrent.TimeUnit

class PttForegroundService : Service() {
    companion object {
        private const val TAG = "PttForegroundService"
        private const val NOTIFICATION_CHANNEL_ID = "kawalo_ptt_channel"
        private const val NOTIFICATION_ID = 9021

        const val ACTION_JOIN_CHANNEL = "com.example.kawalo_mobile.ptt.JOIN_CHANNEL"
        const val ACTION_LEAVE_CHANNEL = "com.example.kawalo_mobile.ptt.LEAVE_CHANNEL"
        const val ACTION_START_TRANSMISSION = "com.example.kawalo_mobile.ptt.START_TRANSMISSION"
        const val ACTION_STOP_TRANSMISSION = "com.example.kawalo_mobile.ptt.STOP_TRANSMISSION"
        const val ACTION_UPDATE_AUTH_TOKEN = "com.example.kawalo_mobile.ptt.UPDATE_AUTH_TOKEN"

        const val EXTRA_CHANNEL_URL = "channelUrl"
        const val EXTRA_GROUP_UID = "groupUid"
        const val EXTRA_TOKEN = "token"
        const val EXTRA_REQUEST_ID = "requestId"
    }

    private var wakeLock: PowerManager.WakeLock? = null
    private var audioEngine: PttAudioEngine? = null
    private var soundPool: SoundPool? = null
    private var vibrator: Vibrator? = null

    // SoundPool sound IDs
    private var soundChirpId = 0
    private var soundBonkId = 0
    private var soundWarbleId = 0
    private var soundRogerId = 0

    // Networking
    private var okHttpClient: OkHttpClient? = null
    private var webSocket: WebSocket? = null
    private var activeChannelUrl: String? = null
    private var activeGroupUid: String? = null
    private var activeToken: String? = null
    private val reconnectHandler = android.os.Handler(android.os.Looper.getMainLooper())
    private var isReconnecting = false
    private var reconnectAttempt = 0

    // OkHttp reports a cancel()ed socket through onFailure. Without this guard that stale callback
    // schedules a reconnect which cancels the healthy replacement, and the loop never ends (the
    // channel flaps every ~2 s). Callbacks from any socket but the current generation are ignored.
    @Volatile private var socketGeneration = 0

    // MediaSession for screen-off headset button capture (BLK-03)
    private var mediaSession: MediaSessionCompat? = null
    private var isPttTriggerPressed = false

    // OEM Rugged Side-Key Receiver
    private val oemKeyReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val action = intent?.action ?: return
            Log.d(TAG, "OEM Key Intent received: $action")
            if (action.contains("DOWN") || action.contains("PRESSED")) {
                handlePttTriggerPressed()
            } else if (action.contains("UP") || action.contains("RELEASED")) {
                handlePttTriggerReleased()
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        acquireWakeLock()
        initAudioAndHaptics()
        initMediaSession()
        registerOemKeyReceivers()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action ?: return START_STICKY

        when (action) {
            ACTION_JOIN_CHANNEL -> {
                val channelUrl = intent.getStringExtra(EXTRA_CHANNEL_URL) ?: return START_STICKY
                val groupUid = intent.getStringExtra(EXTRA_GROUP_UID) ?: return START_STICKY
                val token = intent.getStringExtra(EXTRA_TOKEN) ?: return START_STICKY

                startForegroundWithNotification("Menghubungkan ke Saluran PTT...")
                connectWebSocket(channelUrl, groupUid, token)
            }

            ACTION_LEAVE_CHANNEL -> {
                disconnectWebSocket()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }

            ACTION_START_TRANSMISSION -> {
                val requestId = intent.getStringExtra(EXTRA_REQUEST_ID) ?: "req_${System.currentTimeMillis()}"
                handlePttTriggerPressed(requestId)
            }

            ACTION_STOP_TRANSMISSION -> {
                handlePttTriggerReleased()
            }

            ACTION_UPDATE_AUTH_TOKEN -> {
                val token = intent.getStringExtra(EXTRA_TOKEN)
                if (!token.isNullOrEmpty()) {
                    activeToken = token
                }
            }
        }

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    /* ---------------- Lifecycle & Initialization ---------------- */

    private fun acquireWakeLock() {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Kawalo::PttWakeLock").apply {
            setReferenceCounted(false)
            acquire(12 * 60 * 60 * 1000L) // 12-hour max patrol shift
        }
    }

    private fun initAudioAndHaptics() {
        audioEngine = PttAudioEngine(this).apply {
            onAudioPacketReady = { packet ->
                webSocket?.send(packet.toByteString())
            }
            startPlayback()
        }

        val audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        soundPool = SoundPool.Builder()
            .setMaxStreams(4)
            .setAudioAttributes(audioAttributes)
            .build()

        // Load acoustic cues from res/raw
        soundChirpId = soundPool?.load(this, R.raw.chirp, 1) ?: 0
        soundBonkId = soundPool?.load(this, R.raw.bonk, 1) ?: 0
        soundWarbleId = soundPool?.load(this, R.raw.warble, 1) ?: 0
        soundRogerId = soundPool?.load(this, R.raw.roger, 1) ?: 0

        vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            vibratorManager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
    }

    private fun initMediaSession() {
        mediaSession = MediaSessionCompat(this, "KawaloPttMediaSession").apply {
            setFlags(MediaSessionCompat.FLAG_HANDLES_MEDIA_BUTTONS or MediaSessionCompat.FLAG_HANDLES_TRANSPORT_CONTROLS)

            val state = PlaybackStateCompat.Builder()
                .setActions(PlaybackStateCompat.ACTION_PLAY_PAUSE or PlaybackStateCompat.ACTION_FAST_FORWARD)
                .setState(PlaybackStateCompat.STATE_PLAYING, 0, 1.0f)
                .build()
            setPlaybackState(state)

            setCallback(object : MediaSessionCompat.Callback() {
                override fun onMediaButtonEvent(mediaButtonEvent: Intent?): Boolean {
                    val keyEvent = mediaButtonEvent?.getParcelableExtra<KeyEvent>(Intent.EXTRA_KEY_EVENT)
                    if (keyEvent != null && keyEvent.keyCode == KeyEvent.KEYCODE_HEADSETHOOK) {
                        if (keyEvent.action == KeyEvent.ACTION_DOWN) {
                            handlePttTriggerPressed()
                        } else if (keyEvent.action == KeyEvent.ACTION_UP) {
                            handlePttTriggerReleased()
                        }
                        return true
                    }
                    return super.onMediaButtonEvent(mediaButtonEvent)
                }
            })
            isActive = true
        }
    }

    private fun registerOemKeyReceivers() {
        val filter = IntentFilter().apply {
            addAction("com.samsung.knox.action.PTT_KEY_DOWN")
            addAction("com.samsung.knox.action.PTT_KEY_UP")
            addAction("com.symbol.button.RUGGED_PTT_DOWN")
            addAction("com.symbol.button.RUGGED_PTT_UP")
            addAction("android.intent.action.PTT_BUTTON_DOWN")
            addAction("android.intent.action.PTT_BUTTON_UP")
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(oemKeyReceiver, filter, RECEIVER_EXPORTED)
        } else {
            registerReceiver(oemKeyReceiver, filter)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Kawalo PTT Walkie-Talkie",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Layanan aktif komunikasi suara Walkie-Talkie di latar belakang"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun startForegroundWithNotification(statusText: String) {
        val notification = buildNotification(statusText)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // Android 14+ (API 34/35/36): Layanan latar belakang PTT saat idle/mendengarkan
            // hanya memerlukan tipe mediaPlayback. Tipe microphone ditambahkan secara dinamis
            // hanya ketika floor telah diberikan (granted) dan transmisi audio aktif.
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun updateForegroundServiceType(isRecording: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val hasRecordAudio = androidx.core.content.ContextCompat.checkSelfPermission(
                this,
                android.Manifest.permission.RECORD_AUDIO
            ) == android.content.pm.PackageManager.PERMISSION_GRANTED

            val type = if (isRecording && hasRecordAudio) {
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK or ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
            } else {
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
            }
            try {
                startForeground(
                    NOTIFICATION_ID,
                    buildNotification(if (isRecording) "Transmisi Suara Aktif" else "Saluran PTT Terhubung"),
                    type
                )
            } catch (e: Exception) {
                Log.w(TAG, "Failed to update foreground service type: ${e.message}")
            }
        }
    }

    private fun buildNotification(statusText: String): Notification {
        val launchIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("Kawalo PTT Aktif")
            .setContentText(statusText)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    /* ---------------- WebSocket Networking ---------------- */

    private fun connectWebSocket(channelUrl: String, groupUid: String, token: String) {
        activeChannelUrl = channelUrl
        activeGroupUid = groupUid
        activeToken = token

        val generation = ++socketGeneration
        reconnectHandler.removeCallbacksAndMessages(null)
        isReconnecting = false
        try {
            webSocket?.cancel()
        } catch (_: Exception) {}

        Log.i(TAG, "Connecting PTT WebSocket to $channelUrl with groupUid=$groupUid")

        okHttpClient = OkHttpClient.Builder()
            .readTimeout(0, TimeUnit.MILLISECONDS)
            .connectTimeout(5000, TimeUnit.MILLISECONDS)
            .pingInterval(10, TimeUnit.SECONDS)
            .build()

        val fullUrl = if (channelUrl.contains("?")) {
            "$channelUrl&token=$token"
        } else {
            "$channelUrl?token=$token"
        }

        val request = Request.Builder()
            .url(fullUrl)
            .addHeader("Authorization", "Bearer $token")
            .build()

        PttPlatformChannelBridge.dispatchEvent("connectionStatusChanged", mapOf("status" to "CONNECTING"))

        webSocket = okHttpClient?.newWebSocket(request, object : WebSocketListener() {
            override fun onOpen(webSocket: WebSocket, response: Response) {
                if (generation != socketGeneration) return
                Log.i(TAG, "PTT WebSocket connected successfully to $activeGroupUid")
                reconnectAttempt = 0
                isReconnecting = false
                startForegroundWithNotification("Saluran PTT Terhubung - Siap Bicara")
                PttPlatformChannelBridge.dispatchEvent("connectionStatusChanged", mapOf("status" to "CONNECTED"))
            }

            private var inboundAudioFrameCount = 0

            override fun onMessage(webSocket: WebSocket, text: String) {
                if (generation != socketGeneration) return
                handleInboundJsonFrame(text)
            }

            override fun onMessage(webSocket: WebSocket, bytes: ByteString) {
                if (generation != socketGeneration) return
                // Incoming binary Opus audio packet with 7-byte header
                inboundAudioFrameCount++
                if (inboundAudioFrameCount % 50 == 1) {
                    Log.d(TAG, "Inbound binary audio frame #$inboundAudioFrameCount (${bytes.size} bytes)")
                }
                audioEngine?.jitterBuffer?.pushFrame(bytes.toByteArray())
            }

            override fun onClosing(webSocket: WebSocket, code: Int, reason: String) {
                if (generation != socketGeneration) return
                Log.w(TAG, "PTT WebSocket closing: $code / $reason")
            }

            override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
                if (generation != socketGeneration) return
                Log.i(TAG, "PTT WebSocket closed: $code / $reason")
                PttPlatformChannelBridge.dispatchEvent("connectionStatusChanged", mapOf("status" to "DISCONNECTED"))
            }

            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                if (generation != socketGeneration) return
                val respCode = response?.code ?: -1
                val respMsg = response?.message ?: "None"
                val bodyStr = try { response?.body?.string() } catch (_: Exception) { null }
                Log.e(TAG, "PTT WebSocket failure: ${t.message} | HTTP $respCode ($respMsg) | Body: $bodyStr", t)
                PttPlatformChannelBridge.dispatchEvent("connectionStatusChanged", mapOf("status" to "RECONNECTING"))
                scheduleReconnect()
            }
        })
    }

    private fun scheduleReconnect() {
        if (isReconnecting) return
        val url = activeChannelUrl
        val group = activeGroupUid
        val token = activeToken
        if (url.isNullOrEmpty() || group.isNullOrEmpty() || token.isNullOrEmpty()) {
            return
        }

        isReconnecting = true
        val delayMs = minOf(2000L * (1L shl minOf(reconnectAttempt, 3)), 15000L)
        reconnectAttempt++
        Log.i(TAG, "Scheduling PTT WebSocket reconnect in ${delayMs}ms (attempt #$reconnectAttempt)")
        reconnectHandler.postDelayed({
            isReconnecting = false
            if (activeChannelUrl != null && activeGroupUid != null && activeToken != null) {
                Log.i(TAG, "Attempting PTT WebSocket auto-reconnect...")
                connectWebSocket(activeChannelUrl!!, activeGroupUid!!, activeToken!!)
            }
        }, delayMs)
    }

    private fun disconnectWebSocket() {
        socketGeneration++
        reconnectHandler.removeCallbacksAndMessages(null)
        isReconnecting = false
        reconnectAttempt = 0
        try {
            webSocket?.close(1000, "User Left Channel")
        } catch (e: Exception) {
            Log.w(TAG, "Error closing websocket: ${e.message}")
        }
        webSocket = null
    }

    /* ---------------- Inbound JSON Wire Frame Handler ---------------- */

    private fun handleInboundJsonFrame(jsonStr: String) {
        try {
            val json = JSONObject(jsonStr)
            val type = json.optString("type")

            when (type) {
                "FLOOR_GRANTED" -> {
                    if (!isPttTriggerPressed) {
                        Log.w(TAG, "FLOOR_GRANTED received but trigger was already released. Immediately releasing floor.")
                        handlePttTriggerReleased()
                        return
                    }

                    // Play Chirp & vibrate 50ms pulse
                    playChirpTone()
                    vibrateHaptic(50)

                    // Lazy microphone start with dynamic FGS type update
                    updateForegroundServiceType(true)
                    audioEngine?.startRecording()

                    PttPlatformChannelBridge.dispatchEvent(
                        "transmissionStateChanged",
                        mapOf(
                            "state" to "GRANTED",
                            "requestId" to json.optString("requestId"),
                            "leaseTtlMs" to json.optInt("leaseTtlMs", 2000)
                        )
                    )
                }

                "FLOOR_DENIED" -> {
                    // Play Bonk & double 100ms vibration
                    playBonkTone()
                    vibratePattern(longArrayOf(0, 100, 50, 100))

                    val speakerObj = json.optJSONObject("currentSpeaker")
                    val speakerMap = if (speakerObj != null) {
                        mapOf(
                            "userId" to speakerObj.optString("userId"),
                            "name" to speakerObj.optString("name"),
                            "role" to speakerObj.optString("role")
                        )
                    } else null

                    PttPlatformChannelBridge.dispatchEvent(
                        "transmissionStateChanged",
                        mapOf(
                            "state" to "DENIED",
                            "requestId" to json.optString("requestId"),
                            "reason" to json.optString("reason"),
                            "currentSpeaker" to speakerMap
                        )
                    )
                }

                "FLOOR_REVOKED" -> {
                    // Preempted by Admin or TOT expired: Mute microphone immediately
                    audioEngine?.stopRecording()
                    updateForegroundServiceType(false)

                    // Play Warble alarm & triple 150ms vibration
                    playWarbleTone()
                    vibratePattern(longArrayOf(0, 150, 50, 150, 50, 150))

                    PttPlatformChannelBridge.dispatchEvent(
                        "transmissionStateChanged",
                        mapOf(
                            "state" to "REVOKED",
                            "reason" to json.optString("reason"),
                            "preemptedBy" to json.optString("preemptedBy")
                        )
                    )
                }

                "FLOOR_RESET" -> {
                    // Preemption buffer flush: purge jitter buffer to eliminate old speech collision
                    audioEngine?.purgeJitterBuffer()
                }

                "FLOOR_STATE_CHANGED" -> {
                    val state = json.optString("state")
                    val memberCount = json.optInt("memberCount", 1)
                    val speakerObj = json.optJSONObject("speaker")

                    val speakerMap = if (speakerObj != null) {
                        mapOf(
                            "userId" to speakerObj.optString("userId"),
                            "name" to speakerObj.optString("name"),
                            "role" to speakerObj.optString("role")
                        )
                    } else null

                    if (state == "IDLE") {
                        playRogerTone()
                        audioEngine?.purgeJitterBuffer()
                    } else if (state == "TRANSMITTING" || state == "TAKEN") {
                        audioEngine?.purgeJitterBuffer()
                    }

                    PttPlatformChannelBridge.dispatchEvent(
                        "floorStateChanged",
                        mapOf(
                            "state" to state,
                            "speaker" to speakerMap,
                            "memberCount" to memberCount
                        )
                    )
                }

                "MEMBER_COUNT_UPDATED" -> {
                    val memberCount = json.optInt("memberCount", 1)
                    PttPlatformChannelBridge.dispatchEvent(
                        "memberCountChanged",
                        mapOf("memberCount" to memberCount)
                    )
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error handling inbound frame: ${e.message}")
        }
    }

    /* ---------------- PTT Trigger Actions ---------------- */

    private fun handlePttTriggerPressed(requestId: String = "req_${System.currentTimeMillis()}") {
        isPttTriggerPressed = true
        val ws = webSocket
        if (ws == null) {
            isPttTriggerPressed = false
            Log.w(TAG, "Cannot send FLOOR_REQUEST: WebSocket is null")
            playBonkTone()
            vibratePattern(longArrayOf(0, 100, 50, 100))
            PttPlatformChannelBridge.dispatchEvent(
                "transmissionStateChanged",
                mapOf(
                    "state" to "DENIED",
                    "requestId" to requestId,
                    "reason" to "NOT_CONNECTED"
                )
            )
            return
        }
        val requestJson = JSONObject().apply {
            put("type", "FLOOR_REQUEST")
            put("requestId", requestId)
        }
        val sent = ws.send(requestJson.toString())
        if (!sent) {
            isPttTriggerPressed = false
            Log.w(TAG, "Failed to send FLOOR_REQUEST over WebSocket")
            playBonkTone()
            vibratePattern(longArrayOf(0, 100, 50, 100))
            PttPlatformChannelBridge.dispatchEvent(
                "transmissionStateChanged",
                mapOf(
                    "state" to "DENIED",
                    "requestId" to requestId,
                    "reason" to "TRANSMISSION_ERROR"
                )
            )
        }
    }

    private fun handlePttTriggerReleased() {
        isPttTriggerPressed = false
        audioEngine?.stopRecording()
        updateForegroundServiceType(false)
        val releaseJson = JSONObject().apply {
            put("type", "FLOOR_RELEASED")
            put("reason", "BUTTON_RELEASED")
        }
        webSocket?.send(releaseJson.toString())
    }

    /* ---------------- Acoustic & Haptic Helpers ---------------- */

    private fun playChirpTone() = soundPool?.play(soundChirpId, 1.0f, 1.0f, 1, 0, 1.0f)
    private fun playBonkTone() = soundPool?.play(soundBonkId, 1.0f, 1.0f, 1, 0, 1.0f)
    private fun playWarbleTone() = soundPool?.play(soundWarbleId, 1.0f, 1.0f, 1, 0, 1.0f)
    private fun playRogerTone() = soundPool?.play(soundRogerId, 0.6f, 0.6f, 1, 0, 1.0f)

    private fun vibrateHaptic(durationMs: Long) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator?.vibrate(VibrationEffect.createOneShot(durationMs, VibrationEffect.DEFAULT_AMPLITUDE))
        } else {
            @Suppress("DEPRECATION")
            vibrator?.vibrate(durationMs)
        }
    }

    private fun vibratePattern(pattern: LongArray) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator?.vibrate(VibrationEffect.createWaveform(pattern, -1))
        } else {
            @Suppress("DEPRECATION")
            vibrator?.vibrate(pattern, -1)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        disconnectWebSocket()
        audioEngine?.stopRecording()
        audioEngine?.stopPlayback()
        soundPool?.release()
        mediaSession?.release()
        try {
            unregisterReceiver(oemKeyReceiver)
        } catch (_: Exception) {}
        wakeLock?.let {
            if (it.isHeld) it.release()
        }
    }
}
