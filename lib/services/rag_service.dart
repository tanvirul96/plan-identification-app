import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/plant_model.dart';
import '../data/plant_dataset.dart';
import 'localization_service.dart';
import 'vector_search_service.dart';

class RagService {
  static const String defaultGeminiApiKey =
      "AIzaSyBo2SK47lQSMqTA9CPxb-hqM8xjjF_M_IE";

  String apiKey;
  List<PlantRecord> plants = [];
  final VectorSearchService vectorService = VectorSearchService();

  RagService({this.apiKey = defaultGeminiApiKey}) {
    plants = defaultPlantRecords;
    vectorService.buildIndex(plants);
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

  // Hybrid Search: Vector Cosine Similarity + Keyword Filter
  List<PlantRecord> searchKnowledgeBase(String query, {int topK = 3}) {
    if (query.trim().isEmpty) return plants.take(topK).toList();

    // 1. Vector Cosine Similarity Search
    final vectorResults = vectorService.search(query, topK: topK);
    return vectorResults.map((e) => e.plant).toList();
  }

  // Asynchronous REST Call to Google Gemini LLM API with Robust Multi-Model Fallback
  Future<String?> callGeminiApi(String prompt) async {
    final keyToUse = apiKey.isNotEmpty ? apiKey : defaultGeminiApiKey;

    // Active production Gemini candidate models in order of priority
    final candidateModels = [
      'gemini-2.5-flash-lite',
      'gemini-2.5-flash',
      'gemini-2.5-pro',
      'gemini-flash-latest',
      'gemini-3.5-flash',
      'gemini-1.5-flash',
    ];

    for (var model in candidateModels) {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$keyToUse',
      );

      try {
        final response = await http
            .post(
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
            )
            .timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'];
            final parts = content['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final text = parts[0]['text'].toString().trim();
              if (text.isNotEmpty) {
                return text;
              }
            }
          }
        } else if (response.statusCode == 429) {
          debugPrint('⚠️ Gemini model $model rate limit / quota exceeded, switching to next candidate...');
        }
      } catch (e) {
        debugPrint('⚠️ Gemini model $model error: $e, switching to next candidate...');
      }
    }
    return null; // Fallback directly to 100% offline local vector monograph
  }

  // Generate Pharmaceutical RAG Report (Online Gemini -> Seamless 100% Offline Vector Fallback)
  Future<String> generateRagReport(String plantName) async {
    final record = getPlantRecord(plantName);
    if (record == null) {
      return "⚠️ No knowledge base context found for '$plantName'.";
    }

    final isBn = LocalizationService().isBangla;

    final prompt = '''
You are an expert Botanical Pharmacologist & AI Medical Herbalist.
Language Requirement: ${isBn ? "Respond completely in Bengali (বাংলা)" : "Respond in English"}.
Below is authoritative domain context retrieved from our specialized knowledge base (`Medicinal Plants.csv`):

${record.formattedContext}

Generate a comprehensive, professional Pharmacological Profile for ${record.localName}.
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

    // 100% Offline Vector Semantic Monograph Fallback
    return vectorService.generateOfflineMonograph(record, isBangla: isBn);
  }

  // Answer Multi-turn RAG Chat Question with Fallback
  Future<String> answerRagChat({
    required String userQuery,
    required List<Map<String, String>> chatHistory,
    String? activePlant,
  }) async {
    final isBn = LocalizationService().isBangla;
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
      relevant = plants.take(3).toList();
    }

    final contextString = relevant.map((r) => r.formattedContext).join("\n---\n");

    final prompt = '''
You are a Botanical RAG Assistant specialized in medicinal plants.
Language: ${isBn ? "Bengali (বাংলা)" : "English"}.
Below is domain context retrieved from our knowledge base (`Medicinal Plants.csv`):

$contextString

User Question: "$userQuery"

Synthesize a clear, accurate, concise answer strictly grounded in the retrieved context. Format key facts in bullet points.
''';

    final onlineResult = await callGeminiApi(prompt);
    if (onlineResult != null && onlineResult.isNotEmpty) {
      return onlineResult;
    }

    // Offline Vector RAG Answer Synthesis
    final topMatch = relevant.first;
    if (isBn) {
      return '''
### 🌿 ${topMatch.localName} সম্পর্কে তথ্য:
- **বৈজ্ঞানিক নাম:** *${topMatch.scientificName}* (${topMatch.family})
- **প্রধান ব্যবহার ও নিরাময়:** ${topMatch.primaryIndications}
- **সক্রিয় রাসায়নিক উপাদান:** ${topMatch.activePhytochemicals}
- **প্রস্তুতি ও মাত্রা:** ${topMatch.traditionalPreparationMethods} (মাত্রা: ${topMatch.standardDosage})
- **নিরাপত্তা ও সতর্কতা:** ${topMatch.toxicityProfile} (নিষেধ: ${topMatch.contraindications})
''';
    }

    return '''
### 🌿 Knowledge Base Summary for ${topMatch.localName}:
- **Scientific Name:** *${topMatch.scientificName}* (${topMatch.family})
- **Primary Indications:** ${topMatch.primaryIndications}
- **Active Phytochemicals:** ${topMatch.activePhytochemicals}
- **Traditional Preparation & Dosage:** ${topMatch.traditionalPreparationMethods} (Dosage: ${topMatch.standardDosage})
- **Toxicity & Safety:** ${topMatch.toxicityProfile} (Contraindications: ${topMatch.contraindications})
''';
  }
}
