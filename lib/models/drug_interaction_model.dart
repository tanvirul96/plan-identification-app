enum InteractionSeverity {
  contraindicated, // 🔴 Severe
  moderateCaution, // 🟡 Monitor closely
  safe,            // 🟢 Minor / Safe
}

class HerbDrugInteraction {
  final String plantLocalName;
  final String plantScientificName;
  final String drugName;
  final String drugClass;
  final InteractionSeverity severity;
  final String mechanismEn;
  final String mechanismBn;
  final String clinicalEffectEn;
  final String clinicalEffectBn;
  final String recommendationEn;
  final String recommendationBn;

  HerbDrugInteraction({
    required this.plantLocalName,
    required this.plantScientificName,
    required this.drugName,
    required this.drugClass,
    required this.severity,
    required this.mechanismEn,
    required this.mechanismBn,
    required this.clinicalEffectEn,
    required this.clinicalEffectBn,
    required this.recommendationEn,
    required this.recommendationBn,
  });
}
