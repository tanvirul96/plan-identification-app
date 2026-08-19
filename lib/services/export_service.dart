import 'package:flutter/services.dart';

class ExportService {
  static Future<bool> copyToClipboard(String content) async {
    try {
      await Clipboard.setData(ClipboardData(text: content));
      return true;
    } catch (_) {
      return false;
    }
  }

  static String formatForSharing({
    required String title,
    required String plantName,
    required String content,
    String? author,
  }) {
    final timestamp = DateTime.now().toString().split('.')[0];
    return '''
==================================================
🌿 $title
Plant: $plantName
Generated: $timestamp
Application: Medicinal Plant Identification & RAG Assistant
==================================================

$content

==================================================
Clinical Advisory: Grounded in verified botanical literature. Consult a registered herbal/medical practitioner before starting treatment.
==================================================
''';
  }
}
