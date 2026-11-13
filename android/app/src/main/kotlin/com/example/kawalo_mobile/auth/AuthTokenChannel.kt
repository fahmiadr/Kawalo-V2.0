package com.example.kawalo_mobile.auth

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/** Dart side of [AuthTokenVault] (`kawalo/auth_tokens`). Calls run off the main thread: a refresh blocks. */
object AuthTokenChannel : MethodChannel.MethodCallHandler {
    private const val NAME = "kawalo/auth_tokens"

    // Not single-threaded: reads must not queue behind a refresh that waits on the network.
    private val executor = Executors.newCachedThreadPool()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var channel: MethodChannel? = null
    private var boundMessenger: BinaryMessenger? = null

    fun init(context: Context, messenger: BinaryMessenger) {
        AuthTokenVault.init(context)
        if (messenger === boundMessenger) return
        boundMessenger = messenger
        channel = MethodChannel(messenger, NAME).apply { setMethodCallHandler(this@AuthTokenChannel) }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        executor.execute {
            try {
                val reply: Any? = when (call.method) {
                    "read" -> mapOf(
                        "accessToken" to AuthTokenVault.accessToken(),
                        "refreshToken" to AuthTokenVault.refreshToken(),
                    )
                    "save" -> AuthTokenVault.save(call.argument("accessToken"), call.argument("refreshToken"))
                    "clear" -> AuthTokenVault.clear()
                    "configure" -> AuthTokenVault.setBaseUrl(call.argument<String>("baseUrl").orEmpty())
                    "refresh" -> toMap(AuthTokenVault.refresh(call.argument("staleAccessToken")))
                    else -> {
                        mainHandler.post { result.notImplemented() }
                        return@execute
                    }
                }
                mainHandler.post { result.success(reply) }
            } catch (e: Exception) {
                mainHandler.post { result.error("TOKEN_VAULT", e.message, null) }
            }
        }
    }

    /** Tells a live Dart side that a refresh started by the PTT service was refused, so it shows login. */
    fun notifySessionEnded() {
        mainHandler.post { channel?.invokeMethod("sessionEnded", null) }
    }

    private fun toMap(result: AuthTokenVault.RefreshResult): Map<String, Any?> = when (result) {
        is AuthTokenVault.RefreshResult.Ok -> mapOf(
            "status" to "ok",
            "accessToken" to result.accessToken,
            "refreshToken" to result.refreshToken,
        )
        AuthTokenVault.RefreshResult.Rejected -> mapOf("status" to "rejected")
        AuthTokenVault.RefreshResult.Unavailable -> mapOf("status" to "unavailable")
        AuthTokenVault.RefreshResult.NoSession -> mapOf("status" to "noSession")
    }
}
