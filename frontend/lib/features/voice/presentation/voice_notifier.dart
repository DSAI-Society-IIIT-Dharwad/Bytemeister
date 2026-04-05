import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import '../domain/voice_state.dart';
import '../data/audio_recorder_service.dart';
import '../../../core/network/api_client.dart';

class VoiceNotifier extends StateNotifier<VoiceState> {
  final AudioRecorderService _recorderService;
  final ApiClient _apiClient;
  StreamSubscription? _amplitudeSubscription;
  final AudioPlayer _audioPlayer = AudioPlayer();

  VoiceNotifier(this._recorderService, this._apiClient)
      : super(VoiceState(status: VoiceStatus.idle)) {
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) state = state.copyWith(isPlaying: false);
    });
  }

  Future<void> startRecording() async {
    final micStatus = await Permission.microphone.request();
    if (micStatus != PermissionStatus.granted) {
      state = state.copyWith(
          status: VoiceStatus.error,
          errorMessage: 'Microphone permission denied.');
      return;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Live Transcribe MLKit Thingy is commented out/removed.
      // We just record pure audio now.
      await _recorderService.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 16000),
        path,
      );

      state = state.copyWith(
        status: VoiceStatus.recording,
        waveformData: [],
        transcript: null,
        audioPath: path,
      );

      _amplitudeSubscription = _recorderService.getAmplitudeStream().listen(
        (amp) {
          if (!mounted) return;
          final updatedWaveform = List<double>.from(state.waveformData)
            ..add(amp.current);
          if (updatedWaveform.length > 50) updatedWaveform.removeAt(0);

          state = state.copyWith(waveformData: updatedWaveform);
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

    try {
      final path = await _recorderService.stop();
      if (path != null) {
        state = state.copyWith(
          status: VoiceStatus.processing, // Signal UI we are uploading to Python
          audioPath: path,
          transcript: "Uploading to AI Server...",
        );
        
        // Push file through Dio HTTP
        final result = await _apiClient.processAudio(path);
        
        if (result != null) {
          final summary = result['extracted_data']?['overall_summary'] ?? "Analysis complete.";
          state = state.copyWith(
            status: VoiceStatus.idle,
            transcript: summary,
          );
        } else {
          state = state.copyWith(
            status: VoiceStatus.idle,
            transcript: "Server processing failed.",
          );
        }
      } else {
        state = state.copyWith(
          status: VoiceStatus.idle,
          transcript: "Recording failed.",
        );
      }
    } catch (e) {
      debugPrint("Failed to stop recording: $e");
      state = state.copyWith(status: VoiceStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> changeLocale(String newLocale) async {
    // Legacy mapping (MLKit disabled). No-op for now.
    state = state.copyWith(locale: newLocale);
  }

  Future<void> togglePlayback() async {
    if (state.audioPath == null) return;

    if (state.isPlaying) {
      await _audioPlayer.stop();
      state = state.copyWith(isPlaying: false);
    } else {
      await _audioPlayer.play(DeviceFileSource(state.audioPath!));
      state = state.copyWith(isPlaying: true);
    }
  }

  @override
  void dispose() {
    _amplitudeSubscription?.cancel();
    _audioPlayer.dispose();
    _recorderService.dispose();
    super.dispose();
  }
}

final audioRecorderServiceProvider = Provider((ref) => AudioRecorderService());

final voiceNotifierProvider =
    StateNotifierProvider<VoiceNotifier, VoiceState>((ref) {
  final recorder = ref.watch(audioRecorderServiceProvider);
  final api = ref.watch(apiClientProvider);
  return VoiceNotifier(recorder, api);
});
