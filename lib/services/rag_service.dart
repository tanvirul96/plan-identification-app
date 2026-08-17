import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/plant_model.dart';
import '../data/plant_dataset.dart';

class RagService {
  static const String defaultGeminiApiKey =
      "AIzaSyBo2SK47lQSMqTA9CPxb-hqM8xjjF_M_IE";

  String apiKey;
  List<PlantRecord> plants = [];

  RagService({this.apiKey = defaultGeminiApiKey}) {
    plants = defaultPlantRecords;
  }

  // Name mapping helper
  String normalizeName(String name) {
    if (name.isEmpty) return "";
    final clean = name.trim().toLowerCase();
    if (clean == "devilbackbone" || clean.contains("devil")) {
      return "Devil's Backbone";
    }
    for (var p in plants) {
      if (p.localName.toLowerCase() == clean) return p.localName;
      if (p.localName.toLowerCase().contains(clean)) return p.localName;
    }
    return name;
  }

  PlantRecord? getPlantRecord(String name) {
    final norm = normalizeName(name);
    for (var p in plants) {
      if (p.localName.toLowerCase() == norm.toLowerCase()) return p;
    }
    return null;
  }

  // Weighted Field-Based Search Engine
  List<PlantRecord> searchKnowledgeBase(String query, {int topK = 3}) {
    if (query.trim().isEmpty) return plants.take(topK).toList();

    final terms = query.toLowerCase().split(RegExp(r'\s+'));
    final List<MapEntry<int, PlantRecord>> scored = [];

    for (var p in plants) {
      int score = 0;
      final loc = p.localName.toLowerCase();
      final sci = p.scientificName.toLowerCase();
      final eng = p.commonEnglishName.toLowerCase();
      final ind = p.primaryIndications.toLowerCase();
      final bio = p.coreBioactivity.toLowerCase();
      final phy = p.activePhytochemicals.toLowerCase();
      final prep = p.traditionalPreparationMethods.toLowerCase();
      final tox = p.toxicityProfile.toLowerCase();

      for (var t in terms) {
        if (t.length <= 2) continue;
        if (loc.contains(t) || sci.contains(t) || eng.contains(t)) {
          score += 10;
        } else if (ind.contains(t) || bio.contains(t)) {
          score += 7;
        } else if (phy.contains(t) || prep.contains(t)) {
          score += 5;
        } else if (tox.contains(t)) {
          score += 6;
        } else if (p.formattedContext.toLowerCase().contains(t)) {
          score += 2;
        }
      }
      if (score > 0) {
        scored.add(MapEntry(score, p));
      }
    }

    scored.sort((a, b) => b.key.compareTo(a.key));
    if (scored.isEmpty) {
      return plants.take(topK).toList();
    }
    return scored.take(topK).map((e) => e.value).toList();
  }

  // Asynchronous REST Call to Google Gemini LLM API with Fallback Chain
  Future<String?> callGeminiApi(String prompt) async {
    final keyToUse = apiKey.isNotEmpty ? apiKey : defaultGeminiApiKey;

    // Active production Gemini candidate models prioritized for speed and quota resilience
    final candidateModels = [
      'gemini-2.5-flash-lite',
      'gemini-2.5-flash',
      'gemini-2.5-pro',
      'gemini-flash-latest',
      'gemini-3.5-flash',
    ];

    for (var model in candidateModels) {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$keyToUse',
      );

      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "contents": [
              {
                "parts": [
                  {"text": prompt}
                ]
              }
            ]
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'];
            final parts = content['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              return parts[0]['text'].toString().trim();
            }
          }
        }
      } catch (_) {
        // Continue fallback chain to next model
      }
    }
    return null; // Fallback to local grounded knowledge base if all API calls fail
  }

  // Generate Grounded Local RAG Report (used as fallback)
  String generateLocalReportFallback(PlantRecord record) {
    final riskBadge = record.isHighRisk
        ? "🔴 HIGH TOXICITY / RESTRICTED USE"
        : "🟢 SAFE FOR GENERAL USE";

    return '''
### 🌿 1. Identification & Overview
- **Local Name:** ${record.localName}
- **Scientific Name:** *${record.scientificName}*
- **Common English Name:** ${record.commonEnglishName}
- **Synonyms / Regional:** ${record.synonyms}
- **Botanical Family:** ${record.family}
- **Growth Habit:** ${record.growthHabit}
- **Visual Key Identifiers:** ${record.keyVisualIdentifiers}

### 💊 2. Medicinal Uses & Therapeutic Benefits
- **Primary Indications:** ${record.primaryIndications}
- **Core Bioactivity:** ${record.coreBioactivity}

### 🧪 3. Active Phytochemicals & Pharmacology
- **Key Bioactive Compounds:** ${record.activePhytochemicals}

### ☕ 4. Traditional Preparation, Dosage & Vehicle
- **Preparation Methods:** ${record.traditionalPreparationMethods}
- **Standard Dosage:** ${record.standardDosage}
- **Safe Vehicle (Anupana):** ${record.safeVehicle}

### ⚠️ 5. Toxicity, Contraindications & Adverse Reactions
- **Toxicity Profile:** ${record.toxicityProfile}
- **Contraindications:** ${record.contraindications}
- **Adverse Reactions:** ${record.adverseReactions}
- **Safety Rating:** $riskBadge
''';
  }

  // Generate Pharmaceutical RAG Report
  Future<String> generateRagReport(String plantName) async {
    final record = getPlantRecord(plantName);
    if (record == null) {
      return "⚠️ No knowledge base context found for '$plantName'.";
    }

    final prompt = '''
You are an expert Botanical Pharmacologist & AI Medical Herbalist.
Below is authoritative domain context retrieved from our specialized knowledge base (`Medicinal Plants.csv`).

${record.formattedContext}

Generate a comprehensive, professional Pharmacological & Botanical Profile for ${record.localName}.
Structure your output using clear Markdown headings:
1. ### 🌿 1. Identification & Overview
2. ### 💊 2. Medicinal Uses & Therapeutic Benefits
3. ### 🧪 3. Active Phytochemicals & Pharmacology
4. ### ☕ 4. Traditional Preparation, Dosage & Vehicle
5. ### ⚠️ 5. Toxicity, Contraindications & Adverse Reactions

Strictly ground all facts in the provided context. Do not invent unverified claims.
''';

    final onlineResult = await callGeminiApi(prompt);
    if (onlineResult != null && onlineResult.isNotEmpty) {
      return onlineResult;
    }

    // Fallback directly to clean grounded local knowledge base report
    return generateLocalReportFallback(record);
  }

  // Answer Multi-turn RAG Chat Question with Fallback
  Future<String> answerRagChat({
    required String userQuery,
    required List<Map<String, String>> chatHistory,
    String? activePlant,
  }) async {
    List<PlantRecord> relevant = [];

    if (activePlant != null &&
        activePlant.isNotEmpty &&
        activePlant != "🌐 All 16 Medicinal Plants") {
      final rec = getPlantRecord(activePlant);
      if (rec != null) relevant.add(rec);
    }

    final searchResults = searchKnowledgeBase(userQuery, topK: 2);
    for (var r in searchResults) {
      if (!relevant.any((existing) => existing.localName == r.localName)) {
        relevant.add(r);
      }
    }

    if (relevant.isEmpty) {
      relevant = plants.take(4).toList();
    }

    final contextString = relevant.map((r) => r.formattedContext).join("\n---\n");

    final prompt = '''
You are a Botanical RAG Assistant specialized in medicinal plants.
Below is domain context retrieved from our knowledge base (`Medicinal Plants.csv`):

$contextString

User Question: "$userQuery"

Synthesize a clear, accurate, concise answer strictly grounded in the retrieved context. Format key facts in bullet points.
''';

    final onlineResult = await callGeminiApi(prompt);
    if (onlineResult != null && onlineResult.isNotEmpty) {
      return onlineResult;
    }

    // Grounded Local Chat Fallback without intrusive rate-limit banners
    final topMatch = relevant.first;
    return '''
### 🌿 Grounded Knowledge Answer for ${topMatch.localName}:
- **Scientific Name:** *${topMatch.scientificName}* (${topMatch.family})
- **Primary Indications:** ${topMatch.primaryIndications}
- **Active Phytochemicals:** ${topMatch.activePhytochemicals}
- **Traditional Preparation & Dosage:** ${topMatch.traditionalPreparationMethods} (Dosage: ${topMatch.standardDosage})
- **Toxicity & Safety:** ${topMatch.toxicityProfile} (Contraindications: ${topMatch.contraindications})
''';
  }
}
