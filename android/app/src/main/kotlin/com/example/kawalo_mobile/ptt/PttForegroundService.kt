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
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
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
import com.example.kawalo_mobile.auth.AuthTokenChannel
import com.example.kawalo_mobile.auth.AuthTokenVault
import com.example.kawalo_mobile.ptt.audio.PttAudioEngine
import com.example.kawalo_mobile.ptt.audio.PttTranscriber
import com.example.kawalo_mobile.ptt.bridge.PttPlatformChannelBridge
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import okio.ByteString
import okio.ByteString.Companion.toByteString
import org.json.JSONObject
import java.util.concurrent.Executors
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
        const val ACTION_TOGGLE_TRANSMISSION = "com.example.kawalo_mobile.ptt.TOGGLE_TRANSMISSION"

        const val EXTRA_CHANNEL_URL = "channelUrl"
        const val EXTRA_GROUP_UID = "groupUid"
        const val EXTRA_TOKEN = "token"
        const val EXTRA_REQUEST_ID = "requestId"

        private const val STABLE_CONNECTION_MS = 10_000L

        // A freshly refreshed token that the socket still rejects (e.g. a revoked session version) must not
        // rotate the refresh token on every reconnect attempt.
        private const val REFRESH_COOLDOWN_MS = 60_000L

        // Channel of the current join, kept so a service restarted after process death can rejoin by itself.
        private const val CHANNEL_PREFS = "kawalo_ptt_service"
        private const val PREF_CHANNEL_URL = "channel_url"
        private const val PREF_GROUP_UID = "group_uid"

        // The channel stays joined for the whole login (no shift gate since 13 Nov 2026), so the lock is
        // re-armed before its timeout instead of being held without one.
        // ponytail: held for as long as the channel is joined; an idle-aware release needs the AudioTrack
        // to stop between turns first.
        private const val WAKE_LOCK_TIMEOUT_MS = 12 * 60 * 60 * 1000L
        private const val WAKE_LOCK_RENEW_MS = 11 * 60 * 60 * 1000L

        private const val TEXT_CONNECTING = "Menghubungkan ke Saluran PTT..."
        private const val TEXT_CONNECTED = "Saluran PTT Terhubung - Siap Bicara"
        private const val TEXT_RECONNECTING = "Menyambung ulang ke Saluran PTT..."
    }

    private var wakeLock: PowerManager.WakeLock? = null
    private var wifiLock: WifiManager.WifiLock? = null
    private val wakeLockHandler = Handler(Looper.getMainLooper())
    private val renewWakeLock = object : Runnable {
        override fun run() {
            wakeLock?.acquire(WAKE_LOCK_TIMEOUT_MS)
            wakeLockHandler.postDelayed(this, WAKE_LOCK_RENEW_MS)
        }
    }

    // What the ongoing notification shows (see notificationText()). Written from OkHttp callbacks and from
    // service intents on the main thread.
    @Volatile private var connectionText = TEXT_CONNECTING
    @Volatile private var isConnected = false
    @Volatile private var speakerName: String? = null
    @Volatile private var isTransmitting = false
    @Volatile private var isForegroundStarted = false
    private var audioEngine: PttAudioEngine? = null
    private var transcriber: PttTranscriber? = null

    // The id sent in the last FLOOR_REQUEST; the server records the turn under it and the transcript upload
    // addresses the recording by it.
    @Volatile private var lastRequestId: String? = null
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
    // Fallback for the rare case the vault is unreadable; the vault's token always wins.
    private var activeToken: String? = null
    private var tokenInUse: String? = null
    private val refreshExecutor = Executors.newSingleThreadExecutor()
    private var lastRefreshAt = 0L
    private val reconnectHandler = android.os.Handler(android.os.Looper.getMainLooper())
    private var isReconnecting = false
    private var reconnectAttempt = 0
    private val resetAttemptRunnable = Runnable { reconnectAttempt = 0 }

    // OkHttp reports a cancel()ed socket through onFailure. Without this guard that stale callback
    // schedules a reconnect which cancels the healthy replacement, and the loop never ends (the
    // channel flaps every ~2 s). Callbacks from any socket but the current generation are ignored.
    @Volatile private var socketGeneration = 0

    // MediaSession for screen-off headset button capture (BLK-03)
    private var mediaSession: MediaSessionCompat? = null
    @Volatile private var isPttTriggerPressed = false

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
        AuthTokenVault.init(this)
        acquireWakeLock()
        acquireWifiLock()
        initAudioAndHaptics()
        initMediaSession()
        registerOemKeyReceivers()
        createNotificationChannel()
    }

    // Sticky: after process death the system restarts the service with a null intent and it rejoins the saved
    // channel with the vault's tokens, without Dart. Android 12+ allows that background start only when the
    // app is exempt from battery optimization (asked after login); otherwise startForeground throws and the
    // service stops until the app is opened.
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action ?: return restoreChannel()
        // A trigger or token intent (hardware key, late Dart call) would otherwise recreate a stopped service
        // as a background service that holds the wake lock without a channel.
        if (action != ACTION_JOIN_CHANNEL && !isForegroundStarted) {
            stopSelf()
            return START_NOT_STICKY
        }

        when (action) {
            ACTION_JOIN_CHANNEL -> {
                val channelUrl = intent.getStringExtra(EXTRA_CHANNEL_URL) ?: return START_NOT_STICKY
                val groupUid = intent.getStringExtra(EXTRA_GROUP_UID) ?: return START_NOT_STICKY
                val token = intent.getStringExtra(EXTRA_TOKEN) ?: return START_NOT_STICKY

                // Dart rejoins on every app resume; a service that rejoined by itself must not drop the socket.
                if (isConnected && channelUrl == activeChannelUrl && groupUid == activeGroupUid) {
                    PttPlatformChannelBridge.dispatchEvent("connectionStatusChanged", mapOf("status" to "CONNECTED"))
                    return START_STICKY
                }
                getSharedPreferences(CHANNEL_PREFS, MODE_PRIVATE).edit()
                    .putString(PREF_CHANNEL_URL, channelUrl)
                    .putString(PREF_GROUP_UID, groupUid)
                    .apply()
                startForegroundWithNotification(TEXT_CONNECTING)
                // No-op while already playing; re-arms playback if the AudioTrack failed to initialize earlier.
                audioEngine?.startPlayback()
                activeToken = token
                connectWebSocket(channelUrl, groupUid)
            }

            ACTION_LEAVE_CHANNEL -> endChannel()

            ACTION_START_TRANSMISSION -> {
                val requestId = intent.getStringExtra(EXTRA_REQUEST_ID) ?: "req_${System.currentTimeMillis()}"
                handlePttTriggerPressed(requestId)
            }

            ACTION_STOP_TRANSMISSION -> {
                handlePttTriggerReleased()
            }

            // A notification action delivers a single click, never press and release, so the notification
            // button toggles. The server's 30 s time-out timer ends a turn that is never stopped.
            ACTION_TOGGLE_TRANSMISSION -> {
                if (isPttTriggerPressed) {
                    handlePttTriggerReleased()
                    // Dart did not start this turn, so it would otherwise keep showing it as transmitting.
                    PttPlatformChannelBridge.dispatchEvent("transmissionStateChanged", mapOf("state" to "RELEASED"))
                } else {
                    handlePttTriggerPressed("req_ntf_${System.currentTimeMillis()}")
                }
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

    private fun restoreChannel(): Int {
        val prefs = getSharedPreferences(CHANNEL_PREFS, MODE_PRIVATE)
        val channelUrl = prefs.getString(PREF_CHANNEL_URL, null)
        val groupUid = prefs.getString(PREF_GROUP_UID, null)
        if (channelUrl == null || groupUid == null || AuthTokenVault.refreshToken() == null) {
            stopSelf()
            return START_NOT_STICKY
        }
        try {
            startForegroundWithNotification(TEXT_CONNECTING)
        } catch (e: Exception) {
            Log.w(TAG, "Cannot restart PTT in the background: ${e.message}")
            isForegroundStarted = false
            stopSelf()
            return START_NOT_STICKY
        }
        Log.i(TAG, "Restored PTT channel after a restart")
        audioEngine?.startPlayback()
        connectWebSocket(channelUrl, groupUid)
        return START_STICKY
    }

    /** Leaves the channel for good: a user leave, a logout, or a session the server ended. */
    private fun endChannel() {
        isForegroundStarted = false
        disconnectWebSocket()
        getSharedPreferences(CHANNEL_PREFS, MODE_PRIVATE).edit().clear().apply()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    /* ---------------- Lifecycle & Initialization ---------------- */

    private fun acquireWakeLock() {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Kawalo::PttWakeLock").apply {
            setReferenceCounted(false)
            acquire(WAKE_LOCK_TIMEOUT_MS)
        }
        wakeLockHandler.postDelayed(renewWakeLock, WAKE_LOCK_RENEW_MS)
    }

    // Keeps Wi-Fi out of power save while the screen is off so voice packets are not batched. Android 14
    // deprecated HIGH_PERF and its successor (LOW_LATENCY) only works with the screen on, so on 14+ this may
    // do nothing; it is harmless there.
    @Suppress("DEPRECATION")
    private fun acquireWifiLock() {
        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager ?: return
        wifiLock = wifiManager.createWifiLock(WifiManager.WIFI_MODE_FULL_HIGH_PERF, "Kawalo::PttWifiLock").apply {
            setReferenceCounted(false)
            acquire()
        }
    }

    private fun initAudioAndHaptics() {
        audioEngine = PttAudioEngine(this).apply {
            onAudioPacketReady = { packet ->
                webSocket?.send(packet.toByteString())
            }
            startPlayback()
        }
        val engine = audioEngine
        transcriber = PttTranscriber(
            context = this,
            isOwnMicActive = { engine?.isRecordingActive == true },
            report = { PttPlatformChannelBridge.dispatchEvent("transcriptReady", it) },
        )
        audioEngine?.onPcmFrame = { frame, count -> transcriber?.onPcmFrame(frame, count) }

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
                // User decision 13 Nov 2026: the speaker's name and the Talk/Stop button must work from the
                // lock screen, accepting that anyone holding the phone sees who is talking.
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun startForegroundWithNotification(statusText: String) {
        connectionText = statusText
        isForegroundStarted = true
        val notification = buildNotification()
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

    /** False when the system refused the microphone type (e.g. started from the background on Android 14+). */
    private fun updateForegroundServiceType(isRecording: Boolean): Boolean {
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
                startForeground(NOTIFICATION_ID, buildNotification(), type)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to update foreground service type: ${e.message}")
                return false
            }
        } else {
            refreshNotification()
        }
        return true
    }

    private fun notificationText(): String {
        val speaker = speakerName
        return when {
            isTransmitting -> "Anda sedang bicara"
            isConnected && speaker != null -> "$speaker sedang bicara"
            else -> connectionText
        }
    }

    private fun refreshNotification() {
        if (!isForegroundStarted) return
        getSystemService(NotificationManager::class.java).notify(NOTIFICATION_ID, buildNotification())
    }

    private fun buildNotification(): Notification {
        val launchIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("Kawalo PTT Aktif")
            .setContentText(notificationText())
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)

        val canTalk = androidx.core.content.ContextCompat.checkSelfPermission(
            this,
            android.Manifest.permission.RECORD_AUDIO
        ) == android.content.pm.PackageManager.PERMISSION_GRANTED
        if (isConnected && canTalk) {
            val toggleIntent = PendingIntent.getService(
                this,
                1,
                Intent(this, PttForegroundService::class.java).setAction(ACTION_TOGGLE_TRANSMISSION),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            builder.addAction(0, if (isPttTriggerPressed) "Berhenti" else "Bicara", toggleIntent)
        }
        return builder.build()
    }

    /* ---------------- WebSocket Networking ---------------- */

    private fun connectWebSocket(channelUrl: String, groupUid: String) {
        activeChannelUrl = channelUrl
        activeGroupUid = groupUid
        val token = AuthTokenVault.accessToken() ?: activeToken.orEmpty()
        tokenInUse = token

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
                // Reset the backoff only once the connection proved stable: a server that accepts and then
                // closes at once must not be retried every 2 s forever.
                reconnectHandler.postDelayed(resetAttemptRunnable, STABLE_CONNECTION_MS)
                isReconnecting = false
                isConnected = true
                speakerName = null
                startForegroundWithNotification(TEXT_CONNECTED)
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
                // The server ended the session; complete the close handshake so onClosed fires. A user leave
                // bumps the generation first, so this is never reached for those.
                try {
                    webSocket.close(1000, null)
                } catch (_: Exception) {}
            }

            override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
                if (generation != socketGeneration) return
                Log.i(TAG, "PTT WebSocket closed: $code / $reason")
                // A server-side close (restart, deploy) is not a user leave: keep the channel alive by
                // reconnecting like after a failure, otherwise incoming audio stays silent until the app reopens.
                PttPlatformChannelBridge.dispatchEvent("connectionStatusChanged", mapOf("status" to "RECONNECTING"))
                showReconnecting()
                scheduleReconnect()
            }

            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                if (generation != socketGeneration) return
                val respCode = response?.code ?: -1
                val respMsg = response?.message ?: "None"
                val bodyStr = try { response?.body?.string() } catch (_: Exception) { null }
                Log.e(TAG, "PTT WebSocket failure: ${t.message} | HTTP $respCode ($respMsg) | Body: $bodyStr", t)
                PttPlatformChannelBridge.dispatchEvent("connectionStatusChanged", mapOf("status" to "RECONNECTING"))
                showReconnecting()
                if (respCode == 401) {
                    // The access token expired while the socket was down. The service refreshes it itself
                    // (the vault is the only refresher), so Dart is no longer asked to.
                    onTokenRejected(token, generation)
                } else {
                    scheduleReconnect()
                }
            }
        })
    }

    private fun showReconnecting() {
        isConnected = false
        speakerName = null
        connectionText = TEXT_RECONNECTING
        refreshNotification()
    }

    private fun onTokenRejected(rejectedToken: String, generation: Int) {
        val now = SystemClock.elapsedRealtime()
        if (lastRefreshAt != 0L && now - lastRefreshAt < REFRESH_COOLDOWN_MS) {
            scheduleReconnect()
            return
        }
        lastRefreshAt = now
        refreshExecutor.execute {
            val result = AuthTokenVault.refresh(rejectedToken)
            reconnectHandler.post {
                if (generation != socketGeneration) return@post
                when (result) {
                    AuthTokenVault.RefreshResult.Rejected, AuthTokenVault.RefreshResult.NoSession -> {
                        Log.w(TAG, "PTT session ended while refreshing ($result); leaving the channel")
                        if (result == AuthTokenVault.RefreshResult.Rejected) AuthTokenChannel.notifySessionEnded()
                        PttPlatformChannelBridge.dispatchEvent(
                            "connectionStatusChanged",
                            mapOf("status" to "DISCONNECTED")
                        )
                        endChannel()
                    }
                    else -> scheduleReconnect()
                }
            }
        }
    }

    private fun scheduleReconnect() {
        if (isReconnecting) return
        val url = activeChannelUrl
        val group = activeGroupUid
        if (url.isNullOrEmpty() || group.isNullOrEmpty()) {
            return
        }

        isReconnecting = true
        reconnectHandler.removeCallbacks(resetAttemptRunnable)
        val delayMs = minOf(2000L * (1L shl minOf(reconnectAttempt, 3)), 15000L)
        reconnectAttempt++
        Log.i(TAG, "Scheduling PTT WebSocket reconnect in ${delayMs}ms (attempt #$reconnectAttempt)")
        reconnectHandler.postDelayed({
            isReconnecting = false
            Log.i(TAG, "Attempting PTT WebSocket auto-reconnect...")
            connectWebSocket(url, group)
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

                    // Lazy microphone start with dynamic FGS type update. Without the microphone type the
                    // system would hand a background recorder silence, so the turn is dropped instead.
                    isTransmitting = true
                    if (!updateForegroundServiceType(true)) {
                        isTransmitting = false
                        handlePttTriggerReleased()
                        playBonkTone()
                        vibratePattern(longArrayOf(0, 100, 50, 100))
                        PttPlatformChannelBridge.dispatchEvent(
                            "transmissionStateChanged",
                            mapOf(
                                "state" to "DENIED",
                                "requestId" to json.optString("requestId"),
                                "reason" to "MICROPHONE_UNAVAILABLE"
                            )
                        )
                        return
                    }

                    // Play Chirp & vibrate 50ms pulse
                    playChirpTone()
                    vibrateHaptic(50)

                    val requestId = json.optString("requestId").ifEmpty { lastRequestId.orEmpty() }
                    if (requestId.isNotEmpty()) transcriber?.beginTurn(requestId)
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
                    isPttTriggerPressed = false
                    refreshNotification()
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
                    isPttTriggerPressed = false
                    isTransmitting = false
                    audioEngine?.stopRecording()
                    transcriber?.endTurn()
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

                    speakerName = if (state == "IDLE") null else speakerObj?.optString("name")?.ifBlank { null } ?: "Anggota grup"
                    refreshNotification()

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
        lastRequestId = requestId
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
        refreshNotification()
    }

    private fun handlePttTriggerReleased() {
        isPttTriggerPressed = false
        isTransmitting = false
        audioEngine?.stopRecording()
        transcriber?.endTurn()
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
        refreshExecutor.shutdown()
        audioEngine?.stopRecording()
        transcriber?.release()
        audioEngine?.stopPlayback()
        soundPool?.release()
        mediaSession?.release()
        try {
            unregisterReceiver(oemKeyReceiver)
        } catch (_: Exception) {}
        wakeLockHandler.removeCallbacks(renewWakeLock)
        wakeLock?.let {
            if (it.isHeld) it.release()
        }
        wifiLock?.let {
            if (it.isHeld) it.release()
        }
    }
}
