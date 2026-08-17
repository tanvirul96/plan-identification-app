import 'package:flutter/foundation.dart';
import 'onnx_service_models.dart';

import 'onnx_service_web.dart'
    if (dart.library.ffi) 'onnx_service_ffi.dart';

export 'onnx_service_models.dart';

class OnnxService {
  final OnnxServiceImpl _impl = OnnxServiceImpl();

  static List<String> get classNames => OnnxServiceImpl.classNames;
  static String formatDisplayName(String rawName) =>
      OnnxServiceImpl.formatDisplayName(rawName);

  Future<void> initialize() => _impl.initialize();

  Future<Map<String, LocalPredictionResult>> predictAll(
          Uint8List imageBytes) =>
      _impl.predictAll(imageBytes);

  Future<Map<String, LocalPredictionResult>> predictBoth(
          Uint8List imageBytes) =>
      _impl.predictBoth(imageBytes);

  Future<LocalPredictionResult> predict(
    Uint8List imageBytes, {
    String modelName = 'EfficientNetV2',
  }) =>
      _impl.predict(imageBytes, modelName: modelName);
}
