package com.example.kawalo_mobile.ptt.audio

import android.util.Log
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.ConcurrentSkipListMap

data class PttAudioPacket(
    val sequenceNumber: Int,
    val timestampOffsetMs: Long,
    val opusPayload: ByteArray,
    val arrivalTimeMs: Long = System.currentTimeMillis()
)

/**
 * Adaptive Playout Jitter Buffer implementing RFC 3550 RTP sequence and timestamp tracking.
 * Over TCP transport, bytes arrive in bursts (HoL blocking).
 * This buffer smooths bursts, targets 40-60ms pre-buffering playout delay,
 * automatically detects talkspurt burst transitions, and drops packets exceeding max capacity
 * to preserve real-time conversational freshness.
 */
class PttJitterBuffer(
    private val targetDelayMs: Long = 60L,
    private val maxPlayoutDelayMs: Long = 300L
) {
    companion object {
        private const val TAG = "PttJitterBuffer"
        private const val MAX_BUFFERED_PACKETS = 25 // 500ms max buffered audio
    }

    // Ordered packet queue sorted by sequence number
    private val packetQueue = ConcurrentSkipListMap<Int, PttAudioPacket>()
    private var baseTimestampMs: Long = -1L
    private var firstPacketArrivalMs: Long = -1L
    private var lastArrivalMs: Long = 0L
    private var lastSequenceNumber: Int = -1

    @Synchronized
    fun pushFrame(binaryFrame: ByteArray): Boolean {
        // Frame must have at least 7-byte transport header
        if (binaryFrame.size < 7) return false

        val buffer = ByteBuffer.wrap(binaryFrame).order(ByteOrder.BIG_ENDIAN)
        val opCode = buffer.get().toInt() and 0xFF
        if (opCode != 0x10) return false // 0x10 = PTT Audio

        val seq = buffer.short.toInt() and 0xFFFF
        val timestampOffsetMs = buffer.int.toLong() and 0xFFFFFFFFL

        val payloadSize = binaryFrame.size - 7
        val payload = ByteArray(payloadSize)
        buffer.get(payload)

        val now = System.currentTimeMillis()

        // Detect new talkspurt / burst:
        // 1. Initial burst (firstPacketArrivalMs == -1L)
        // 2. New burst sequence start (seq == 0)
        // 3. Inter-burst silence gap > 300ms
        // 4. Sequence reset (timestamp offset is small but last sequence was high)
        val isSeqZero = (seq == 0)
        val isGap = (now - lastArrivalMs > 300L) && (lastArrivalMs > 0L)
        val isSeqReset = (timestampOffsetMs < 100L) && (lastSequenceNumber > 5)

        if (firstPacketArrivalMs == -1L || isSeqZero || isGap || isSeqReset) {
            Log.d(TAG, "New talk burst detected (seqZero=$isSeqZero, gap=$isGap, seqReset=$isSeqReset, seq=$seq). Resetting timing.")
            packetQueue.clear()
            firstPacketArrivalMs = now
            baseTimestampMs = timestampOffsetMs
        }

        lastArrivalMs = now
        lastSequenceNumber = seq

        val packet = PttAudioPacket(
            sequenceNumber = seq,
            timestampOffsetMs = timestampOffsetMs,
            opusPayload = payload,
            arrivalTimeMs = now
        )

        // Drop oldest packets if buffer exceeds maximum queue depth (prevent latency accumulation)
        while (packetQueue.size >= MAX_BUFFERED_PACKETS) {
            packetQueue.pollFirstEntry()
        }

        packetQueue[seq] = packet
        return true
    }

    @Synchronized
    fun pollFrame(): ByteArray? {
        if (packetQueue.isEmpty()) {
            return null
        }

        val now = System.currentTimeMillis()

        // Pre-buffering: wait until at least 2 frames (40ms) or target delay elapsed
        if (packetQueue.size < 2 && (now - firstPacketArrivalMs) < targetDelayMs) {
            return null
        }

        val firstEntry = packetQueue.pollFirstEntry() ?: return null
        return firstEntry.value.opusPayload
    }

    @Synchronized
    fun flush() {
        packetQueue.clear()
        baseTimestampMs = -1L
        firstPacketArrivalMs = -1L
        lastArrivalMs = 0L
        lastSequenceNumber = -1
        Log.d(TAG, "Jitter buffer flushed")
    }

    fun size(): Int = packetQueue.size
}
