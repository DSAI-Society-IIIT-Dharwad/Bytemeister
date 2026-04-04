import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/review_state.dart';
import '../domain/extracted_entity.dart';

class ReviewNotifier extends StateNotifier<ReviewState> {
  ReviewNotifier()
    : super(ReviewState(workflowType: WorkflowType.healthcare, entities: []));

  void setWorkflow(WorkflowType type) {
    state = state.copyWith(
      workflowType: type,
      entities: _getInitialEntities(type),
    );
  }

  void updateEntity(int index, String newValue) {
    final updatedEntities = List<ExtractedEntity>.from(state.entities);
    updatedEntities[index] = updatedEntities[index].copyWith(value: newValue);
    state = state.copyWith(entities: updatedEntities);
  }

  void toggleVerified(int index) {
    final updatedEntities = List<ExtractedEntity>.from(state.entities);
    updatedEntities[index] = updatedEntities[index].copyWith(
      isVerified: !updatedEntities[index].isVerified,
    );
    state = state.copyWith(entities: updatedEntities);
  }

  List<ExtractedEntity> _getInitialEntities(WorkflowType type) {
    if (type == WorkflowType.healthcare) {
      return [
        ExtractedEntity(key: 'Symptoms', value: 'Fever, Cough'),
        ExtractedEntity(key: 'Diagnosis', value: 'Influenza'),
        ExtractedEntity(key: 'Treatment', value: 'Paracetamol, Rest'),
      ];
    } else {
      return [
        ExtractedEntity(key: 'Account Confirmation', value: 'Confirmed'),
        ExtractedEntity(key: 'Payment Mode', value: 'UPI'),
        ExtractedEntity(key: 'Reason', value: 'Personal Loan'),
      ];
    }
  }

  Future<void> submit() async {
    state = state.copyWith(isSubmitting: true);
    await Future.delayed(const Duration(seconds: 2));
    state = state.copyWith(isSubmitting: false);
  }
}

final reviewNotifierProvider =
    StateNotifierProvider<ReviewNotifier, ReviewState>((ref) {
      return ReviewNotifier();
    });
