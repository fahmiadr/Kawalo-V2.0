package com.example.kawalo_mobile.ptt.audio

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.MediaRecorder
import android.util.Log
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.atomic.AtomicBoolean

class PttAudioEngine(private val context: Context) {
    companion object {
        private const val TAG = "PttAudioEngine"
        const val SAMPLE_RATE = 16000
        const val CHANNEL_IN = AudioFormat.CHANNEL_IN_MONO
        const val CHANNEL_OUT = AudioFormat.CHANNEL_OUT_MONO
        const val ENCODING = AudioFormat.ENCODING_PCM_16BIT
        const val FRAME_DURATION_MS = 20
        const val SAMPLES_PER_FRAME = SAMPLE_RATE * FRAME_DURATION_MS / 1000 // 320 samples
        const val BYTES_PER_FRAME = SAMPLES_PER_FRAME * 2 // 640 bytes PCM

        private val isOpusAvailable: Boolean by lazy {
            try {
                Class.forName("io.github.thewh1teagle.opus.Opus")
                true
            } catch (_: Exception) {
                false
            }
        }
    }

    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private var audioRecord: AudioRecord? = null
    private var audioTrack: AudioTrack? = null
    private var recordingThread: Thread? = null
    private var playbackThread: Thread? = null

    private val isRecording = AtomicBoolean(false)
    private val isPlaying = AtomicBoolean(false)

    val jitterBuffer = PttJitterBuffer()

    // Callback for outbound 7-byte framed binary audio packets
    var onAudioPacketReady: ((ByteArray) -> Unit)? = null

    private var sequenceNumber = 0
    private var burstStartTimeMs = 0L

    init {
        setupAudioRouting()
    }

    fun setupAudioRouting() {
        try {
            audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
            if (!audioManager.isWiredHeadsetOn && !audioManager.isBluetoothScoOn) {
                audioManager.isSpeakerphoneOn = true
            }
            Log.d(TAG, "setupAudioRouting: mode=${audioManager.mode}, speakerphone=${audioManager.isSpeakerphoneOn}")
        } catch (e: Exception) {
            Log.w(TAG, "Failed to configure audio routing: ${e.message}")
        }
    }

    /**
     * Start playing incoming audio from the jitter buffer.
     * Complies with API 34 Foreground Service mediaPlayback type.
     */
    @Synchronized
    fun startPlayback() {
        if (isPlaying.get()) return

        setupAudioRouting()
        val minBufferSize = AudioTrack.getMinBufferSize(SAMPLE_RATE, CHANNEL_OUT, ENCODING)
        val bufferSize = maxOf(minBufferSize, BYTES_PER_FRAME * 4)

        val audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
            .build()

        val audioFormat = AudioFormat.Builder()
            .setSampleRate(SAMPLE_RATE)
            .setChannelMask(CHANNEL_OUT)
            .setEncoding(ENCODING)
            .build()

        val track = AudioTrack(
            audioAttributes,
            audioFormat,
            bufferSize,
            AudioTrack.MODE_STREAM,
            AudioManager.AUDIO_SESSION_ID_GENERATE
        )

        if (track.state != AudioTrack.STATE_INITIALIZED) {
            Log.e(TAG, "AudioTrack initialization failed! state=${track.state}")
            try { track.release() } catch (_: Exception) {}
            return
        }

        audioTrack = track
        audioTrack?.play()
        isPlaying.set(true)
        Log.i(TAG, "AudioTrack started playback successfully (bufferSize=$bufferSize)")

        playbackThread = Thread({
            android.os.Process.setThreadPriority(android.os.Process.THREAD_PRIORITY_URGENT_AUDIO)
            var playedFrames = 0
            while (isPlaying.get()) {
                val opusPayload = jitterBuffer.pollFrame()
                if (opusPayload != null) {
                    // Decode Opus frame to 16kHz PCM (or passthrough)
                    val pcmData = decodeOpusToPcm(opusPayload)
                    audioTrack?.write(pcmData, 0, pcmData.size)
                    playedFrames++
                    if (playedFrames % 50 == 1) {
                        Log.d(TAG, "AudioTrack playing frames (count=$playedFrames, bytes=${pcmData.size})")
                    }
                } else {
                    try {
                        Thread.sleep(5)
                    } catch (_: InterruptedException) {
                        break
                    }
                }
            }
        }, "PttAudioPlaybackThread").apply { start() }
    }

    @Synchronized
    fun stopPlayback() {
        isPlaying.set(false)
        playbackThread?.interrupt()
        playbackThread = null

        try {
            audioTrack?.stop()
            audioTrack?.release()
        } catch (e: Exception) {
            Log.w(TAG, "Error stopping audioTrack: ${e.message}")
        }
        audioTrack = null
        jitterBuffer.flush()
    }

    /**
     * Lazy Microphone Acquisition (Android 14 API 34 Compliant).
     * AudioRecord is instantiated and started ONLY when floor is granted.
     */
    @Synchronized
    fun startRecording() {
        if (isRecording.get()) return

        setupAudioRouting()
        sequenceNumber = 0
        burstStartTimeMs = System.currentTimeMillis()

        val minBufferSize = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_IN, ENCODING)
        val bufferSize = maxOf(minBufferSize, BYTES_PER_FRAME * 4)

        try {
            var record: AudioRecord? = null
            try {
                record = AudioRecord(
                    MediaRecorder.AudioSource.VOICE_COMMUNICATION,
                    SAMPLE_RATE,
                    CHANNEL_IN,
                    ENCODING,
                    bufferSize
                )
            } catch (e: Exception) {
                Log.w(TAG, "AudioRecord creation with VOICE_COMMUNICATION failed: ${e.message}")
            }

            if (record == null || record.state != AudioRecord.STATE_INITIALIZED) {
                Log.w(TAG, "VOICE_COMMUNICATION uninitialized, falling back to AudioSource.MIC")
                try {
                    record?.release()
                } catch (_: Exception) {}
                record = AudioRecord(
                    MediaRecorder.AudioSource.MIC,
                    SAMPLE_RATE,
                    CHANNEL_IN,
                    ENCODING,
                    bufferSize
                )
            }

            if (record.state != AudioRecord.STATE_INITIALIZED) {
                Log.e(TAG, "AudioRecord initialization failed for both VOICE_COMMUNICATION and MIC")
                try {
                    record.release()
                } catch (_: Exception) {}
                return
            }

            audioRecord = record
            audioRecord?.startRecording()
            isRecording.set(true)
            Log.i(TAG, "AudioRecord recording started successfully with source ${audioRecord?.audioSource}")

            recordingThread = Thread({
                android.os.Process.setThreadPriority(android.os.Process.THREAD_PRIORITY_URGENT_AUDIO)
                val pcmBuffer = ByteArray(BYTES_PER_FRAME)

                while (isRecording.get()) {
                    val readBytes = audioRecord?.read(pcmBuffer, 0, BYTES_PER_FRAME) ?: -1
                    if (readBytes == BYTES_PER_FRAME) {
                        // Encode 640-byte PCM to Opus
                        val encodedOpus = encodePcmToOpus(pcmBuffer)

                        // Assemble 7-byte binary transport frame:
                        // Byte 0: 0x10 (PTT Audio)
                        // Bytes 1-2: uint16 sequence number
                        // Bytes 3-6: uint32 monotonic offset (ms)
                        // Bytes 7..N: raw Opus payload
                        val now = System.currentTimeMillis()
                        val offsetMs = (now - burstStartTimeMs).toInt()

                        val frame = ByteBuffer.allocate(7 + encodedOpus.size).order(ByteOrder.BIG_ENDIAN)
                        frame.put(0x10.toByte())
                        frame.putShort((sequenceNumber and 0xFFFF).toShort())
                        frame.putInt(offsetMs)
                        frame.put(encodedOpus)

                        sequenceNumber = (sequenceNumber + 1) and 0xFFFF
                        onAudioPacketReady?.invoke(frame.array())
                    }
                }
            }, "PttAudioRecordingThread").apply { start() }

        } catch (e: Exception) {
            Log.e(TAG, "Failed to start AudioRecord: ${e.message}")
        }
    }

    /**
     * Lazy Microphone Release.
     * AudioRecord is immediately stopped and released when floor is released.
     */
    @Synchronized
    fun stopRecording() {
        isRecording.set(false)
        recordingThread?.interrupt()
        recordingThread = null

        try {
            if (audioRecord?.state == AudioRecord.STATE_INITIALIZED) {
                audioRecord?.stop()
            }
            audioRecord?.release()
        } catch (e: Exception) {
            Log.w(TAG, "Error stopping audioRecord: ${e.message}")
        }
        audioRecord = null
    }

    /* ---------------- Opus Codec Wrappers ---------------- */

    private fun encodePcmToOpus(pcm: ByteArray): ByteArray {
        if (!isOpusAvailable) return pcm
        return try {
            val opusClass = Class.forName("io.github.thewh1teagle.opus.Opus")
            val encodeMethod = opusClass.getMethod("encode", ByteArray::class.java, Int::class.javaPrimitiveType)
            encodeMethod.invoke(null, pcm, SAMPLES_PER_FRAME) as? ByteArray ?: pcm
        } catch (_: Exception) {
            pcm
        }
    }

    private fun decodeOpusToPcm(opus: ByteArray): ByteArray {
        if (!isOpusAvailable) return opus
        return try {
            val opusClass = Class.forName("io.github.thewh1teagle.opus.Opus")
            val decodeMethod = opusClass.getMethod("decode", ByteArray::class.java, Int::class.javaPrimitiveType)
            decodeMethod.invoke(null, opus, SAMPLES_PER_FRAME) as? ByteArray ?: opus
        } catch (_: Exception) {
            opus
        }
    }

    fun purgeJitterBuffer() {
        jitterBuffer.flush()
    }
}
