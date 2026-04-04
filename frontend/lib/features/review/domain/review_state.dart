import 'extracted_entity.dart';

enum WorkflowType { healthcare, finance }

class ReviewState {
  final WorkflowType workflowType;
  final List<ExtractedEntity> entities;
  final bool isSubmitting;

  ReviewState({
    required this.workflowType,
    required this.entities,
    this.isSubmitting = false,
  });

  ReviewState copyWith({
    WorkflowType? workflowType,
    List<ExtractedEntity>? entities,
    bool? isSubmitting,
  }) {
    return ReviewState(
      workflowType: workflowType ?? this.workflowType,
      entities: entities ?? this.entities,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}
