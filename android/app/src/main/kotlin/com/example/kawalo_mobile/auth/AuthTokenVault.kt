package com.example.kawalo_mobile.auth

import android.content.Context
import android.content.SharedPreferences
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.io.IOException
import java.security.KeyStore
import java.util.concurrent.TimeUnit
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * Single owner of the access/refresh token pair on Android (since 13 Nov 2026).
 *
 * Dart reads and writes the pair through [AuthTokenChannel] and the PTT service uses it directly, so the
 * service can refresh and reconnect after the Dart side died. The server rotates refresh tokens and revokes
 * the whole family when an already-rotated token is sent again, so every refresh on the device goes through
 * [refresh], serialized by one lock, and always sends the refresh token that is stored at that moment.
 *
 * Values are AES-GCM encrypted with a non-exportable Android Keystore key (no user-authentication
 * requirement, so the service can read them while the screen is locked).
 */
object AuthTokenVault {
    sealed interface RefreshResult {
        data class Ok(val accessToken: String, val refreshToken: String) : RefreshResult

        /** The server refused the refresh token: the session is over and the pair was cleared. */
        data object Rejected : RefreshResult

        /** Offline, timeout, 429/5xx or no base URL yet: keep the pair and try again later. */
        data object Unavailable : RefreshResult

        /** Nothing to refresh (logged out). */
        data object NoSession : RefreshResult
    }

    private const val PREFS = "kawalo_auth_tokens"
    private const val KEY_ALIAS = "kawalo_auth_tokens_key"
    private const val ACCESS = "access"
    private const val REFRESH = "refresh"
    private const val BASE_URL = "base_url"
    private const val GCM_IV_BYTES = 12

    private lateinit var prefs: SharedPreferences
    private val storeLock = Any()
    private val refreshLock = Any()

    private val http by lazy {
        OkHttpClient.Builder()
            .connectTimeout(10, TimeUnit.SECONDS)
            .readTimeout(10, TimeUnit.SECONDS)
            .callTimeout(15, TimeUnit.SECONDS)
            .build()
    }

    fun init(context: Context) = synchronized(storeLock) {
        if (!::prefs.isInitialized) {
            prefs = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        }
    }

    fun accessToken(): String? = synchronized(storeLock) { read(ACCESS) }

    fun refreshToken(): String? = synchronized(storeLock) { read(REFRESH) }

    /** A null field is left as it is. Throws when the Keystore cannot encrypt. */
    fun save(accessToken: String?, refreshToken: String?) = synchronized(storeLock) {
        val editor = prefs.edit()
        accessToken?.let { editor.putString(ACCESS, encrypt(it)) }
        refreshToken?.let { editor.putString(REFRESH, encrypt(it)) }
        editor.commit()
    }

    fun clear() = synchronized(storeLock) {
        prefs.edit().remove(ACCESS).remove(REFRESH).commit()
    }

    /** The API base URL ending in `/api`, stored so a service restarted without Dart can refresh. */
    fun setBaseUrl(baseUrl: String) = synchronized(storeLock) {
        prefs.edit().putString(BASE_URL, baseUrl).commit()
    }

    /**
     * Blocking; never call it on the main thread. [staleAccessToken] is the token the caller found expired or
     * rejected: when the stored one differs, someone else already refreshed and the stored pair is returned
     * without contacting the server.
     */
    fun refresh(staleAccessToken: String?): RefreshResult = synchronized(refreshLock) {
        val (access, refresh, baseUrl) = synchronized(storeLock) {
            Triple(read(ACCESS), read(REFRESH), prefs.getString(BASE_URL, null))
        }
        if (refresh.isNullOrEmpty()) return RefreshResult.NoSession
        if (access != null && access != staleAccessToken) return RefreshResult.Ok(access, refresh)
        if (baseUrl.isNullOrEmpty()) return RefreshResult.Unavailable

        val result = post(baseUrl, refresh)
        synchronized(storeLock) {
            // A logout or a new login while the request was in flight wins over this result.
            if (read(REFRESH) != refresh) {
                val current = read(REFRESH) ?: return RefreshResult.NoSession
                val currentAccess = read(ACCESS) ?: return RefreshResult.Unavailable
                return RefreshResult.Ok(currentAccess, current)
            }
            when (result) {
                is RefreshResult.Ok -> save(result.accessToken, result.refreshToken)
                RefreshResult.Rejected -> clear()
                else -> {}
            }
        }
        return result
    }

    private fun post(baseUrl: String, refreshToken: String): RefreshResult {
        val body = JSONObject().put("refresh_token", refreshToken).toString()
            .toRequestBody("application/json".toMediaType())
        val request = Request.Builder()
            .url(baseUrl.trimEnd('/') + "/v1/auth/refresh")
            .header("Accept", "application/json")
            .post(body)
            .build()
        return try {
            http.newCall(request).execute().use { response ->
                val json = response.body?.string()?.let { runCatching { JSONObject(it) }.getOrNull() }
                // Same rule as the Dart refresher: 400/401/403 or success=false ends the session; anything else
                // (429 "already refreshing", 5xx) is retried later.
                when {
                    response.code == 400 || response.code == 401 || response.code == 403 -> RefreshResult.Rejected
                    !response.isSuccessful -> RefreshResult.Unavailable
                    json?.optBoolean("success", true) == false -> RefreshResult.Rejected
                    else -> {
                        val data = json?.optJSONObject("data")
                        val access = data?.optString("access_token").orEmpty()
                        val refresh = data?.optString("refresh_token").orEmpty()
                        if (access.isEmpty() || refresh.isEmpty()) {
                            RefreshResult.Unavailable
                        } else {
                            RefreshResult.Ok(access, refresh)
                        }
                    }
                }
            }
        } catch (_: IOException) {
            RefreshResult.Unavailable
        }
    }

    /* ---------------- Keystore encryption ---------------- */

    private fun read(name: String): String? {
        val stored = prefs.getString(name, null) ?: return null
        return try {
            decrypt(stored)
        } catch (_: Exception) {
            // Key lost (e.g. restored to another device): the value is useless, the user logs in again.
            null
        }
    }

    private fun key(): SecretKey {
        val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (keyStore.getEntry(KEY_ALIAS, null) as? KeyStore.SecretKeyEntry)?.let { return it.secretKey }
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(
            KeyGenParameterSpec.Builder(KEY_ALIAS, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build()
        )
        return generator.generateKey()
    }

    private fun encrypt(plain: String): String {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, key())
        val sealed = cipher.iv + cipher.doFinal(plain.toByteArray(Charsets.UTF_8))
        return Base64.encodeToString(sealed, Base64.NO_WRAP)
    }

    private fun decrypt(stored: String): String {
        val sealed = Base64.decode(stored, Base64.NO_WRAP)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(128, sealed, 0, GCM_IV_BYTES))
        return String(cipher.doFinal(sealed, GCM_IV_BYTES, sealed.size - GCM_IV_BYTES), Charsets.UTF_8)
    }
}
