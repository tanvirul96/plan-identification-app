class LocalPredictionResult {
  final String modelName;
  final String predictedSpecies;
  final double confidence;
  final List<Map<String, dynamic>> top3Candidates;
  final List<List<double>>? camGrid; // 2D normalized Grad-CAM activation grid

  LocalPredictionResult({
    required this.modelName,
    required this.predictedSpecies,
    required this.confidence,
    required this.top3Candidates,
    this.camGrid,
  });
}
