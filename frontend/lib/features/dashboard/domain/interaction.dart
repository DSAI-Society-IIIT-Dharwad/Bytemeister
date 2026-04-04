enum InteractionStatus { pending, verified }

class Interaction {
  final String id;
  final DateTime date;
  final String domainType; // Healthcare, Finance
  final String summary;
  final String transcript;
  final String details;
  final InteractionStatus status;

  Interaction({
    required this.id,
    required this.date,
    required this.domainType,
    required this.summary,
    required this.transcript,
    required this.details,
    required this.status,
  });
}
