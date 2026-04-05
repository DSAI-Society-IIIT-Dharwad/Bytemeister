import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/interaction.dart';

class DashboardState {
  final List<Interaction> interactions;
  final bool isLoading;
  final String selectedDomain; // 'All', 'Healthcare', 'Finance'

  DashboardState({
    this.interactions = const [],
    this.isLoading = false,
    this.selectedDomain = 'All',
  });

  DashboardState copyWith({
    List<Interaction>? interactions,
    bool? isLoading,
    String? selectedDomain,
  }) {
    return DashboardState(
      interactions: interactions ?? this.interactions,
      isLoading: isLoading ?? this.isLoading,
      selectedDomain: selectedDomain ?? this.selectedDomain,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final MemoryLayerClient _client;

  DashboardNotifier(this._client) : super(DashboardState()) {
    _loadInteractions();
  }

  void setSelectedDomain(String domain) {
    state = state.copyWith(selectedDomain: domain);
  }

  Future<void> _loadInteractions() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final records = await _client.getUserTimeline('Rahul_Dr._Smith');
      
      final parsedInteractions = records.map((entry) {
        final domain = entry['domain'] as String? ?? 'Unknown';
        final summary = entry['plain_summary'] as String? ?? 
                        entry['summary'] as String? ?? 'No summary provided.';
                        
        final transcript = entry['raw_transcript'] as String? ?? 
                           entry['transcript'] as String? ?? 'No transcript found.';
                           
        final fields = entry['domain_fields'] as Map? ?? 
                       entry['structured_extraction']?['domain_fields'] as Map? ?? {};
        
        // Convert the extraction JSON dict to string
        final detailsString = fields.entries.map((e) => '${e.key}: ${e.value}').join('\n');
        
        DateTime date;
        try {
          final timeStr = entry['date'] as String? ?? entry['timestamp'] as String? ?? entry['created_at'] as String?;
          date = timeStr != null ? DateTime.parse(timeStr) : DateTime.now();
        } catch (_) {
          date = DateTime.now();
        }

        return Interaction(
          id: entry['id']?.toString() ?? entry['db_id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          date: date,
          domainType: domain.substring(0, 1).toUpperCase() + domain.substring(1).toLowerCase(), // e.g. "Healthcare"
          summary: summary,
          transcript: transcript,
          details: detailsString.isEmpty ? 'No structured details found.' : detailsString,
          status: InteractionStatus.verified, // Assuming historical are verified
        );
      }).toList();

      state = state.copyWith(
        interactions: parsedInteractions,
        isLoading: false,
      );
    } catch (e) {
      // In case of failure, keep it empty instead of hardcoded
      state = state.copyWith(interactions: [], isLoading: false);
    }
  }
}

final dashboardNotifierProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
      return DashboardNotifier(ref.watch(memoryLayerClientProvider));
    });
