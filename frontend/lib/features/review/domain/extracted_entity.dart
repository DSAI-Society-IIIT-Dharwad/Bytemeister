class ExtractedEntity {
  final String key;
  final String value;
  final double confidence;
  final bool isVerified;

  ExtractedEntity({
    required this.key,
    required this.value,
    this.confidence = 1.0,
    this.isVerified = false,
  });

  ExtractedEntity copyWith({
    String? key,
    String? value,
    double? confidence,
    bool? isVerified,
  }) {
    return ExtractedEntity(
      key: key ?? this.key,
      value: value ?? this.value,
      confidence: confidence ?? this.confidence,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
