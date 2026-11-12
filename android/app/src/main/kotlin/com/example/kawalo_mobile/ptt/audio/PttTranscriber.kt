package com.example.kawalo_mobile.ptt.audio

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.speech.RecognitionListener
import android.speech.RecognitionSupport
import android.speech.RecognitionSupportCallback
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.core.content.ContextCompat

/**
 * Transcribes the local speaker's own PTT turns with the OS speech recognizer (Android 13+ only).
 *
 * The microphone stays with [PttAudioEngine]: its frames are copied into a per-turn memory buffer and, once the
 * floor is released, replayed into the recognizer through `EXTRA_AUDIO_SOURCE` (a pipe). The recognizer therefore
 * never competes with the live `AudioRecord`. Every turn yields exactly one report (`ok`, `failed` or
 * `unsupported`) through [report]; Dart uploads it, and the server worker transcribes turns reported as
 * `failed`/`unsupported` (or never reported, e.g. when no Flutter engine is listening).
 *
 * Threading: [onPcmFrame] runs on the audio thread and only copies bytes; [beginTurn]/[endTurn] may run on any
 * thread; everything touching [SpeechRecognizer] runs on the main thread. No exception may escape this class:
 * live audio, floor handling and the service lifecycle must not depend on it.
 */
class PttTranscriber(
    private val context: Context,
    // Lets the "recognizer opened the mic itself" check ignore our own AudioRecord of a newer turn.
    private val isOwnMicActive: () -> Boolean,
    private val report: (Map<String, Any?>) -> Unit,
) {
    companion object {
        private const val TAG = "PttTranscriber"

        /**
         * Decision T1 (12 Nov 2026): transcription priority is 1) the on-device `id-ID` model, 2) the OS default
         * recognizer, which on most phones is Google's and sends the audio to Google's servers, 3) the server
         * worker, which takes every turn reported `failed`/`unsupported`. Set to false to keep audio on the
         * phone: devices without the on-device model then report `unsupported` straight to the server worker.
         */
        const val ALLOW_CLOUD_FALLBACK = true

        const val LOCALE = "id-ID"

        // 30 s of 16 kHz mono PCM16, the server's turn limit; frames past it are dropped.
        private const val MAX_TURN_BYTES = PttAudioEngine.SAMPLE_RATE * 2 * 30
        // Shorter turns hold no words worth a recognizer session; the server judges them (no_speech).
        private const val MIN_TURN_BYTES = PttAudioEngine.SAMPLE_RATE * 2 / 2
        private const val MAX_PENDING_JOBS = 3

        // Results must arrive this long after the pipe is closed (end of audio).
        private const val RESULT_TIMEOUT_MS = 15_000L
        // Before the pipe closes: support check plus feeding, which may be no faster than real time.
        private const val FEED_SLACK_MS = 15_000L
    }

    private class Turn(val requestId: String, val buffer: PttTurnBuffer?, val unsupportedReason: String?)

    private class Job(val requestId: String, val pcm: ByteArray) {
        val durationMs: Long get() = pcm.size * 1000L / (PttAudioEngine.SAMPLE_RATE * 2)
    }

    private class Session(val job: Job) {
        var recognizer: SpeechRecognizer? = null
        var engine = "on_device"
        var readEnd: ParcelFileDescriptor? = null
        var writeEnd: ParcelFileDescriptor? = null
        val segments = mutableListOf<String>()
        var baselineRecordings = 0
        var micGrowthSeen = false
        lateinit var timeout: Runnable
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

    @Volatile private var currentTurn: Turn? = null

    // Main thread only.
    private val pending = ArrayDeque<Job>()
    private var session: Session? = null
    private var released = false
    private var modelDownloadRequested = false

    fun beginTurn(requestId: String) {
        try {
            val unsupportedReason = when {
                Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU -> "sdk_${Build.VERSION.SDK_INT}_below_33"
                ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) !=
                    PackageManager.PERMISSION_GRANTED -> "record_audio_not_granted"
                else -> null
            }
            val buffer = if (unsupportedReason == null) PttTurnBuffer(MAX_TURN_BYTES) else null
            val previous = synchronized(this) {
                currentTurn.also { currentTurn = Turn(requestId, buffer, unsupportedReason) }
            }
            // A turn whose end was never signalled still deserves its report.
            if (previous != null) finishTurn(previous)
        } catch (t: Throwable) {
            Log.w(TAG, "beginTurn failed: ${t.message}")
        }
    }

    /** Audio thread: one array copy, no locks, no allocation. */
    fun onPcmFrame(frame: ByteArray, count: Int) {
        try {
            currentTurn?.buffer?.append(frame, count)
        } catch (_: Throwable) {
        }
    }

    fun endTurn() {
        try {
            val turn = synchronized(this) { currentTurn.also { currentTurn = null } } ?: return
            finishTurn(turn)
        } catch (t: Throwable) {
            Log.w(TAG, "endTurn failed: ${t.message}")
        }
    }

    fun release() {
        mainHandler.post {
            released = true
            session?.let { cleanup(it) }
            session = null
            pending.clear()
        }
    }

    private fun finishTurn(turn: Turn) {
        val buffer = turn.buffer
        if (buffer == null) {
            emit(turn.requestId, PttTranscriptPolicy.STATUS_UNSUPPORTED, null, turn.unsupportedReason)
            return
        }
        val length = buffer.seal()
        if (length < MIN_TURN_BYTES) {
            emit(turn.requestId, PttTranscriptPolicy.STATUS_FAILED, null, "too_short_${length}b")
            return
        }
        val job = Job(turn.requestId, buffer.copy(length))
        mainHandler.post { enqueue(job) }
    }

    /* ---------------- Main thread ---------------- */

    private fun enqueue(job: Job) {
        if (released) return
        PttTranscriptPolicy.enqueueBounded(pending, job, MAX_PENDING_JOBS)?.let {
            emit(it.requestId, PttTranscriptPolicy.STATUS_FAILED, null, "queue_overflow")
        }
        startNext()
    }

    private fun startNext() {
        while (session == null && !released) {
            val job = pending.removeFirstOrNull() ?: return
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
                emit(job.requestId, PttTranscriptPolicy.STATUS_UNSUPPORTED, null, "sdk_below_33")
                continue
            }
            val s = Session(job)
            session = s
            try {
                startSession(s)
            } catch (t: Throwable) {
                finish(s, PttTranscriptPolicy.STATUS_FAILED, null, "start_error_${t.javaClass.simpleName}")
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.TIRAMISU)
    private fun startSession(s: Session) {
        s.timeout = Runnable { finishWithCollected(s, "timeout") }
        mainHandler.postDelayed(s.timeout, s.job.durationMs + FEED_SLACK_MS)

        if (!SpeechRecognizer.isOnDeviceRecognitionAvailable(context)) {
            fallbackOrUnsupported(s, "no_on_device_recognizer")
            return
        }
        val recognizer = SpeechRecognizer.createOnDeviceSpeechRecognizer(context)
        s.recognizer = recognizer
        recognizer.checkRecognitionSupport(
            languageIntent(),
            context.mainExecutor,
            object : RecognitionSupportCallback {
                override fun onSupportResult(support: RecognitionSupport) {
                    if (s !== session) return
                    try {
                        if (support.installedOnDeviceLanguages.any(PttTranscriptPolicy::isIndonesian)) {
                            listen(s)
                        } else {
                            val supported = support.supportedOnDeviceLanguages.any(PttTranscriptPolicy::isIndonesian)
                            if (supported) requestModelDownload(s)
                            fallbackOrUnsupported(s, if (supported) "id_model_not_installed" else "id_not_supported_on_device")
                        }
                    } catch (t: Throwable) {
                        finish(s, PttTranscriptPolicy.STATUS_FAILED, null, "support_result_${t.javaClass.simpleName}")
                    }
                }

                override fun onError(error: Int) {
                    if (s !== session) return
                    try {
                        fallbackOrUnsupported(s, "support_check_${PttTranscriptPolicy.errorName(error)}")
                    } catch (t: Throwable) {
                        finish(s, PttTranscriptPolicy.STATUS_FAILED, null, "support_error_${t.javaClass.simpleName}")
                    }
                }
            },
        )
    }

    // Asks the recognizer service to fetch the missing id-ID model so later turns are transcribed on the phone
    // instead of by the slower server worker. Only the model comes down; no audio leaves the device. Requested
    // once per process: the service owns the download, repeating it every turn would only add noise.
    @RequiresApi(Build.VERSION_CODES.TIRAMISU)
    private fun requestModelDownload(s: Session) {
        if (modelDownloadRequested) return
        modelDownloadRequested = true
        try {
            s.recognizer?.triggerModelDownload(languageIntent())
            Log.i(TAG, "Requested the on-device $LOCALE model download")
        } catch (t: Throwable) {
            Log.w(TAG, "triggerModelDownload failed: ${t.javaClass.simpleName} ${t.message}")
        }
    }

    @RequiresApi(Build.VERSION_CODES.TIRAMISU)
    private fun fallbackOrUnsupported(s: Session, reason: String) {
        if (!ALLOW_CLOUD_FALLBACK || !SpeechRecognizer.isRecognitionAvailable(context)) {
            finish(s, PttTranscriptPolicy.STATUS_UNSUPPORTED, null, reason)
            return
        }
        Log.i(TAG, "Falling back to the default recognizer: $reason")
        s.recognizer?.destroy()
        s.recognizer = SpeechRecognizer.createSpeechRecognizer(context)
        s.engine = "default"
        listen(s)
    }

    @RequiresApi(Build.VERSION_CODES.TIRAMISU)
    private fun listen(s: Session) {
        val recognizer = s.recognizer ?: return
        val pipe = ParcelFileDescriptor.createPipe()
        s.readEnd = pipe[0]
        s.writeEnd = pipe[1]
        s.baselineRecordings = activeRecordings()

        recognizer.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) = checkMic(s, "ready")
            override fun onBeginningOfSpeech() = checkMic(s, "speech")
            override fun onRmsChanged(rmsdB: Float) {}
            override fun onBufferReceived(buffer: ByteArray?) {}
            override fun onEndOfSpeech() {}
            override fun onPartialResults(partialResults: Bundle?) {}
            override fun onEvent(eventType: Int, params: Bundle?) {}

            // Segmented sessions deliver each utterance here; the plain one only through onResults.
            override fun onSegmentResults(segmentResults: Bundle) {
                if (s !== session) return
                bestHypothesis(segmentResults)?.let { s.segments.add(it) }
            }

            override fun onEndOfSegmentedSession() {
                if (s === session) finishWithCollected(s, "segmented_end")
            }

            override fun onResults(results: Bundle?) {
                if (s !== session) return
                bestHypothesis(results)?.let { s.segments.add(it) }
                finishWithCollected(s, "results")
            }

            override fun onError(error: Int) {
                if (s !== session) return
                if (s.segments.isNotEmpty()) {
                    finishWithCollected(s, "error_after_segments_${PttTranscriptPolicy.errorName(error)}")
                } else {
                    finish(s, PttTranscriptPolicy.statusForError(error), null, "${s.engine}_${PttTranscriptPolicy.errorName(error)}")
                }
            }
        })

        val intent = languageIntent().apply {
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, false)
            putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, s.engine == "on_device")
            putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE, pipe[0])
            putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE_ENCODING, AudioFormat.ENCODING_PCM_16BIT)
            putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE_SAMPLING_RATE, PttAudioEngine.SAMPLE_RATE)
            putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE_CHANNEL_COUNT, 1)
            // PTT speech pauses mid-turn. A plain session stops at the first end of speech and drops the rest;
            // a session segmented by the audio source runs until the pipe is closed.
            putExtra(RecognizerIntent.EXTRA_SEGMENTED_SESSION, RecognizerIntent.EXTRA_AUDIO_SOURCE)
        }
        recognizer.startListening(intent)
        feed(s)
    }

    // Writes may block until the recognizer reads; closing the write end on cleanup unblocks them.
    private fun feed(s: Session) {
        val writeEnd = s.writeEnd ?: return
        val pcm = s.job.pcm
        Thread({
            var error: String? = null
            try {
                // Closing the stream closes the pipe, which is the recognizer's end-of-audio signal.
                ParcelFileDescriptor.AutoCloseOutputStream(writeEnd).use { out ->
                    var offset = 0
                    while (offset < pcm.size) {
                        val n = minOf(PttAudioEngine.BYTES_PER_FRAME * 50, pcm.size - offset)
                        out.write(pcm, offset, n)
                        offset += n
                    }
                }
            } catch (t: Throwable) {
                error = t.javaClass.simpleName
            }
            mainHandler.post {
                if (s !== session) return@post
                if (error != null) Log.w(TAG, "Pipe feed for ${s.job.requestId} stopped early: $error")
                s.writeEnd = null
                mainHandler.removeCallbacks(s.timeout)
                mainHandler.postDelayed(s.timeout, RESULT_TIMEOUT_MS)
            }
        }, "PttTranscriberFeed").apply {
            isDaemon = true
            start()
        }
    }

    private fun bestHypothesis(bundle: Bundle?): String? =
        bundle?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
            ?.firstOrNull()
            ?.trim()
            ?.takeIf { it.isNotEmpty() }

    private fun finishWithCollected(s: Session, why: String) {
        val text = s.segments.joinToString(" ").trim()
        if (text.isEmpty()) {
            finish(s, PttTranscriptPolicy.STATUS_FAILED, null, "${s.engine}_${why}_empty")
        } else {
            finish(s, PttTranscriptPolicy.STATUS_OK, text, "${s.engine}_$why")
        }
    }

    private fun finish(s: Session, status: String, text: String?, reason: String) {
        if (s !== session) return
        checkMic(s, "finish")
        val fullReason = if (s.micGrowthSeen) "${reason}_mic_opened_by_service" else reason
        cleanup(s)
        session = null
        emit(s.job.requestId, status, text, fullReason)
        startNext()
    }

    private fun cleanup(s: Session) {
        try { mainHandler.removeCallbacks(s.timeout) } catch (_: Throwable) {}
        try { s.recognizer?.cancel() } catch (_: Throwable) {}
        try { s.recognizer?.destroy() } catch (_: Throwable) {}
        s.recognizer = null
        try { s.writeEnd?.close() } catch (_: Throwable) {}
        try { s.readEnd?.close() } catch (_: Throwable) {}
        s.writeEnd = null
        s.readEnd = null
    }

    // Spike check: a service that ignores EXTRA_AUDIO_SOURCE opens the mic itself, which shows up as an extra
    // active recording. Logged only; the transcript still counts.
    private fun checkMic(s: Session, stage: String) {
        if (s.micGrowthSeen || s !== session) return
        val now = activeRecordings()
        if (now > s.baselineRecordings && !isOwnMicActive()) {
            s.micGrowthSeen = true
            Log.w(TAG, "Recognizer seems to record from the mic ($stage: $now > ${s.baselineRecordings}) for ${s.job.requestId}")
        }
    }

    private fun activeRecordings(): Int =
        try { audioManager.activeRecordingConfigurations.size } catch (_: Throwable) { 0 }

    private fun languageIntent() = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
        putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
        putExtra(RecognizerIntent.EXTRA_LANGUAGE, LOCALE)
        putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE, LOCALE)
    }

    private fun emit(requestId: String, status: String, text: String?, reason: String?) {
        Log.i(TAG, "Transcript $requestId: $status ($reason)")
        try {
            report(
                mapOf(
                    "requestId" to requestId,
                    "status" to status,
                    "text" to text,
                    "locale" to if (status == PttTranscriptPolicy.STATUS_OK) LOCALE else null,
                    // For logs only, never shown to users.
                    "reason" to reason,
                ),
            )
        } catch (t: Throwable) {
            Log.w(TAG, "Transcript report failed: ${t.message}")
        }
    }
}

/** Fixed-size PCM buffer for one turn. */
internal class PttTurnBuffer(capacityBytes: Int) {
    private val data = ByteArray(capacityBytes)
    @Volatile private var length = 0
    @Volatile private var sealed = false

    // Single writer (the audio thread). length moves only after the copy, so a reader that snapshots it via
    // seal() never sees a torn frame; a frame racing seal() is simply lost.
    fun append(src: ByteArray, count: Int) {
        if (sealed) return
        val n = minOf(count, data.size - length)
        if (n <= 0) return
        System.arraycopy(src, 0, data, length, n)
        length += n
    }

    fun seal(): Int {
        sealed = true
        return length
    }

    fun copy(length: Int): ByteArray = data.copyOf(length)
}

/** Pure decisions, kept apart so they stay easy to reason about without a device. */
internal object PttTranscriptPolicy {
    const val STATUS_OK = "ok"
    const val STATUS_FAILED = "failed"
    const val STATUS_UNSUPPORTED = "unsupported"

    // Both statuses make the server worker transcribe the turn; the split only tells "this device cannot" from
    // "this device tried". No match / speech timeout count as failed so the worker still gets a try.
    fun statusForError(error: Int): String = when (error) {
        SpeechRecognizer.ERROR_LANGUAGE_NOT_SUPPORTED,
        SpeechRecognizer.ERROR_LANGUAGE_UNAVAILABLE,
        SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS,
        SpeechRecognizer.ERROR_CANNOT_CHECK_SUPPORT -> STATUS_UNSUPPORTED
        else -> STATUS_FAILED
    }

    fun errorName(error: Int): String = when (error) {
        SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "network_timeout"
        SpeechRecognizer.ERROR_NETWORK -> "network"
        SpeechRecognizer.ERROR_AUDIO -> "audio"
        SpeechRecognizer.ERROR_SERVER -> "server"
        SpeechRecognizer.ERROR_CLIENT -> "client"
        SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "speech_timeout"
        SpeechRecognizer.ERROR_NO_MATCH -> "no_match"
        SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "busy"
        SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "insufficient_permissions"
        SpeechRecognizer.ERROR_TOO_MANY_REQUESTS -> "too_many_requests"
        SpeechRecognizer.ERROR_SERVER_DISCONNECTED -> "server_disconnected"
        SpeechRecognizer.ERROR_LANGUAGE_NOT_SUPPORTED -> "language_not_supported"
        SpeechRecognizer.ERROR_LANGUAGE_UNAVAILABLE -> "language_unavailable"
        SpeechRecognizer.ERROR_CANNOT_CHECK_SUPPORT -> "cannot_check_support"
        else -> "error_$error"
    }

    // Java's Locale still maps Indonesian to the legacy code "in", so accept both.
    fun isIndonesian(tag: String): Boolean =
        tag.substringBefore('-').substringBefore('_').lowercase() in setOf("id", "in")

    /** Appends [item]; when the queue is over [cap], removes and returns the oldest entry. */
    fun <T> enqueueBounded(queue: ArrayDeque<T>, item: T, cap: Int): T? {
        queue.addLast(item)
        return if (queue.size > cap) queue.removeFirst() else null
    }
}
