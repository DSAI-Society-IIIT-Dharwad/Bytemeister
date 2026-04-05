import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../voice/data/mlkit_speech_service.dart';
import 'package:flutter/foundation.dart';

/// State for the passive background 'tee' listener
class BackgroundListeningState {
  final bool isActive;
  final String? error;

  const BackgroundListeningState({this.isActive = false, this.error});

  BackgroundListeningState copyWith({bool? isActive, String? error}) =>
      BackgroundListeningState(
        isActive: isActive ?? this.isActive,
        error: error,
      );
}

class BackgroundListeningNotifier extends StateNotifier<BackgroundListeningState> {
  // MlkitSpeechService is the Dart bridge to the native
  // SpeechRecognitionService via MethodChannel.
  // MainActivity ALREADY starts and binds that native service in onCreate,
  // so by the time the user ever taps the toggle it's long been bound.
  final MlkitSpeechService _mlkit = MlkitSpeechService();

  // Has initClient been called yet this session?
  bool _clientInitialized = false;

  BackgroundListeningNotifier() : super(const BackgroundListeningState());

  Future<void> toggle(bool enable) async {
    if (enable) {
      await _turnOn();
    } else {
      await _turnOff();
    }
  }

  Future<void> _turnOn() async {
    state = state.copyWith(error: null);

    // 1. Microphone permission
    final micStatus = await Permission.microphone.request();
    if (micStatus != PermissionStatus.granted) {
      debugPrint('[BG] Microphone permission denied');
      state = BackgroundListeningState(
        isActive: false,
        error: 'Microphone permission denied. Please grant it in Settings.',
      );
      return;
    }

    try {
      // 2. Init the ML Kit client once per app session
      if (!_clientInitialized) {
        debugPrint('[BG] Calling initClient …');
        await _mlkit.initClient(locale: 'en-US', mode: 'ADVANCED');
        _clientInitialized = true;
        debugPrint('[BG] initClient OK');
      }

      // 3. Start native mic tapping + keyword recognition
      debugPrint('[BG] Starting recognition …');
      await _mlkit.startRecognition();
      debugPrint('[BG] Background listening ON');

      state = const BackgroundListeningState(isActive: true);
    } on Exception catch (e) {
      debugPrint('[BG] Error turning on: $e');
      // If initClient threw SERVICE_UNBOUND, the native service isn't bound
      // yet (rare race). Reset so user can retry.
      _clientInitialized = false;
      state = BackgroundListeningState(
        isActive: false,
        error: 'Could not start listening: $e',
      );
    }
  }

  Future<void> _turnOff() async {
    try {
      debugPrint('[BG] Stopping recognition …');
      await _mlkit.stopRecognition();
      debugPrint('[BG] Background listening OFF');
    } on Exception catch (e) {
      debugPrint('[BG] Error stopping (non-fatal): $e');
    }
    state = const BackgroundListeningState(isActive: false);
  }
}

final backgroundListeningProvider =
    StateNotifierProvider<BackgroundListeningNotifier, BackgroundListeningState>(
        (ref) => BackgroundListeningNotifier());
