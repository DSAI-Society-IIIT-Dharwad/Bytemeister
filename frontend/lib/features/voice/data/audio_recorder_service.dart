import 'dart:async';
import 'package:record/record.dart';

class AudioRecorderService {
  final _audioRecorder = AudioRecorder();
  StreamSubscription<RecordState>? _recordStateSubscription;
  StreamSubscription<Amplitude>? _amplitudeSubscription;

  Future<void> start(RecordConfig config, String path) async {
    if (await _audioRecorder.hasPermission()) {
      await _audioRecorder.start(config, path: path);
    }
  }

  Future<String?> stop() async {
    return await _audioRecorder.stop();
  }

  Future<void> dispose() async {
    await _audioRecorder.dispose();
    _recordStateSubscription?.cancel();
    _amplitudeSubscription?.cancel();
  }

  Stream<Amplitude> getAmplitudeStream() {
    return _audioRecorder.onAmplitudeChanged(const Duration(milliseconds: 100));
  }

  Stream<RecordState> getRecordStateStream() {
    return _audioRecorder.onStateChanged();
  }
}
