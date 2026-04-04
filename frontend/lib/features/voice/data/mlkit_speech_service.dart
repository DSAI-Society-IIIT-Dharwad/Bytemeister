import 'package:flutter/services.dart';

enum MlkitModelStatus {
  unavailable(0),
  downloadable(1),
  downloading(2),
  available(3);

  final int value;
  const MlkitModelStatus(this.value);

  static MlkitModelStatus fromInt(int value) {
    return MlkitModelStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MlkitModelStatus.unavailable,
    );
  }
}

class MlkitSpeechService {
  static const methodChannel = MethodChannel('dev.genai.mlkit_speech/control');
  static const eventChannel = EventChannel('dev.genai.mlkit_speech/text_stream');

  Future<void> initClient({String locale = 'en-US', String mode = 'ADVANCED'}) async {
    try {
      await methodChannel.invokeMethod('initClient', {'locale': locale, 'mode': mode});
    } on PlatformException catch (e) {
      throw Exception('Failed to init client: ${e.message}');
    }
  }

  Future<MlkitModelStatus> checkStatus() async {
    try {
      final int status = await methodChannel.invokeMethod('checkStatus');
      return MlkitModelStatus.fromInt(status);
    } on PlatformException catch (e) {
      throw Exception('Failed to check status: ${e.message}');
    }
  }

  Future<void> downloadModel() async {
    try {
      await methodChannel.invokeMethod('downloadModel');
    } on PlatformException catch (e) {
      throw Exception('Failed to download model: ${e.message}');
    }
  }

  Future<void> startRecognition() async {
    try {
      await methodChannel.invokeMethod('startRecognition');
    } on PlatformException catch (e) {
      throw Exception('Failed to start recognition: ${e.message}');
    }
  }

  Future<void> stopRecognition() async {
    try {
      await methodChannel.invokeMethod('stopRecognition');
    } on PlatformException catch (e) {
      throw Exception('Failed to stop recognition: ${e.message}');
    }
  }

  Stream<String> get textStream {
    return eventChannel.receiveBroadcastStream().cast<String>();
  }

  Future<String?> getSavedAudioPath() async {
    try {
      return await methodChannel.invokeMethod<String>('getSavedAudioPath');
    } on PlatformException catch (_) {
      // Intentionally handling the "NO_AUDIO" exception thrown by MainActivity internally
      return null;
    }
  }
}
