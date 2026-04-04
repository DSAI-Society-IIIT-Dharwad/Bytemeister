package com.example.hack2future

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.os.Binder
import android.os.Build
import android.os.IBinder
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
import java.util.Locale

class SpeechRecognitionService : Service() {
    private val TAG = "SpeechRecognitionSvc"
    private val NOTIFICATION_CHANNEL_ID = "speech_recognition_channel"
    private val NOTIFICATION_ID = 1

    private val binder = LocalBinder()

    private var speechRecognizer: SpeechRecognizer? = null
    private val coroutineScope = CoroutineScope(Dispatchers.Main + Job())
    private var recognitionJob: Job? = null
    private var downloadJob: Job? = null

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
        recognitionJob = coroutineScope.launch {
            try {
                val request = speechRecognizerRequest {
                    audioSource = AudioSource.fromMic()
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
    }

    fun stopRecognition() {
        recognitionJob?.cancel()
        coroutineScope.launch {
            speechRecognizer?.stopRecognition()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "onDestroy: Service destroyed")
        coroutineScope.cancel()
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
