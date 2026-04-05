import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class SearchState {
  final String query;
  final List<Map<String, dynamic>> results;
  final bool isLoading;
  final String? error;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.error,
  });

  SearchState copyWith({
    String? query,
    List<Map<String, dynamic>>? results,
    bool? isLoading,
    String? error,
  }) =>
      SearchState(
        query: query ?? this.query,
        results: results ?? this.results,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class SearchNotifier extends StateNotifier<SearchState> {
  final MemoryLayerClient _client;

  SearchNotifier(this._client) : super(const SearchState());

  Future<void> search(String query, {String? userId}) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(results: [], query: '', isLoading: false);
      return;
    }

    state = state.copyWith(query: query, isLoading: true, error: null);

    final results = await _client.semanticSearch(query, userId: userId);

    state = state.copyWith(
      results: results,
      isLoading: false,
      error: results.isEmpty ? null : null,
    );
  }

  void clear() {
    state = const SearchState();
  }
}

final searchNotifierProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(ref.watch(memoryLayerClientProvider));
});
