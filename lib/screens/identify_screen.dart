import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import '../services/rag_service.dart';
import '../services/onnx_service.dart';
import '../widgets/neu_widgets.dart';

/// Custom scroll behavior that enables mouse drag on web/desktop.
class _WebDragScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

class IdentifyScreen extends StatefulWidget {
  final RagService ragService;
  final Function(String) onPlantIdentified;

  const IdentifyScreen({
    super.key,
    required this.ragService,
    required this.onPlantIdentified,
  });

  @override
  State<IdentifyScreen> createState() => _IdentifyScreenState();
}

class _IdentifyScreenState extends State<IdentifyScreen>
    with AutomaticKeepAliveClientMixin {
  LocalPredictionResult? _efficientnetResult;
  LocalPredictionResult? _mobilenetResult;
  LocalPredictionResult? _inceptionResult;
  String _activeModelForRag = "EfficientNetV2";
  bool _showGradCamOverlay = false;

  @override
  bool get wantKeepAlive => true;

  final Map<String, bool> _expandedCards = {
    "EfficientNetV2-B2": false,
    "MobileNetV2": false,
    "InceptionV3": false,
  };

  bool _isPredicting = false;
  bool _isLoadingReport = false;
  String? _ragReportText;
  String? _selectedPlantName;

  final ImagePicker _imagePicker = ImagePicker();
  final OnnxService _onnxService = OnnxService();
  XFile? _pickedImageFile;

  @override
  void initState() {
    super.initState();
    _onnxService.initialize();
  }

  void _clearAll() {
    setState(() {
      _pickedImageFile = null;
      _efficientnetResult = null;
      _mobilenetResult = null;
      _inceptionResult = null;
      _selectedPlantName = null;
      _ragReportText = null;
      _isLoadingReport = false;
      _isPredicting = false;
      _showGradCamOverlay = false;
    });
  }

  void _generateReportForSelectedPlant() async {
    final activeResult = _currentActiveResult;
    final plantName = _selectedPlantName ?? activeResult?.predictedSpecies;
    if (plantName == null || plantName.isEmpty) return;

    setState(() {
      _selectedPlantName = plantName;
      _isLoadingReport = true;
      _ragReportText = null;
    });

    widget.onPlantIdentified(plantName);
    final report = await widget.ragService.generateRagReport(plantName);

    if (mounted) {
      setState(() {
        _ragReportText = report;
        _isLoadingReport = false;
      });
    }
  }

  Future<void> _pickLeafImage(ImageSource source) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (picked != null) {
        final Uint8List imageBytes = await picked.readAsBytes();

        setState(() {
          _pickedImageFile = picked;
          _isPredicting = true;
          _efficientnetResult = null;
          _mobilenetResult = null;
          _inceptionResult = null;
          _selectedPlantName = null;
          _ragReportText = null;
        });

        try {
          final results = await _onnxService.predictAll(imageBytes);

          if (mounted) {
            setState(() {
              _efficientnetResult = results["EfficientNetV2"];
              _mobilenetResult = results["MobileNetV2"];
              _inceptionResult = results["InceptionV3"];
              _isPredicting = false;

              LocalPredictionResult? activeResult;
              if (_activeModelForRag == "EfficientNetV2") {
                activeResult = _efficientnetResult;
              } else if (_activeModelForRag == "InceptionV3") {
                activeResult = _inceptionResult;
              } else {
                activeResult = _mobilenetResult;
              }
              activeResult ??= _efficientnetResult ?? _mobilenetResult ?? _inceptionResult;
              _selectedPlantName = activeResult?.predictedSpecies;
              _ragReportText = null;
              _isLoadingReport = false;
            });
          }
        } catch (inferenceError) {
          if (mounted) {
            setState(() => _isPredicting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                duration: const Duration(seconds: 8),
                backgroundColor: Colors.red.shade800,
                content: Text(
                  "Model inference failed: $inferenceError",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
          }
        }
      }
    } on MissingPluginException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please perform a full app restart to register camera/gallery channels.")),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPredicting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error selecting image: $e")),
        );
      }
    }
  }

  LocalPredictionResult? get _currentActiveResult {
    if (_activeModelForRag == "EfficientNetV2") return _efficientnetResult;
    if (_activeModelForRag == "InceptionV3") return _inceptionResult;
    return _mobilenetResult;
  }

  // ─── Neumorphic Model Card ─────────────────────────────────────────────

  Widget _buildModelCard({
    required String modelTitle,
    required LocalPredictionResult? result,
    required bool isActive,
    required VoidCallback onTapSelect,
    bool isTopWinner = false,
  }) {
    final bool isExpanded = _expandedCards[modelTitle] ?? false;
    final primary = NeuTheme.primaryColor(context);
    final onSurf = NeuTheme.onSurface(context);
    final subtle = NeuTheme.subtleText(context);

    return GestureDetector(
      onTap: result != null ? onTapSelect : null,
      child: NeuContainer(
        isPressed: isActive,
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.all(16),
        borderRadius: 22,
        blurRadius: isActive ? 12 : 16,
        offset: const Offset(5, 5),
        child: SizedBox(
          width: 270,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    isTopWinner ? Icons.emoji_events : Icons.smart_toy_outlined,
                    color: isTopWinner ? Colors.amber.shade700 : (isActive ? primary : subtle),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      modelTitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: onSurf,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isActive)
                    Icon(Icons.check_circle, color: primary, size: 20),
                ],
              ),
              const SizedBox(height: 14),

              if (result != null) ...[
                // Species & Confidence
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Top Prediction", style: TextStyle(fontSize: 11, color: subtle)),
                          const SizedBox(height: 2),
                          Text(
                            result.predictedSpecies,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isTopWinner ? const Color(0xFF2E7D32) : primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    NeuContainer(
                      isPressed: true,
                      borderRadius: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      blurRadius: 6,
                      offset: const Offset(2, 2),
                      child: Text(
                        "${result.confidence.toStringAsFixed(1)}%",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Top 3 Toggle
                GestureDetector(
                  onTap: () => setState(() => _expandedCards[modelTitle] = !isExpanded),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Top 3 Candidates",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: subtle),
                      ),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 20,
                        color: subtle,
                      ),
                    ],
                  ),
                ),

                if (isExpanded) ...[
                  const SizedBox(height: 8),
                  ...result.top3Candidates.asMap().entries.map((entry) {
                    int idx = entry.key;
                    var cand = entry.value;
                    String rankEmoji = idx == 0 ? "🥇" : (idx == 1 ? "🥈" : "🥉");
                    double conf = (cand['confidence'] as num).toDouble();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "$rankEmoji ${cand['species']}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: idx == 0 ? FontWeight.bold : FontWeight.normal,
                                    color: onSurf,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                "${conf.toStringAsFixed(1)}%",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: subtle),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (conf / 100).clamp(0.0, 1.0),
                              minHeight: 4,
                              backgroundColor: NeuTheme.shadowDark(context).withValues(alpha: 0.15),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                idx == 0 ? primary : subtle.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── Image Card ────────────────────────────────────────────────────────

  Widget _buildImageCard(List<List<double>>? camGrid) {
    final primary = NeuTheme.primaryColor(context);
    final onSurf = NeuTheme.onSurface(context);
    final hasSelection = _pickedImageFile != null || _selectedPlantName != null;

    return NeuContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Capture / Select Leaf",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: onSurf),
                ),
              ),
              if (hasSelection)
                NeuIconButton(
                  icon: Icons.refresh,
                  onPressed: _clearAll,
                  iconColor: Colors.redAccent,
                  tooltip: "Clear Screen",
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: NeuButton(
                  onPressed: () => _pickLeafImage(ImageSource.camera),
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 20, color: primary),
                      const SizedBox(width: 8),
                      Text(
                        "Take Photo",
                        style: TextStyle(fontWeight: FontWeight.w600, color: onSurf, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: NeuButton(
                  onPressed: () => _pickLeafImage(ImageSource.gallery),
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library, size: 20, color: primary),
                      const SizedBox(width: 8),
                      Text(
                        "Gallery",
                        style: TextStyle(fontWeight: FontWeight.w600, color: onSurf, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (_pickedImageFile != null) ...[
            const SizedBox(height: 18),

            // Image + Grad-CAM Overlay
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  kIsWeb
                      ? Image.network(
                          _pickedImageFile!.path,
                          height: 260,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(_pickedImageFile!.path),
                          height: 260,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                  if (_showGradCamOverlay && camGrid != null)
                    Positioned.fill(
                      child: CustomPaint(painter: GradCamHeatmapPainter(grid: camGrid)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Grad-CAM Toggle
            NeuButton(
              onPressed: camGrid != null
                  ? () => setState(() => _showGradCamOverlay = !_showGradCamOverlay)
                  : null,
              borderRadius: 14,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: _showGradCamOverlay
                  ? Colors.deepOrange.shade100.withValues(alpha: 0.3)
                  : null,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _showGradCamOverlay ? Icons.visibility_off : Icons.remove_red_eye,
                      size: 18,
                      color: _showGradCamOverlay ? Colors.deepOrange.shade700 : primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _showGradCamOverlay
                          ? "Hide Grad-CAM Heatmap"
                          : "Show Grad-CAM ($_activeModelForRag)",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: _showGradCamOverlay ? Colors.deepOrange.shade700 : NeuTheme.onSurface(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Predictions Section ───────────────────────────────────────────────

  Widget _buildPredictionResultsSection() {
    final primary = NeuTheme.primaryColor(context);
    final onSurf = NeuTheme.onSurface(context);
    final subtle = NeuTheme.subtleText(context);

    if (_isPredicting) {
      return NeuContainer(
        padding: const EdgeInsets.all(28),
        borderRadius: 24,
        child: Column(
          children: [
            CircularProgressIndicator(color: primary),
            const SizedBox(height: 14),
            Text(
              "Running model inference & feature extraction...",
              style: TextStyle(color: subtle, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_efficientnetResult == null && _mobilenetResult == null && _inceptionResult == null) {
      return NeuContainer(
        padding: const EdgeInsets.all(28),
        borderRadius: 24,
        child: Column(
          children: [
            Icon(Icons.image_search, size: 48, color: primary.withValues(alpha: 0.5)),
            const SizedBox(height: 14),
            Text(
              "No Leaf Selected",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: onSurf),
            ),
            const SizedBox(height: 8),
            Text(
              "Capture or select a leaf image to compare AI model predictions and Grad-CAM attention heatmaps.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: subtle, height: 1.4),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "⚖️ Model Predictions",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: primary),
        ),
        const SizedBox(height: 14),

        // Horizontal Model Cards — scrollable with mouse drag on web
        ScrollConfiguration(
          behavior: _WebDragScrollBehavior(),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildModelCard(
                  modelTitle: "EfficientNetV2-B2",
                  result: _efficientnetResult,
                  isActive: _activeModelForRag == "EfficientNetV2",
                  isTopWinner: true,
                  onTapSelect: () => setState(() {
                    _activeModelForRag = "EfficientNetV2";
                    _selectedPlantName = _efficientnetResult?.predictedSpecies;
                    _ragReportText = null;
                    _isLoadingReport = false;
                  }),
                ),
                _buildModelCard(
                  modelTitle: "MobileNetV2",
                  result: _mobilenetResult,
                  isActive: _activeModelForRag == "MobileNetV2",
                  onTapSelect: () => setState(() {
                    _activeModelForRag = "MobileNetV2";
                    _selectedPlantName = _mobilenetResult?.predictedSpecies;
                    _ragReportText = null;
                    _isLoadingReport = false;
                  }),
                ),
                _buildModelCard(
                  modelTitle: "InceptionV3",
                  result: _inceptionResult,
                  isActive: _activeModelForRag == "InceptionV3",
                  onTapSelect: () => setState(() {
                    _activeModelForRag = "InceptionV3";
                    _selectedPlantName = _inceptionResult?.predictedSpecies;
                    _ragReportText = null;
                    _isLoadingReport = false;
                  }),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),

        // Report Section
        NeuContainer(
          padding: const EdgeInsets.all(18),
          borderRadius: 22,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.local_pharmacy, color: primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Selected: ${_selectedPlantName ?? 'Unknown'}",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              NeuButton(
                onPressed: _isLoadingReport ? null : _generateReportForSelectedPlant,
                borderRadius: 14,
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.menu_book, size: 18, color: primary),
                    const SizedBox(width: 8),
                    Text(
                      _ragReportText != null
                          ? "Re-Generate Report"
                          : "📄 Generate Pharmacological Report",
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: onSurf),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Loading or Report Display
        if (_isLoadingReport)
          NeuContainer(
            isPressed: true,
            padding: const EdgeInsets.all(24),
            borderRadius: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: primary)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    "Generating report for $_selectedPlantName...",
                    style: TextStyle(color: subtle, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          )
        else if (_ragReportText != null)
          NeuContainer(
            padding: const EdgeInsets.all(22),
            borderRadius: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified, color: primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Pharmacological Profile: $_selectedPlantName",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: primary),
                      ),
                    ),
                  ],
                ),
                Divider(height: 24, color: NeuTheme.shadowDark(context).withValues(alpha: 0.2)),
                MarkdownBody(
                  data: _ragReportText!,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                    p: TextStyle(height: 1.55, fontSize: 14, color: onSurf),
                    h1: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: primary),
                    h2: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: primary),
                    h3: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primary),
                    strong: TextStyle(fontWeight: FontWeight.bold, color: onSurf),
                    listBullet: TextStyle(fontWeight: FontWeight.bold, color: primary),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final activeResult = _currentActiveResult;
    final camGrid = activeResult?.camGrid;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTwoColumn = screenWidth >= 950;
    final primary = NeuTheme.primaryColor(context);
    final onSurf = NeuTheme.onSurface(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner
              NeuContainer(
                isPressed: true,
                borderRadius: 22,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                blurRadius: 10,
                offset: const Offset(3, 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.energy_savings_leaf, color: primary, size: 24),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        "Medicinal Leaf Identifier & AI Pharmacologist",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: onSurf),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2-Column (wide) or Single-Column (mobile)
              if (isTwoColumn)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: _buildImageCard(camGrid)),
                    const SizedBox(width: 18),
                    Expanded(flex: 7, child: _buildPredictionResultsSection()),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildImageCard(camGrid),
                    const SizedBox(height: 18),
                    _buildPredictionResultsSection(),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Smooth Bilinear Interpolated Grad-CAM CustomPainter ────────────────────

class GradCamHeatmapPainter extends CustomPainter {
  final List<List<double>> grid;
  final double opacity;

  GradCamHeatmapPainter({required this.grid, this.opacity = 0.55});

  Color _getJetColor(double v) {
    v = v.clamp(0.0, 1.0);
    double r = (1.5 - (v - 0.75).abs() * 4).clamp(0.0, 1.0);
    double g = (1.5 - (v - 0.50).abs() * 4).clamp(0.0, 1.0);
    double b = (1.5 - (v - 0.25).abs() * 4).clamp(0.0, 1.0);
    return Color.fromRGBO((r * 255).round(), (g * 255).round(), (b * 255).round(), opacity);
  }

  double _sampleBilinear(double gx, double gy, int rows, int cols) {
    int x0 = gx.floor().clamp(0, cols - 1);
    int x1 = (x0 + 1).clamp(0, cols - 1);
    int y0 = gy.floor().clamp(0, rows - 1);
    int y1 = (y0 + 1).clamp(0, rows - 1);
    double dx = gx - x0;
    double dy = gy - y0;
    double top = grid[y0][x0] * (1 - dx) + grid[y0][x1] * dx;
    double bottom = grid[y1][x0] * (1 - dx) + grid[y1][x1] * dx;
    return top * (1 - dy) + bottom * dy;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (grid.isEmpty || grid[0].isEmpty) return;
    final int rows = grid.length;
    final int cols = grid[0].length;
    const int subStepsX = 48;
    const int subStepsY = 48;
    final double stepW = size.width / subStepsX;
    final double stepH = size.height / subStepsY;

    for (int sy = 0; sy < subStepsY; sy++) {
      for (int sx = 0; sx < subStepsX; sx++) {
        double gy = (sy + 0.5) / subStepsY * (rows - 1);
        double gx = (sx + 0.5) / subStepsX * (cols - 1);
        double val = _sampleBilinear(gx, gy, rows, cols);
        if (val <= 0.05) continue;

        final paint = Paint()
          ..color = _getJetColor(val)
          ..style = PaintingStyle.fill;

        canvas.drawRect(
          Rect.fromLTWH(sx * stepW, sy * stepH, stepW + 0.6, stepH + 0.6),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant GradCamHeatmapPainter oldDelegate) =>
      oldDelegate.grid != grid || oldDelegate.opacity != opacity;
}
