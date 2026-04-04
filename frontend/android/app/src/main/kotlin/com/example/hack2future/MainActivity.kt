package com.example.hack2future

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.Bundle
import android.os.IBinder
import android.util.Log
import com.google.mlkit.genai.common.DownloadStatus
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class MainActivity : FlutterActivity() {
    private val TAG = "MLKitSpeechMain"
    private val METHOD_CHANNEL = "dev.genai.mlkit_speech/control"
    private val EVENT_CHANNEL = "dev.genai.mlkit_speech/text_stream"

    private var eventSink: EventChannel.EventSink? = null
    private val coroutineScope = CoroutineScope(Dispatchers.Main + Job())
    private var downloadJob: Job? = null

    // Foreground Service Integration
    private var speechService: SpeechRecognitionService? = null
    private var isBound = false

    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(className: ComponentName, service: IBinder) {
            val binder = service as SpeechRecognitionService.LocalBinder
            speechService = binder.getService()
            isBound = true
            setupServiceCallbacks()
            Log.d(TAG, "onServiceConnected: SpeechRecognitionService bound")
        }

        override fun onServiceDisconnected(arg0: ComponentName) {
            isBound = false
            speechService = null
            Log.d(TAG, "onServiceDisconnected: SpeechRecognitionService disconnected")
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Bind to background service
        Intent(this, SpeechRecognitionService::class.java).also { intent ->
            startService(intent) // ensures it stays running as Foreground Service independently
            bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d(TAG, "configureFlutterEngine: setting up channels")

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    Log.d(TAG, "EventChannel onListen: eventSink connected")
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    Log.d(TAG, "EventChannel onCancel: eventSink disconnected")
                    eventSink = null
                }
            }
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            Log.d(TAG, "MethodChannel received: ${call.method}")
            when (call.method) {
                "initClient" -> handleInitClient(call, result)
                "checkStatus" -> handleCheckStatus(result)
                "downloadModel" -> handleDownloadModel(result)
                "startRecognition" -> handleStartRecognition(result)
                "stopRecognition" -> handleStopRecognition(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun setupServiceCallbacks() {
        speechService?.onPartialText = { text ->
            coroutineScope.launch { eventSink?.success(text) }
        }
        speechService?.onFinalText = { text ->
            coroutineScope.launch { eventSink?.success(text) }
        }
        speechService?.onError = { msg, code ->
            coroutineScope.launch { eventSink?.error("RECOGNITION_ERROR", msg, code) }
        }
    }

    private fun handleInitClient(call: MethodCall, result: MethodChannel.Result) {
        try {
            val localeTag = call.argument<String>("locale") ?: "en-US"
            val modeStr = call.argument<String>("mode") ?: "BASIC"
            Log.d(TAG, "initClient: locale=$localeTag, mode=$modeStr")

            if (!isBound || speechService == null) {
                result.error("SERVICE_UNBOUND", "Speech Service is not connected yet", null)
                return
            }

            speechService?.initClient(localeTag, modeStr)
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "initClient failed: ${e.message}", e)
            result.error("INIT_ERROR", "Failed to initialize ML Kit Speech client", e.message)
        }
    }

    private fun handleCheckStatus(result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                if (!isBound || speechService == null) {
                    result.error("SERVICE_UNBOUND", "Speech Service is not connected yet", null)
                    return@launch
                }
                
                val status = speechService?.checkStatus() ?: 0 // UNAVAILABLE
                result.success(status)
            } catch (e: Exception) {
                Log.e(TAG, "checkStatus failed: ${e.message}", e)
                result.error("STATUS_ERROR", "Failed to check model status", e.message)
            }
        }
    }

    private fun handleDownloadModel(result: MethodChannel.Result) {
        downloadJob?.cancel()
        downloadJob = coroutineScope.launch {
            try {
                if (!isBound || speechService == null) {
                    result.error("SERVICE_UNBOUND", "Speech Service is not connected yet", null)
                    return@launch
                }

                speechService?.downloadModel()?.collect { downloadStatus ->
                    // Logs omitted for brevity (similar to before)
                }
                result.success(true)
            } catch (e: Exception) {
                Log.e(TAG, "downloadModel failed: ${e.message}", e)
                result.error("DOWNLOAD_ERROR", "Failed to download model", e.message)
            }
        }
    }

    private fun handleStartRecognition(result: MethodChannel.Result) {
        // Reply immediately so await completes and EventChannel connects.
        result.success(true)
        Log.d(TAG, "startRecognition: replied true to Dart, launching recognition")

        coroutineScope.launch {
            var waited = 0
            while (eventSink == null && waited < 2000) {
                delay(50)
                waited += 50
            }
            if (!isBound || speechService == null) {
                eventSink?.error("SERVICE_UNBOUND", "Speech Service is not connected", null)
                return@launch
            }
            speechService?.startRecognition()
        }
    }

    private fun handleStopRecognition(result: MethodChannel.Result) {
        try {
            speechService?.stopRecognition()
            result.success(true)
        } catch (e: Exception) {
            result.error("STOP_ERROR", "Failed to stop recognition", e.message)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        if (isBound) {
            unbindService(serviceConnection)
            isBound = false
        }
        coroutineScope.cancel()
    }
}