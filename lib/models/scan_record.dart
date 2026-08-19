import 'dart:convert';

class ScanRecord {
  final String id;
  final DateTime timestamp;
  final String plantName;
  final double confidence;
  final String modelName;
  final String? imageBase64;
  final String? imagePath;
  final List<Map<String, dynamic>> top3Candidates;
  bool isBookmarked;
  String? userNotes;

  ScanRecord({
    required this.id,
    required this.timestamp,
    required this.plantName,
    required this.confidence,
    required this.modelName,
    this.imageBase64,
    this.imagePath,
    required this.top3Candidates,
    this.isBookmarked = false,
    this.userNotes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'plantName': plantName,
      'confidence': confidence,
      'modelName': modelName,
      'imageBase64': imageBase64,
      'imagePath': imagePath,
      'top3Candidates': top3Candidates,
      'isBookmarked': isBookmarked,
      'userNotes': userNotes,
    };
  }

  factory ScanRecord.fromMap(Map<String, dynamic> map) {
    return ScanRecord(
      id: map['id'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      plantName: map['plantName'] ?? 'Unknown',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      modelName: map['modelName'] ?? 'EfficientNetV2',
      imageBase64: map['imageBase64'],
      imagePath: map['imagePath'],
      top3Candidates: (map['top3Candidates'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      isBookmarked: map['isBookmarked'] ?? false,
      userNotes: map['userNotes'],
    );
  }

  String toJson() => jsonEncode(toMap());
  factory ScanRecord.fromJson(String source) =>
      ScanRecord.fromMap(jsonDecode(source));
}
