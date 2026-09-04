class RecognitionContext {
  final String rawText;
  final String normalizedText;
  final List<String> lines;
  final String? currentPickupCode;

  const RecognitionContext({
    required this.rawText,
    required this.normalizedText,
    required this.lines,
    this.currentPickupCode,
  });
}
