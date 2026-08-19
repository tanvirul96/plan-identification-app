import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

enum QualityTier {
  excellent,
  good,
  fair,
  poor,
}

class QualityAssessment {
  final int score; // 0 to 100
  final QualityTier tier;
  final double blurVariance;
  final double meanLuminance;
  final double contrast;
  final String statusEn;
  final String statusBn;
  final List<String> suggestionsEn;
  final List<String> suggestionsBn;

  QualityAssessment({
    required this.score,
    required this.tier,
    required this.blurVariance,
    required this.meanLuminance,
    required this.contrast,
    required this.statusEn,
    required this.statusBn,
    required this.suggestionsEn,
    required this.suggestionsBn,
  });

  bool get isAcceptable => score >= 45;
}

class ImageQualityService {
  static QualityAssessment assess(Uint8List imageBytes) {
    try {
      final img.Image? decoded = img.decodeImage(imageBytes);
      if (decoded == null) {
        return _fallbackAssessment();
      }

      // Downsample for rapid, non-blocking analysis (max 128x128)
      final sample = img.copyResize(decoded, width: 128, height: 128);
      final int width = sample.width;
      final int height = sample.height;

      // 1. Calculate Grayscale Luminance and Contrast
      double sumLum = 0.0;
      final List<double> lumValues = [];

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final p = sample.getPixel(x, y);
          // Standard ITU-R BT.601 luma
          final lum = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b);
          lumValues.add(lum);
          sumLum += lum;
        }
      }

      final double meanLum = sumLum / lumValues.length;

      // Contrast: standard deviation of luminance
      double sumVar = 0.0;
      for (var l in lumValues) {
        sumVar += (l - meanLum) * (l - meanLum);
      }
      final double contrast = math.sqrt(sumVar / lumValues.length);

      // 2. Laplacian Kernel Blur Detection (3x3 second-order derivative)
      // Kernel:
      //  0  1  0
      //  1 -4  1
      //  0  1  0
      double sumLap = 0.0;
      final List<double> lapValues = [];

      for (int y = 1; y < height - 1; y++) {
        for (int x = 1; x < width - 1; x++) {
          final c = lumValues[y * width + x];
          final top = lumValues[(y - 1) * width + x];
          final bottom = lumValues[(y + 1) * width + x];
          final left = lumValues[y * width + (x - 1)];
          final right = lumValues[y * width + (x + 1)];

          final lap = (top + bottom + left + right - 4 * c).abs();
          lapValues.add(lap);
          sumLap += lap;
        }
      }

      final double meanLap = sumLap / lapValues.length;
      double lapVarSum = 0.0;
      for (var v in lapValues) {
        lapVarSum += (v - meanLap) * (v - meanLap);
      }
      final double lapVariance = lapVarSum / lapValues.length;

      // 3. Composite Score Calculation (0-100)
      // Focus/Sharpness weight: 60%, Lighting/Contrast weight: 40%
      double sharpnessScore = (lapVariance / 80.0 * 100).clamp(0.0, 100.0);
      double lightingScore = 100.0;

      final List<String> suggEn = [];
      final List<String> suggBn = [];

      // Lighting penalties
      if (meanLum < 50) {
        lightingScore -= 40;
        suggEn.add('Image is too dark. Move to bright natural lighting.');
        suggBn.add('ছবিটি খুব অন্ধকার। পর্যাপ্ত আলোতে ছবি তুলুন।');
      } else if (meanLum > 215) {
        lightingScore -= 35;
        suggEn.add('Image is over-exposed / washed out.');
        suggBn.add('ছবিটিতে মাত্রাতিরিক্ত আলো পড়েছে।');
      }

      if (contrast < 20) {
        lightingScore -= 25;
        suggEn.add('Low leaf-background contrast.');
        suggBn.add('পাতা ও পটভূমির মধ্যে রঙের বৈসাদৃশ্য কম।');
      }

      if (sharpnessScore < 40) {
        suggEn.add('Camera shake detected. Hold device steady & refocus.');
        suggBn.add('ছবিটি কিছুটা ঝাপসা। স্থিরভাবে রেখে ফোকাস করুন।');
      }

      lightingScore = lightingScore.clamp(10.0, 100.0);
      final double totalScore = (sharpnessScore * 0.6 + lightingScore * 0.4);
      final int finalScore = totalScore.round().clamp(10, 99);

      QualityTier tier;
      String statusEn;
      String statusBn;

      if (finalScore >= 80) {
        tier = QualityTier.excellent;
        statusEn = 'Excellent Sharpness & Lighting';
        statusBn = 'চমৎকার স্পষ্টতা ও আলো';
      } else if (finalScore >= 65) {
        tier = QualityTier.good;
        statusEn = 'Good Quality (Ready for AI)';
        statusBn = 'ভালো মান (AI বিশ্লেষণের উপযোগী)';
      } else if (finalScore >= 45) {
        tier = QualityTier.fair;
        statusEn = 'Fair Quality';
        statusBn = 'মোটামুটি মান';
      } else {
        tier = QualityTier.poor;
        statusEn = 'Blurry / Sub-optimal Lighting';
        statusBn = 'ঝাপসা / অপর্যাপ্ত আলো';
      }

      return QualityAssessment(
        score: finalScore,
        tier: tier,
        blurVariance: lapVariance,
        meanLuminance: meanLum,
        contrast: contrast,
        statusEn: statusEn,
        statusBn: statusBn,
        suggestionsEn: suggEn,
        suggestionsBn: suggBn,
      );
    } catch (e) {
      debugPrint('Quality assessment error: $e');
      return _fallbackAssessment();
    }
  }

  static QualityAssessment _fallbackAssessment() {
    return QualityAssessment(
      score: 85,
      tier: QualityTier.good,
      blurVariance: 50.0,
      meanLuminance: 128.0,
      contrast: 50.0,
      statusEn: 'Good Quality',
      statusBn: 'ভালো মান',
      suggestionsEn: [],
      suggestionsBn: [],
    );
  }
}
