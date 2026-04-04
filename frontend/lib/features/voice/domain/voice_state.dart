enum VoiceStatus { idle, initializing, downloading, recording, processing, synthesizing, error }

class VoiceState {
  final VoiceStatus status;
  final String? transcript;
  final List<double> waveformData;
  final String? errorMessage;
  final String? audioPath;
  final bool isPlaying;
  final bool isModelReady;
  final String locale;

  VoiceState({
    required this.status,
    this.transcript,
    this.waveformData = const [],
    this.errorMessage,
    this.audioPath,
    this.isPlaying = false,
    this.isModelReady = false,
    this.locale = 'en-US',
  });

  VoiceState copyWith({
    VoiceStatus? status,
    String? transcript,
    List<double>? waveformData,
    String? errorMessage,
    String? audioPath,
    bool? isPlaying,
    bool? isModelReady,
    String? locale,
  }) {
    return VoiceState(
      status: status ?? this.status,
      transcript: transcript ?? this.transcript,
      waveformData: waveformData ?? this.waveformData,
      errorMessage: errorMessage ?? this.errorMessage,
      audioPath: audioPath ?? this.audioPath,
      isPlaying: isPlaying ?? this.isPlaying,
      isModelReady: isModelReady ?? this.isModelReady,
      locale: locale ?? this.locale,
    );
  }
}
