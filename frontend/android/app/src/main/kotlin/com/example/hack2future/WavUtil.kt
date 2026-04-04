package com.example.hack2future

import java.io.File
import java.io.RandomAccessFile
import java.nio.ByteBuffer
import java.nio.ByteOrder

/**
 * Utility to write a proper 44-byte WAV header at the beginning of a raw PCM file.
 * We use 16kHz, 16-bit, Mono PCM as it is required by both ML Kit and general speech pipelines.
 */
object WavUtil {
    fun finalizeWavFile(file: File) {
        if (!file.exists() || file.length() < 44) return

        val totalDataLen = file.length() - 44
        val totalAudioLen = totalDataLen

        val sampleRate = 16000L
        val channels = 1
        val byteRate = 16000L * 2 * 1 // SampleRate * 16Bit(2Bytes) * Channels

        val header = ByteArray(44)
        
        // RIFF/WAV header
        header[0] = 'R'.code.toByte()
        header[1] = 'I'.code.toByte()
        header[2] = 'F'.code.toByte()
        header[3] = 'F'.code.toByte()
        
        // File length minus 8 bytes
        var size = (36 + totalAudioLen).toInt()
        header[4] = (size and 0xff).toByte()
        header[5] = ((size shr 8) and 0xff).toByte()
        header[6] = ((size shr 16) and 0xff).toByte()
        header[7] = ((size shr 24) and 0xff).toByte()
        
        // WAVE
        header[8] = 'W'.code.toByte()
        header[9] = 'A'.code.toByte()
        header[10] = 'V'.code.toByte()
        header[11] = 'E'.code.toByte()
        
        // 'fmt ' chunk
        header[12] = 'f'.code.toByte()
        header[13] = 'm'.code.toByte()
        header[14] = 't'.code.toByte()
        header[15] = ' '.code.toByte()
        
        header[16] = 16 // 4 bytes: size of 'fmt ' chunk
        header[17] = 0
        header[18] = 0
        header[19] = 0
        
        header[20] = 1 // format = 1 (PCM)
        header[21] = 0
        
        header[22] = channels.toByte()
        header[23] = 0
        
        header[24] = (sampleRate and 0xff).toByte()
        header[25] = ((sampleRate shr 8) and 0xff).toByte()
        header[26] = ((sampleRate shr 16) and 0xff).toByte()
        header[27] = ((sampleRate shr 24) and 0xff).toByte()
        
        header[28] = (byteRate and 0xff).toByte()
        header[29] = ((byteRate shr 8) and 0xff).toByte()
        header[30] = ((byteRate shr 16) and 0xff).toByte()
        header[31] = ((byteRate shr 24) and 0xff).toByte()
        
        header[32] = (2 * 16 / 8).toByte() // block align
        header[33] = 0
        
        header[34] = 16 // bits per sample
        header[35] = 0
        
        // 'data' chunk
        header[36] = 'd'.code.toByte()
        header[37] = 'a'.code.toByte()
        header[38] = 't'.code.toByte()
        header[39] = 'a'.code.toByte()
        
        val audioDataSize = totalAudioLen.toInt()
        header[40] = (audioDataSize and 0xff).toByte()
        header[41] = ((audioDataSize shr 8) and 0xff).toByte()
        header[42] = ((audioDataSize shr 16) and 0xff).toByte()
        header[43] = ((audioDataSize shr 24) and 0xff).toByte()

        // Overwrite first 44 bytes using RandomAccessFile
        RandomAccessFile(file, "rw").use { raf ->
            raf.seek(0)
            raf.write(header)
        }
    }

    /**
     * Pre-allocates a 44-byte empty header to the start of the file so we can fill it in post-recording.
     */
    fun writePlaceholderHeader(file: File) {
        val bytes = ByteArray(44)
        file.writeBytes(bytes)
    }
}
