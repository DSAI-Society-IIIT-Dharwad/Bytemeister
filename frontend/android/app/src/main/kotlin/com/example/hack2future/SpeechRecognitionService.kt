package com.example.hack2future

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.ParcelFileDescriptor
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.mlkit.genai.common.DownloadStatus
import com.google.mlkit.genai.common.FeatureStatus
import com.google.mlkit.genai.common.audio.AudioSource
import com.google.mlkit.genai.speechrecognition.SpeechRecognition
import com.google.mlkit.genai.speechrecognition.SpeechRecognizer
import com.google.mlkit.genai.speechrecognition.SpeechRecognizerOptions
import com.google.mlkit.genai.speechrecognition.SpeechRecognizerResponse
import com.google.mlkit.genai.speechrecognition.speechRecognizerOptions
import com.google.mlkit.genai.speechrecognition.speechRecognizerRequest
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream
import java.util.Locale

class SpeechRecognitionService : Service() {
    private val TAG = "SpeechRecognitionSvc"
    private val NOTIFICATION_CHANNEL_ID = "speech_recognition_channel"
    private val NOTIFICATION_ID = 1

    private val binder = LocalBinder()

    private var speechRecognizer: SpeechRecognizer? = null
    private val coroutineScope = CoroutineScope(Dispatchers.Main + Job())
    private var recognitionJob: Job? = null
    private var audioRecordJob: Job? = null
    private var downloadJob: Job? = null

    @Volatile
    private var isRecording = false

    private var audioRecord: AudioRecord? = null

    // Tracking the saved audio file
    var lastSavedAudioPath: String? = null

    // Callbacks to communicate with MainActivity
    var onPartialText: ((String) -> Unit)? = null
    var onFinalText: ((String) -> Unit)? = null
    var onError: ((String, String?) -> Unit)? = null

    inner class LocalBinder : Binder() {
        fun getService(): SpeechRecognitionService = this@SpeechRecognitionService
    }

    override fun onBind(intent: Intent): IBinder {
        return binder
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "onCreate: Service created")
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand: Starting Foreground Service")
        
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            notificationIntent,
            PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("Hack2Future Background Listening")
            .setContentText("Listening for keywords...")
            .setSmallIcon(R.mipmap.ic_launcher) // Use default launcher icon
            .setContentIntent(pendingIntent)
            .build()

        startForeground(NOTIFICATION_ID, notification)

        // Keep service running
        return START_NOT_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Speech Recognition Background Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    fun initClient(localeTag: String, modeStr: String) {
        val locale = Locale.Builder().setLanguageTag(localeTag).build()
        val mode = if (modeStr == "ADVANCED") {
            SpeechRecognizerOptions.Mode.MODE_ADVANCED
        } else {
            SpeechRecognizerOptions.Mode.MODE_BASIC
        }

        speechRecognizer?.close()
        speechRecognizer = SpeechRecognition.getClient(
            speechRecognizerOptions {
                this.locale = locale
                this.preferredMode = mode
            }
        )
    }

    suspend fun checkStatus(): Int {
        return speechRecognizer?.checkStatus() ?: FeatureStatus.UNAVAILABLE
    }

    fun downloadModel(): Flow<DownloadStatus>? {
        return speechRecognizer?.download()
    }

    fun startRecognition() {
        recognitionJob?.cancel()
        audioRecordJob?.cancel()
        
        isRecording = true
        val sampleRate = 16000
        val bufferSize = AudioRecord.getMinBufferSize(
            sampleRate,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT
        ) * 2

        try {
            audioRecord = AudioRecord(
                MediaRecorder.AudioSource.MIC,
                sampleRate,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                bufferSize
            )
        } catch (e: SecurityException) {
            onError?.invoke("Microphone permission required", e.message)
            return
        }

        if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
            onError?.invoke("AudioRecord init failed", "Microphone in use?")
            return
        }

        // Setup Parcel pipes
        val pipe = ParcelFileDescriptor.createPipe()
        val readPfd = pipe[0]
        val writePfd = pipe[1]

        // Prepare local WAV cache file
        val ts = System.currentTimeMillis()
        val wavFile = File(cacheDir, "recording_$ts.wav")
        lastSavedAudioPath = wavFile.absolutePath
        
        // Write the empty 44-byte WAV header first to reserve space
        WavUtil.writePlaceholderHeader(wavFile)

        // Launch the internal ML Kit parser pipeline
        recognitionJob = coroutineScope.launch {
            try {
                val request = speechRecognizerRequest {
                    audioSource = AudioSource.fromPfd(readPfd)
                }

                speechRecognizer?.startRecognition(request)?.collect { response ->
                    when (response) {
                        is SpeechRecognizerResponse.PartialTextResponse -> {
                            onPartialText?.invoke(response.text)
                            checkKeywordsAndNotify(response.text)
                        }
                        is SpeechRecognizerResponse.FinalTextResponse -> {
                            onFinalText?.invoke(response.text)
                            checkKeywordsAndNotify(response.text)
                        }
                        is SpeechRecognizerResponse.CompletedResponse -> {
                            // Session completed
                            Log.d(TAG, "ML Kit Session Completed")
                        }
                        is SpeechRecognizerResponse.ErrorResponse -> {
                            onError?.invoke(response.e.message ?: "Unknown Error", response.e.errorCode?.toString())
                        }
                        else -> {}
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Recognition error", e)
                onError?.invoke("Recognition exception", e.message)
            }
        }

        // Launch the Tee byte-pump (Reads Mic -> Pumps File & Pipe)
        audioRecordJob = coroutineScope.launch(Dispatchers.IO) {
            val audioBuffer = ByteArray(bufferSize)
            audioRecord?.startRecording()

            FileOutputStream(writePfd.fileDescriptor).use { pipeOut ->
                // File output must start AFTER the 44-byte header! We already wrote it,
                // so we open in append mode, or RandomAccessFile.
                FileOutputStream(wavFile, true).use { fileOut ->
                    while (isRecording) {
                        val readData = audioRecord?.read(audioBuffer, 0, bufferSize) ?: 0
                        if (readData > 0) {
                            try {
                                // 1. Tee to ML Kit
                                pipeOut.write(audioBuffer, 0, readData)
                                // 2. Tee to Disk
                                fileOut.write(audioBuffer, 0, readData)
                            } catch (e: Exception) {
                                Log.e(TAG, "Pipe or File closed unexpectedly", e)
                                break
                            }
                        }
                    }
                }
            }

            // Cleanup when `isRecording` loop breaks natively
            audioRecord?.stop()
            audioRecord?.release()
            audioRecord = null
            
            readPfd.close()
            writePfd.close()

            // Finalize standard WAV header
            Log.d(TAG, "Finalizing WAV locally at ${wavFile.absolutePath}")
            WavUtil.finalizeWavFile(wavFile)
        }
    }

    fun stopRecognition() {
        Log.d(TAG, "stopRecognition called natively")
        isRecording = false // Breaks the AudioRecord pump
        coroutineScope.launch {
            try {
                speechRecognizer?.stopRecognition()
            } catch (e: Exception) {
                Log.e(TAG, "Error stopping recognizer early", e)
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        isRecording = false
        Log.d(TAG, "onDestroy: Service destroyed")
        coroutineScope.cancel()
        audioRecord?.release()
        speechRecognizer?.close()
        speechRecognizer = null
    }

    private var lastNotificationTime: Long = 0

    private fun checkKeywordsAndNotify(text: String) {
        val lowerText = text.lowercase()
        val keywords = listOf("health", "finance", "स्वास्थ्य", "वित्त")
        var detectedKeyword: String? = null

        for (kw in keywords) {
            if (lowerText.contains(kw)) {
                detectedKeyword = kw
                break
            }
        }

        if (detectedKeyword != null) {
            val now = System.currentTimeMillis()
            // Throttle notifications to max 1 every 30 seconds
            if (now - lastNotificationTime > 30000) {
                lastNotificationTime = now
                Log.d(TAG, "Keyword detected natively: $detectedKeyword")
                showKeywordNotification(detectedKeyword)
            }
        }
    }

    private fun showKeywordNotification(keyword: String) {
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            notificationIntent,
            PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("Keyword Detected!")
            .setContentText("We heard the keyword: \"$keyword\"")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()

        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(999, notification)
    }
}
