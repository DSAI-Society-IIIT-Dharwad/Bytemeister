import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  DashboardNotifier() : super(DashboardState()) {
    _loadInteractions();
  }

  void setSelectedDomain(String domain) {
    state = state.copyWith(selectedDomain: domain);
  }

  void _loadInteractions() {
    state = state.copyWith(
      interactions: [
        Interaction(
          id: '1',
          date: DateTime.now().subtract(const Duration(days: 1)),
          domainType: 'Healthcare',
          summary: 'Patient with fever and cough.',
          transcript: "Doctor: How can I help you today?\nPatient: I've been having a fever and a persistent cough for two days now.\nDoctor: Any other symptoms?\nPatient: Just some fatigue and a bit of chest tightness.",
          details: 'Recommended rest, increased fluid intake, and paracetamol for the fever. Follow-up in 3 days if symptoms persist.',
          status: InteractionStatus.verified,
        ),
        Interaction(
          id: '2',
          date: DateTime.now().subtract(const Duration(hours: 2)),
          domainType: 'Finance',
          summary: 'Loan account confirmation.',
          transcript: "Agent: Hello, I'm calling to confirm your loan application.\nCustomer: Yes, I applied for a personal loan yesterday.\nAgent: We've reviewed your details and everything looks good. Can you confirm your income?\nCustomer: Yes, it's roughly 5,000 per month.",
          details: 'Confirmed loan application status. Next step is final verification of documents. Approval expected within 48 hours.',
          status: InteractionStatus.pending,
        ),
      ],
    );
  }
}

final dashboardNotifierProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
      return DashboardNotifier();
    });
