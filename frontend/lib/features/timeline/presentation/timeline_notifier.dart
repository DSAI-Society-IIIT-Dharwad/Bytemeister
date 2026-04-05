import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class TimelineState {
  final List<Map<String, dynamic>> entries;
  final bool isLoading;
  final String? error;
  final String userId;

  const TimelineState({
    this.entries = const [],
    this.isLoading = false,
    this.error,
    this.userId = 'Rahul_Dr._Smith',
  });

  TimelineState copyWith({
    List<Map<String, dynamic>>? entries,
    bool? isLoading,
    String? error,
    String? userId,
  }) =>
      TimelineState(
        entries: entries ?? this.entries,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        userId: userId ?? this.userId,
      );
}

class TimelineNotifier extends StateNotifier<TimelineState> {
  final MemoryLayerClient _client;

  TimelineNotifier(this._client) : super(const TimelineState()) {
    loadTimeline();
  }

  Future<void> loadTimeline([String? userId]) async {
    final id = userId ?? state.userId;
    state = state.copyWith(isLoading: true, error: null, userId: id);

    final entries = await _client.getUserTimeline(id);
    state = state.copyWith(
      entries: entries,
      isLoading: false,
      error: entries.isEmpty ? 'No timeline entries found for "$id".' : null,
    );
  }

  /// Returns true on success, false on failure.
  Future<bool> updateRecord(
    String dbId, {
    required String correctedTranscript,
    required Map<String, dynamic> correctedExtraction,
  }) async {
    final success = await _client.updateRecord(
      dbId,
      correctedTranscript: correctedTranscript,
      correctedExtraction: correctedExtraction,
    );
    if (success) loadTimeline();
    return success;
  }
}

final timelineNotifierProvider =
    StateNotifierProvider<TimelineNotifier, TimelineState>((ref) {
  return TimelineNotifier(ref.watch(memoryLayerClientProvider));
});
