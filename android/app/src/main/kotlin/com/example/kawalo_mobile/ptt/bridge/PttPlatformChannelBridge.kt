package com.example.kawalo_mobile.ptt.bridge

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import com.example.kawalo_mobile.MainActivity
import com.example.kawalo_mobile.ptt.PttForegroundService
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.lang.ref.WeakReference
import java.util.concurrent.CopyOnWriteArraySet

object PttPlatformChannelBridge : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private const val CONTROL_CHANNEL = "kawalo/ptt_control"
    private const val EVENTS_CHANNEL = "kawalo/ptt_events"

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private val eventSinks = CopyOnWriteArraySet<EventChannel.EventSink>()
    private val mainHandler = Handler(Looper.getMainLooper())

    private var appContext: Context? = null
    private var activityRef: WeakReference<MainActivity>? = null

    fun init(activity: MainActivity, flutterEngine: FlutterEngine) {
        activityRef = WeakReference(activity)
        appContext = activity.applicationContext
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        methodChannel = MethodChannel(messenger, CONTROL_CHANNEL).apply {
            setMethodCallHandler(this@PttPlatformChannelBridge)
        }

        eventChannel = EventChannel(messenger, EVENTS_CHANNEL).apply {
            setStreamHandler(this@PttPlatformChannelBridge)
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val ctx = appContext ?: run {
            result.error("UNINITIALIZED", "Bridge context not initialized", null)
            return
        }

        when (call.method) {
            "joinChannel" -> {
                val channelUrl = call.argument<String>("channelUrl")
                val groupUid = call.argument<String>("groupUid")
                val token = call.argument<String>("token")

                if (channelUrl.isNullOrEmpty() || groupUid.isNullOrEmpty() || token.isNullOrEmpty()) {
                    result.error("INVALID_ARGS", "channelUrl, groupUid, and token are required", null)
                    return
                }

                val intent = Intent(ctx, PttForegroundService::class.java).apply {
                    action = PttForegroundService.ACTION_JOIN_CHANNEL
                    putExtra(PttForegroundService.EXTRA_CHANNEL_URL, channelUrl)
                    putExtra(PttForegroundService.EXTRA_GROUP_UID, groupUid)
                    putExtra(PttForegroundService.EXTRA_TOKEN, token)
                }
                ctx.startForegroundService(intent)
                result.success(true)
            }

            "leaveChannel" -> {
                val intent = Intent(ctx, PttForegroundService::class.java).apply {
                    action = PttForegroundService.ACTION_LEAVE_CHANNEL
                }
                ctx.startService(intent)
                result.success(true)
            }

            "startTransmission" -> {
                val requestId = call.argument<String>("requestId") ?: "req_${System.currentTimeMillis()}"
                val intent = Intent(ctx, PttForegroundService::class.java).apply {
                    action = PttForegroundService.ACTION_START_TRANSMISSION
                    putExtra(PttForegroundService.EXTRA_REQUEST_ID, requestId)
                }
                ctx.startService(intent)
                result.success(true)
            }

            "stopTransmission" -> {
                val intent = Intent(ctx, PttForegroundService::class.java).apply {
                    action = PttForegroundService.ACTION_STOP_TRANSMISSION
                }
                ctx.startService(intent)
                result.success(true)
            }

            "updateAuthToken" -> {
                val token = call.argument<String>("token")
                if (!token.isNullOrEmpty()) {
                    val intent = Intent(ctx, PttForegroundService::class.java).apply {
                        action = PttForegroundService.ACTION_UPDATE_AUTH_TOKEN
                        putExtra(PttForegroundService.EXTRA_TOKEN, token)
                    }
                    ctx.startService(intent)
                    result.success(true)
                } else {
                    result.error("INVALID_TOKEN", "Token cannot be empty", null)
                }
            }

            "hasRecordAudioPermission" -> {
                val hasPerm = ContextCompat.checkSelfPermission(
                    ctx,
                    Manifest.permission.RECORD_AUDIO
                ) == PackageManager.PERMISSION_GRANTED
                result.success(hasPerm)
            }

            "requestRecordAudioPermission" -> {
                val act = activityRef?.get()
                if (act != null) {
                    act.requestRecordAudioPermission(result)
                } else {
                    val hasPerm = ContextCompat.checkSelfPermission(
                        ctx,
                        Manifest.permission.RECORD_AUDIO
                    ) == PackageManager.PERMISSION_GRANTED
                    result.success(hasPerm)
                }
            }

            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        if (events != null) {
            eventSinks.add(events)
        }
    }

    override fun onCancel(arguments: Any?) {
        eventSinks.clear()
    }

    /* ---------------- Event Dispatchers to Flutter ---------------- */

    fun dispatchEvent(eventType: String, data: Map<String, Any?>) {
        val payload = mapOf(
            "event" to eventType,
            "data" to data
        )
        mainHandler.post {
            val iterator = eventSinks.iterator()
            while (iterator.hasNext()) {
                val sink = iterator.next()
                try {
                    sink.success(payload)
                } catch (e: Exception) {
                    android.util.Log.w("PttBridge", "Failed to dispatch event to sink: ${e.message}")
                    eventSinks.remove(sink)
                }
            }
        }
    }
}
