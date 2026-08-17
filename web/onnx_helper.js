// ─── ONNX Runtime Web Helper ────────────────────────────────────────────────
// Provides local browser-based ONNX model inference using WebAssembly.
// Called from Flutter Dart via dart:js_interop.

var onnxSessions = {};

async function initOnnxWeb() {
  if (typeof ort === 'undefined') {
    console.error('❌ ONNX Runtime Web (ort) not loaded. Check index.html CDN script.');
    return false;
  }
  // Use single-threaded WASM to avoid needing SharedArrayBuffer CORS headers
  ort.env.wasm.numThreads = 1;
  console.log('✅ ONNX Runtime Web initialized (WASM single-thread)');
  return true;
}

async function loadOnnxModelFromBytes(modelName, modelBytes) {
  if (onnxSessions[modelName]) {
    console.log(`ℹ️ ${modelName} already loaded, skipping.`);
    return true;
  }

  try {
    console.log(`⏳ Loading ${modelName} (${(modelBytes.byteLength / 1024 / 1024).toFixed(1)} MB)...`);
    const session = await ort.InferenceSession.create(modelBytes.buffer, {
      executionProviders: ['wasm'],
    });
    onnxSessions[modelName] = session;
    console.log(`✅ ${modelName} loaded successfully.`);
    return true;
  } catch (e) {
    console.error(`❌ Failed to load ${modelName}:`, e);
    return false;
  }
}

async function runOnnxInference(modelName, floatData, batchSize, channels, height, width) {
  const session = onnxSessions[modelName];
  if (!session) {
    throw new Error(`Model ${modelName} not loaded. Call loadOnnxModelFromBytes first.`);
  }

  const tensor = new ort.Tensor('float32', floatData, [batchSize, channels, height, width]);
  const results = await session.run({ input: tensor });
  const outputNames = Object.keys(results);

  // First output: logits [1, numClasses]
  const logits = Array.from(results[outputNames[0]].data);

  // Second output (if exists): feature map [1, C, H, W]
  let featureMapData = null;
  let featureMapDims = null;
  if (outputNames.length > 1 && results[outputNames[1]]) {
    featureMapData = Array.from(results[outputNames[1]].data);
    featureMapDims = Array.from(results[outputNames[1]].dims);
  }

  return JSON.stringify({
    logits: logits,
    featureMapData: featureMapData,
    featureMapDims: featureMapDims,
  });
}
