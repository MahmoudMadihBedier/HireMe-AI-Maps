class CvAnalysisResult {
  final int matchPercentage;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> suggestions;

  CvAnalysisResult({
    required this.matchPercentage,
    required this.strengths,
    required this.weaknesses,
    required this.suggestions,
  });

  factory CvAnalysisResult.fromMap(Map<String, dynamic> map) {
    return CvAnalysisResult(
      matchPercentage: (map['match_percentage'] as num?)?.toInt() ?? 0,
      strengths: (map['strengths'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      weaknesses: (map['weaknesses'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      suggestions: (map['suggestions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
