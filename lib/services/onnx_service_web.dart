import 'dart:convert';
import 'dart:js_interop';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'onnx_service_models.dart';

// ─── JS Interop Declarations ─────────────────────────────────────────────────
// These call functions defined in web/onnx_helper.js

@JS('initOnnxWeb')
external JSPromise<JSAny?> _jsInitOnnx();

@JS('loadOnnxModelFromBytes')
external JSPromise<JSAny?> _jsLoadModelFromBytes(
    JSString modelName, JSUint8Array modelBytes);

@JS('runOnnxInference')
external JSPromise<JSAny?> _jsRunInference(JSString modelName,
    JSFloat32Array floatData, JSNumber batch, JSNumber channels,
    JSNumber height, JSNumber width);

// ─── OnnxServiceImpl (Web — Local ONNX via WebAssembly) ──────────────────────

class OnnxServiceImpl {
  static const List<String> classNames = [
    'Akondo', 'Amloki', 'Arjun', 'Basok', 'Bohera',
    'Devilbackbone', 'Haritoki', 'Jarmani Lata', 'Joba',
    'Lemongrass', 'Nayontara', 'Neem', 'Pathorkuchi',
    'Thankuni', 'Tulsi', 'Zenora',
  ];

  static const Map<String, String> displayNames = {
    'Devilbackbone': "Devil's Backbone",
  };

  static String formatDisplayName(String rawName) =>
      displayNames[rawName] ?? rawName;

  bool _isInitialized = false;
  final Map<String, bool> _loadedModels = {};

  // Model config: session name → asset path + input size
  static const Map<String, Map<String, dynamic>> _modelConfigs = {
    'EfficientNetV2': {
      'asset': 'assets/models/efficientnet_v2_b2_plants.onnx',
      'size': 260,
    },
    'MobileNetV2': {
      'asset': 'assets/models/mobilenet_v2_plants.onnx',
      'size': 224,
    },
    'InceptionV3': {
      'asset': 'assets/models/inception_v3_plants.onnx',
      'size': 299,
    },
  };

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _jsInitOnnx().toDart;
      debugPrint('🌐 ONNX Runtime Web (WASM) initialized.');
    } catch (e) {
      debugPrint('❌ ONNX Runtime Web init failed: $e');
      return;
    }

    // Load models sequentially to minimize peak memory usage
    for (final entry in _modelConfigs.entries) {
      await _loadModelFromAsset(entry.key, entry.value['asset'] as String);
    }

    _isInitialized = true;
    debugPrint('✅ All ONNX models loaded in browser (WebAssembly).');
  }

  Future<void> _loadModelFromAsset(String modelName, String assetPath) async {
    try {
      debugPrint('⏳ Loading $modelName from asset: $assetPath ...');
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      await _jsLoadModelFromBytes(modelName.toJS, bytes.toJS).toDart;
      _loadedModels[modelName] = true;
      debugPrint('✅ $modelName loaded (${(bytes.length / 1024 / 1024).toStringAsFixed(1)} MB).');
    } catch (e) {
      _loadedModels[modelName] = false;
      debugPrint('❌ $modelName load failed: $e');
    }
  }

  Future<Map<String, LocalPredictionResult>> predictAll(
      Uint8List imageBytes) async {
    if (!_isInitialized) await initialize();

    final results = <String, LocalPredictionResult>{};

    for (final entry in _modelConfigs.entries) {
      final name = entry.key;
      if (_loadedModels[name] != true) continue;

      try {
        final result = await _runSingleModel(imageBytes, name);
        results[name] = result;
      } catch (e) {
        debugPrint('⚠️ $name inference failed: $e');
      }
    }

    if (results.isEmpty) {
      throw Exception(
          'No ONNX models available. Check browser console for loading errors.');
    }

    return results;
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
    return _runSingleModel(imageBytes, modelName);
  }

  Future<LocalPredictionResult> _runSingleModel(
      Uint8List imageBytes, String modelName) async {
    final config = _modelConfigs[modelName];
    if (config == null) throw Exception('Unknown model: $modelName');

    final targetSize = config['size'] as int;

    // Preprocess image: decode → resize → normalize → NCHW float tensor
    final floatData = _preprocessImage(imageBytes, targetSize);
    final jsFloatData = Float32List.fromList(floatData).toJS;

    // Run ONNX inference via JavaScript WebAssembly
    final jsResult = await _jsRunInference(
      modelName.toJS,
      jsFloatData,
      1.toJS, 3.toJS, targetSize.toJS, targetSize.toJS,
    ).toDart;

    // Parse JSON result from JS
    final resultStr = (jsResult! as JSString).toDart;
    final result = jsonDecode(resultStr) as Map<String, dynamic>;

    // Extract logits
    final logits = (result['logits'] as List)
        .map<double>((n) => (n as num).toDouble())
        .toList();

    // Softmax
    final double maxLogit = logits.reduce(math.max);
    final expScores = logits.map((l) => math.exp(l - maxLogit)).toList();
    final double sumExp = expScores.reduce((a, b) => a + b);
    final probs = expScores.map((e) => e / sumExp).toList();

    // Top-3 candidates
    final indexed = <Map<String, dynamic>>[
      for (int i = 0; i < probs.length; i++)
        {
          'species': formatDisplayName(classNames[i % classNames.length]),
          'confidence': probs[i] * 100,
        }
    ]..sort(
        (a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double));

    // Extract Grad-CAM feature map grid
    List<List<double>>? camGrid;
    if (result['featureMapData'] != null && result['featureMapDims'] != null) {
      try {
        camGrid = _extractCamGrid(
          (result['featureMapData'] as List).map<double>((n) => (n as num).toDouble()).toList(),
          (result['featureMapDims'] as List).map<int>((n) => (n as num).toInt()).toList(),
        );
      } catch (e) {
        debugPrint('Notice extracting CAM grid: $e');
      }
    }

    return LocalPredictionResult(
      modelName: modelName,
      predictedSpecies: indexed[0]['species'] as String,
      confidence: indexed[0]['confidence'] as double,
      top3Candidates: indexed.take(3).toList(),
      camGrid: camGrid,
    );
  }

  // ─── Image Preprocessing (same logic as FFI version) ───────────────────

  List<double> _preprocessImage(Uint8List imageBytes, int targetSize) {
    final img.Image? decoded = img.decodeImage(imageBytes);
    if (decoded == null) throw Exception('Could not decode image bytes.');

    final img.Image resized = img.copyResize(
      decoded,
      width: targetSize,
      height: targetSize,
      interpolation: img.Interpolation.linear,
    );

    const mean = [0.485, 0.456, 0.406];
    const std = [0.229, 0.224, 0.225];
    final int planeSize = targetSize * targetSize;
    final nchw = List<double>.filled(3 * planeSize, 0.0);

    for (int y = 0; y < targetSize; y++) {
      for (int x = 0; x < targetSize; x++) {
        final pixel = resized.getPixel(x, y);
        final r = pixel.r / 255.0;
        final g = pixel.g / 255.0;
        final b = pixel.b / 255.0;

        final idx = y * targetSize + x;
        nchw[idx] = (r - mean[0]) / std[0];
        nchw[planeSize + idx] = (g - mean[1]) / std[1];
        nchw[2 * planeSize + idx] = (b - mean[2]) / std[2];
      }
    }

    return nchw;
  }

  // ─── Grad-CAM Feature Map → 2D Grid ────────────────────────────────────

  List<List<double>> _extractCamGrid(List<double> flatData, List<int> dims) {
    // dims: [1, C, H, W]
    if (dims.length < 4) throw Exception('Invalid feature map dims: $dims');

    final int numChannels = dims[1];
    final int h = dims[2];
    final int w = dims[3];

    List<List<double>> grid = List.generate(h, (_) => List.filled(w, 0.0));

    double maxVal = 0.0;
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        double sum = 0.0;
        for (int c = 0; c < numChannels; c++) {
          final double val = flatData[c * h * w + y * w + x];
          sum += val > 0 ? val : 0; // ReLU
        }
        double avg = sum / numChannels;
        grid[y][x] = avg;
        if (avg > maxVal) maxVal = avg;
      }
    }

    // Suppress edges
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

    // Re-find max after edge suppression
    maxVal = 0.0;
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        if (grid[y][x] > maxVal) maxVal = grid[y][x];
      }
    }

    // Normalize to [0, 1]
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
