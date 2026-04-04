import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../domain/voice_state.dart';
import '../data/audio_recorder_service.dart';
import '../data/mlkit_speech_service.dart';

class VoiceNotifier extends StateNotifier<VoiceState> {
  final MlkitSpeechService _mlkitSpeechService;
  StreamSubscription? _amplitudeSubscription;
  StreamSubscription? _textSubscription;

  VoiceNotifier(this._mlkitSpeechService)
      : super(VoiceState(status: VoiceStatus.idle)) {
    _initMlkit('en-US'); // Default to English
  }

  Future<void> _initMlkit(String locale) async {
    try {
      state = state.copyWith(status: VoiceStatus.initializing);
      await _mlkitSpeechService.initClient(locale: locale, mode: 'BASIC');
      
      final status = await _mlkitSpeechService.checkStatus();
      if (status == MlkitModelStatus.downloadable) {
        state = state.copyWith(status: VoiceStatus.downloading);
        await _mlkitSpeechService.downloadModel();
        // Assume download finishes and is now ready. 
        // In a real scenario, we might poll or listen to a progress stream.
        state = state.copyWith(status: VoiceStatus.idle, isModelReady: true);
      } else if (status == MlkitModelStatus.available) {
        state = state.copyWith(status: VoiceStatus.idle, isModelReady: true);
      } else {
        state = state.copyWith(
            status: VoiceStatus.error,
            errorMessage: 'Model status: $status. Cannot proceed.');
      }
    } on PlatformException catch (e) {
      state = state.copyWith(
          status: VoiceStatus.error,
          errorMessage: 'ML Kit Init Error: ${e.message}');
    } catch (e) {
      state = state.copyWith(
          status: VoiceStatus.error, errorMessage: 'Failed to init ML Kit: $e');
    }
  }

  Future<void> startRecording() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      state = state.copyWith(
          status: VoiceStatus.error,
          errorMessage: 'Microphone permission denied.');
      return;
    }

    if (!state.isModelReady) {
      state = state.copyWith(
          status: VoiceStatus.error,
          errorMessage: 'ML Kit model is not ready yet.');
      return;
    }

    state = state.copyWith(
        status: VoiceStatus.recording,
        waveformData: [],
        transcript: null,
        audioPath: null);

    try {
      // ML Kit owns the microphone — do NOT start _recorderService in parallel
      // or both will compete for the mic and ML Kit will produce no results.
      await _mlkitSpeechService.startRecognition();
      _textSubscription = _mlkitSpeechService.textStream.listen(
        (text) {
          state = state.copyWith(transcript: text);
        },
        onError: (e) {
          debugPrint('MLKit text stream error: $e');
          state = state.copyWith(
            status: VoiceStatus.error,
            errorMessage: 'Recognition stream error: $e',
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
          status: VoiceStatus.error,
          errorMessage: 'Failed to start recording: $e');
    }
  }

  Future<void> stopRecording() async {
    state = state.copyWith(status: VoiceStatus.processing);
    _amplitudeSubscription?.cancel();
    _textSubscription?.cancel();

    try {
      await _mlkitSpeechService.stopRecognition();
    } catch (e) {
      debugPrint("Failed to stop ML Kit: $e");
    }

    // ML Kit owns the mic — no local audio file is produced.
    // The transcript captured via the EventChannel stream is the output.
    state = state.copyWith(
      status: VoiceStatus.idle,
      audioPath: null,
      transcript: state.transcript?.isNotEmpty == true
          ? state.transcript
          : 'No speech detected.',
    );
  }

  Future<void> changeLocale(String newLocale) async {
    // If currently recording, stop first
    if (state.status == VoiceStatus.recording) {
      await stopRecording();
    }
    // Re-initialize the model with the new locale
    await _initMlkit(newLocale);
  }

  Future<void> togglePlayback() async {
    // Playback not available when using ML Kit mic capture.
    // audioPath is null in this mode.
  }

  @override
  void dispose() {
    _amplitudeSubscription?.cancel();
    _textSubscription?.cancel();
    super.dispose();
  }
}

final audioRecorderServiceProvider = Provider((ref) => AudioRecorderService());
final mlkitSpeechServiceProvider = Provider((ref) => MlkitSpeechService());

final voiceNotifierProvider =
    StateNotifierProvider<VoiceNotifier, VoiceState>((ref) {
  final mlkitSpeechService = ref.watch(mlkitSpeechServiceProvider);
  return VoiceNotifier(mlkitSpeechService);
});
