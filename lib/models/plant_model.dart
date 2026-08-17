class PlantRecord {
  final String localName;
  final String scientificName;
  final String commonEnglishName;
  final String synonyms;
  final String family;
  final String growthHabit;
  final String keyVisualIdentifiers;
  final String activePhytochemicals;
  final String coreBioactivity;
  final String primaryIndications;
  final String traditionalPreparationMethods;
  final String standardDosage;
  final String safeVehicle;
  final String toxicityProfile;
  final String contraindications;
  final String adverseReactions;

  PlantRecord({
    required this.localName,
    required this.scientificName,
    required this.commonEnglishName,
    required this.synonyms,
    required this.family,
    required this.growthHabit,
    required this.keyVisualIdentifiers,
    required this.activePhytochemicals,
    required this.coreBioactivity,
    required this.primaryIndications,
    required this.traditionalPreparationMethods,
    required this.standardDosage,
    required this.safeVehicle,
    required this.toxicityProfile,
    required this.contraindications,
    required this.adverseReactions,
  });

  factory PlantRecord.fromCsvRow(List<String> row) {
    String getCol(int idx) => (idx < row.length) ? row[idx].trim() : '';

    return PlantRecord(
      localName: getCol(0),
      scientificName: getCol(1),
      commonEnglishName: getCol(2),
      synonyms: getCol(3),
      family: getCol(4),
      growthHabit: getCol(5),
      keyVisualIdentifiers: getCol(6),
      activePhytochemicals: getCol(7),
      coreBioactivity: getCol(8),
      primaryIndications: getCol(9),
      traditionalPreparationMethods: getCol(10),
      standardDosage: getCol(11),
      safeVehicle: getCol(12),
      toxicityProfile: getCol(13),
      contraindications: getCol(14),
      adverseReactions: getCol(15),
    );
  }

  factory PlantRecord.fromMap(Map<String, dynamic> map) {
    return PlantRecord(
      localName: map['Local Name'] ?? '',
      scientificName: map['Scientific Name'] ?? '',
      commonEnglishName: map['Common English Name'] ?? '',
      synonyms: map['Synonyms/Regional Names'] ?? '',
      family: map['Family'] ?? '',
      growthHabit: map['Growth Habit'] ?? '',
      keyVisualIdentifiers: map['Key Visual Identifiers'] ?? '',
      activePhytochemicals: map['Active Phytochemicals'] ?? '',
      coreBioactivity: map['Core Bioactivity'] ?? '',
      primaryIndications: map['Primary Indications'] ?? '',
      traditionalPreparationMethods: map['Traditional Preparation Methods'] ?? '',
      standardDosage: map['Standard Dosage'] ?? '',
      safeVehicle: map['Safe Vehicle/Anupana'] ?? '',
      toxicityProfile: map['Toxicity Profile'] ?? '',
      contraindications: map['Contraindications'] ?? '',
      adverseReactions: map['Adverse Reactions'] ?? '',
    );
  }

  Map<String, String> toMap() {
    return {
      'Local Name': localName,
      'Scientific Name': scientificName,
      'Common English Name': commonEnglishName,
      'Synonyms/Regional Names': synonyms,
      'Family': family,
      'Growth Habit': growthHabit,
      'Key Visual Identifiers': keyVisualIdentifiers,
      'Active Phytochemicals': activePhytochemicals,
      'Core Bioactivity': coreBioactivity,
      'Primary Indications': primaryIndications,
      'Traditional Preparation Methods': traditionalPreparationMethods,
      'Standard Dosage': standardDosage,
      'Safe Vehicle/Anupana': safeVehicle,
      'Toxicity Profile': toxicityProfile,
      'Contraindications': contraindications,
      'Adverse Reactions': adverseReactions,
    };
  }

  bool get isHighRisk {
    final tox = toxicityProfile.toLowerCase();
    return tox.contains('toxic') ||
        tox.contains('blindness') ||
        tox.contains('cardiotoxic') ||
        tox.contains('severe') ||
        tox.contains('fatal');
  }

  String get formattedContext {
    return '''
=== KNOWLEDGE BASE RECORD FOR: $localName ===
- Local Name: $localName
- Scientific Name: $scientificName
- Common English Name: $commonEnglishName
- Synonyms: $synonyms
- Family: $family
- Growth Habit: $growthHabit
- Key Visual Identifiers: $keyVisualIdentifiers
- Active Phytochemicals: $activePhytochemicals
- Core Bioactivity: $coreBioactivity
- Primary Indications: $primaryIndications
- Traditional Preparation: $traditionalPreparationMethods
- Standard Dosage: $standardDosage
- Safe Vehicle (Anupana): $safeVehicle
- Toxicity Profile: $toxicityProfile
- Contraindications: $contraindications
- Adverse Reactions: $adverseReactions
==================================================
''';
  }
}
