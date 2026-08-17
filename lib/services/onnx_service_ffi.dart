import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';
import 'package:path_provider/path_provider.dart';
import 'onnx_service_models.dart';

class OnnxServiceImpl {
  static const List<String> classNames = [
    'Akondo',
    'Amloki',
    'Arjun',
    'Basok',
    'Bohera',
    'Devilbackbone',
    'Haritoki',
    'Jarmani Lata',
    'Joba',
    'Lemongrass',
    'Nayontara',
    'Neem',
    'Pathorkuchi',
    'Thankuni',
    'Tulsi',
    'Zenora',
  ];

  static const Map<String, String> displayNames = {
    'Devilbackbone': "Devil's Backbone",
  };

  OrtSession? _mobilenetSession;
  OrtSession? _inceptionSession;
  OrtSession? _efficientnetSession;
  bool _isInitialized = false;

  static String formatDisplayName(String rawName) {
    return displayNames[rawName] ?? rawName;
  }

  static const String _modelVersion = 'v4';

  Future<String> _extractAssetToFile(String assetPath) async {
    final dir = await getApplicationDocumentsDirectory();
    final rawName = assetPath.split('/').last;
    final baseName = rawName.replaceAll('.onnx', '');
    final stampedName = '${baseName}_$_modelVersion.onnx';
    final outFile = File('${dir.path}/$stampedName');

    final ByteData data = await rootBundle.load(assetPath);
    final Uint8List bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    if (!await outFile.exists() || await outFile.length() != bytes.length) {
      debugPrint(
          'Extracting asset $assetPath → ${outFile.path} (${(bytes.length / 1024 / 1024).toStringAsFixed(1)} MB)');
      await outFile.writeAsBytes(bytes, flush: true);
    } else {
      debugPrint('Asset already up-to-date: ${outFile.path}');
    }

    return outFile.path;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      OrtEnv.instance.init();
      final sessionOptions = OrtSessionOptions();

      // MobileNetV2
      try {
        final mbPath =
            await _extractAssetToFile('assets/models/mobilenet_v2_plants.onnx');
        _mobilenetSession = OrtSession.fromFile(File(mbPath), sessionOptions);
        debugPrint('✅ MobileNetV2 Dual ONNX Session loaded from file.');
      } catch (e, stack) {
        debugPrint('❌ MobileNetV2 ONNX Session Load Error: $e\n$stack');
      }

      // InceptionV3
      try {
        final incPath =
            await _extractAssetToFile('assets/models/inception_v3_plants.onnx');
        _inceptionSession = OrtSession.fromFile(File(incPath), sessionOptions);
        debugPrint('✅ InceptionV3 Dual ONNX Session loaded from file.');
      } catch (e, stack) {
        debugPrint('❌ InceptionV3 ONNX Session Load Error: $e\n$stack');
      }

      // EfficientNetV2-B2
      try {
        final effPath = await _extractAssetToFile(
            'assets/models/efficientnet_v2_b2_plants.onnx');
        _efficientnetSession = OrtSession.fromFile(File(effPath), sessionOptions);
        debugPrint('✅ EfficientNetV2 Dual ONNX Session loaded from file.');
      } catch (e, stack) {
        debugPrint('❌ EfficientNetV2 ONNX Session Load Error: $e\n$stack');
      }

      _isInitialized = true;
    } catch (e, stack) {
      debugPrint('❌ ONNX OrtEnv Initialization Error: $e\n$stack');
      _isInitialized = false;
    }
  }

  Future<Map<String, LocalPredictionResult>> predictAll(
      Uint8List imageBytes) async {
    if (!_isInitialized) await initialize();

    final efficientnetRes =
        await predict(imageBytes, modelName: 'EfficientNetV2');
    final mobilenetRes = await predict(imageBytes, modelName: 'MobileNetV2');
    final inceptionRes = await predict(imageBytes, modelName: 'InceptionV3');

    return {
      'EfficientNetV2': efficientnetRes,
      'MobileNetV2': mobilenetRes,
      'InceptionV3': inceptionRes,
    };
  }

  Future<Map<String, LocalPredictionResult>> predictBoth(
      Uint8List imageBytes) async {
    return predictAll(imageBytes);
  }

  Future<LocalPredictionResult> predict(
    Uint8List imageBytes, {
    String modelName = 'EfficientNetV2',
  }) async {
    if (!_isInitialized) await initialize();

    final nameLower = modelName.toLowerCase();
    final isInc = nameLower.contains('inception');
    final isEff = nameLower.contains('efficient');

    int targetSize = 224;
    OrtSession? activeSession = _mobilenetSession;
    String modelLabel = 'MobileNetV2';

    if (isEff) {
      targetSize = 260;
      activeSession = _efficientnetSession;
      modelLabel = 'EfficientNetV2';
    } else if (isInc) {
      targetSize = 299;
      activeSession = _inceptionSession;
      modelLabel = 'InceptionV3';
    }

    if (activeSession == null) {
      throw Exception(
          'ONNX session for $modelLabel is null — check initialization logs.');
    }

    final floatBuffer = await compute(
      _preprocessImage,
      _PreprocessArgs(imageBytes: imageBytes, targetSize: targetSize),
    );

    try {
      final Float32List tensorData = Float32List.fromList(floatBuffer);
      final inputTensor = OrtValueTensor.createTensorWithDataList(
        tensorData,
        [1, 3, targetSize, targetSize],
      );
      final runOptions = OrtRunOptions();
      final outputs = activeSession.run(runOptions, {'input': inputTensor});

      inputTensor.release();
      runOptions.release();

      final outputTensor = outputs[0];
      final List<dynamic> rawLogits = outputTensor?.value as List<dynamic>;
      final List<double> logits = rawLogits[0].cast<double>();

      final double maxLogit = logits.reduce(math.max);
      final List<double> expScores =
          logits.map((l) => math.exp(l - maxLogit)).toList();
      final double sumExp = expScores.reduce((a, b) => a + b);
      final List<double> probs = expScores.map((e) => e / sumExp).toList();

      final List<Map<String, dynamic>> indexedProbs = [
        for (int i = 0; i < probs.length; i++)
          {
            'species': formatDisplayName(classNames[i % classNames.length]),
            'confidence': probs[i] * 100,
          }
      ]..sort((a, b) =>
          (b['confidence'] as double).compareTo(a['confidence'] as double));

      List<List<double>>? camGrid;
      if (outputs.length > 1 && outputs[1] != null) {
        try {
          camGrid = _extractCamGrid(outputs[1] as OrtValueTensor);
        } catch (e) {
          debugPrint('Notice extracting CAM grid: $e');
        }
      }

      return LocalPredictionResult(
        modelName: modelLabel,
        predictedSpecies: indexedProbs[0]['species'] as String,
        confidence: indexedProbs[0]['confidence'] as double,
        top3Candidates: indexedProbs.take(3).toList(),
        camGrid: camGrid,
      );
    } catch (e, stack) {
      debugPrint('❌ ONNX Inference Error [$modelLabel]: $e\n$stack');
      rethrow;
    }
  }

  List<List<double>> _extractCamGrid(OrtValueTensor featTensor) {
    final List<dynamic> rawFeat = featTensor.value as List<dynamic>;
    final List<dynamic> channels = rawFeat[0] as List<dynamic>;
    final int numChannels = channels.length;
    final int h = (channels[0] as List<dynamic>).length;
    final int w = (channels[0][0] as List<dynamic>).length;

    List<List<double>> grid = List.generate(h, (_) => List.filled(w, 0.0));

    double maxVal = 0.0;
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        double sum = 0.0;
        for (int c = 0; c < numChannels; c++) {
          final double val = (channels[c][y][x] as num).toDouble();
          sum += val > 0 ? val : 0;
        }
        double avg = sum / numChannels;
        grid[y][x] = avg;
        if (avg > maxVal) maxVal = avg;
      }
    }

    if (h > 4 && w > 4) {
      for (int x = 0; x < w; x++) {
        grid[0][x] = math.min(grid[0][x], grid[1][x]);
        grid[h - 1][x] = math.min(grid[h - 1][x], grid[h - 2][x]);
      }
      for (int y = 0; y < h; y++) {
        grid[y][0] = math.min(grid[y][0], grid[y][1]);
        grid[y][w - 1] = math.min(grid[y][w - 1], grid[y][w - 2]);
      }
    }

    maxVal = 0.0;
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        if (grid[y][x] > maxVal) maxVal = grid[y][x];
      }
    }

    if (maxVal > 0) {
      for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
          grid[y][x] = (grid[y][x] / maxVal).clamp(0.0, 1.0);
        }
      }
    }

    return grid;
  }
}

class _PreprocessArgs {
  final Uint8List imageBytes;
  final int targetSize;
  const _PreprocessArgs({required this.imageBytes, required this.targetSize});
}

List<double> _preprocessImage(_PreprocessArgs args) {
  final img.Image? decoded = img.decodeImage(args.imageBytes);
  if (decoded == null) throw Exception('Could not decode image bytes.');

  final img.Image resized = img.copyResize(
    decoded,
    width: args.targetSize,
    height: args.targetSize,
    interpolation: img.Interpolation.linear,
  );

  const mean = [0.485, 0.456, 0.406];
  const std = [0.229, 0.224, 0.225];
  final int planeSize = args.targetSize * args.targetSize;
  final List<double> nchw = List<double>.filled(3 * planeSize, 0.0);

  for (int y = 0; y < args.targetSize; y++) {
    for (int x = 0; x < args.targetSize; x++) {
      final pixel = resized.getPixel(x, y);
      final r = pixel.r / 255.0;
      final g = pixel.g / 255.0;
      final b = pixel.b / 255.0;

      final idx = y * args.targetSize + x;
      nchw[idx] = (r - mean[0]) / std[0];
      nchw[planeSize + idx] = (g - mean[1]) / std[1];
      nchw[2 * planeSize + idx] = (b - mean[2]) / std[2];
    }
  }

  return nchw;
}
