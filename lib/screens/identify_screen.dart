import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import '../services/rag_service.dart';
import '../services/onnx_service.dart';

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

class _IdentifyScreenState extends State<IdentifyScreen> {
  LocalPredictionResult? _efficientnetResult;
  LocalPredictionResult? _mobilenetResult;
  LocalPredictionResult? _inceptionResult;
  String _activeModelForRag = "EfficientNetV2";
  bool _showGradCamOverlay = false;

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
          // Run ONNX inference on EfficientNetV2, MobileNetV2, and InceptionV3
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
            setState(() {
              _isPredicting = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                duration: const Duration(seconds: 8),
                backgroundColor: Colors.red.shade800,
                content: Text(
                  "ONNX inference failed: $inferenceError",
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
          const SnackBar(
            content: Text(
              "Please perform a full app restart ('flutter run') to register native camera/gallery channels.",
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPredicting = false;
        });
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

  Widget _buildHorizontalModelCard({
    required ThemeData theme,
    required String modelTitle,
    required LocalPredictionResult? result,
    required bool isActive,
    required VoidCallback onTapSelect,
    bool isTopWinner = false,
  }) {
    final bool isExpanded = _expandedCards[modelTitle] ?? false;

    return Container(
      width: 290,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: isActive ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isActive
                ? (isTopWinner ? Colors.green.shade600 : theme.colorScheme.primary)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: isActive ? 2.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: result != null ? onTapSelect : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      isTopWinner ? Icons.emoji_events : Icons.smart_toy,
                      color: isTopWinner
                          ? Colors.amber.shade700
                          : (isActive ? theme.colorScheme.primary : theme.colorScheme.outline),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        modelTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isActive)
                      Icon(
                        Icons.check_circle,
                        color: isTopWinner ? Colors.green.shade600 : theme.colorScheme.primary,
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                if (result != null) ...[
                  // Species & Confidence
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Top Prediction",
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              result.predictedSpecies,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isTopWinner ? Colors.green.shade800 : theme.colorScheme.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isTopWinner ? Colors.green.shade600 : theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${result.confidence.toStringAsFixed(1)}%",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isTopWinner ? Colors.white : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Dropdown button to toggle Top 3 Candidates
                  InkWell(
                    onTap: () {
                      setState(() {
                        _expandedCards[modelTitle] = !isExpanded;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Top 3 Candidates",
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Icon(
                            isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Expandable Top 3 Breakdown
                  if (isExpanded) ...[
                    const SizedBox(height: 6),
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
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: idx == 0 ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  "${conf.toStringAsFixed(1)}%",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (conf / 100).clamp(0.0, 1.0),
                                minHeight: 4,
                                backgroundColor: Colors.grey.withValues(alpha: 0.15),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  idx == 0
                                      ? (isTopWinner ? Colors.green.shade600 : theme.colorScheme.primary)
                                      : Colors.grey.shade400,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeResult = _currentActiveResult;
    final camGrid = activeResult?.camGrid;
    final hasSelection = _pickedImageFile != null || _selectedPlantName != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.energy_savings_leaf,
                  color: theme.colorScheme.primary,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Text(
                  "Medicinal Leaf Identifier",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Image Selection & Preview Section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Capture / Select Leaf Specimen",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // Clear Screen Button
                      if (hasSelection)
                        IconButton.filledTonal(
                          onPressed: _clearAll,
                          icon: const Icon(Icons.refresh, size: 20),
                          color: Colors.red.shade700,
                          tooltip: "Clear Screen",
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Take Photo & Pick Gallery Buttons in the SAME ROW
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _pickLeafImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt, size: 20),
                          label: const Text("Take Photo"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickLeafImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library, size: 20),
                          label: const Text("Pick Gallery"),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_pickedImageFile != null) ...[
                    const SizedBox(height: 16),

                    // Stack for Leaf Image + Smooth Grad-CAM Heatmap Overlay
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          kIsWeb
                              ? Image.network(
                                  _pickedImageFile!.path,
                                  height: 240,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(_pickedImageFile!.path),
                                  height: 240,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),

                          // Grad-CAM Smooth Heatmap Overlay
                          if (_showGradCamOverlay && camGrid != null)
                            Positioned.fill(
                              child: CustomPaint(
                                painter: GradCamHeatmapPainter(grid: camGrid),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Show / Hide Grad-CAM Toggle Button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: camGrid != null
                            ? () => setState(() => _showGradCamOverlay = !_showGradCamOverlay)
                            : null,
                        icon: Icon(
                          _showGradCamOverlay ? Icons.visibility_off : Icons.remove_red_eye,
                        ),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _showGradCamOverlay
                                ? "Hide Grad-CAM Heatmap"
                                : "Show Grad-CAM Heatmap ($_activeModelForRag)",
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: _showGradCamOverlay
                              ? Colors.deepOrange.shade700
                              : theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Placeholder when no image is picked
          if (_pickedImageFile == null && _selectedPlantName == null)
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.image_search,
                      size: 48,
                      color: theme.colorScheme.primary.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "No Leaf Selected",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Take a photo or select a gallery leaf image to compare predictions and visualize smooth Grad-CAM attention heatmaps.",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_isPredicting)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text("Executing ONNX model inference..."),
                  ],
                ),
              ),
            ),

          // Horizontal Model Cards Layout
          if (_efficientnetResult != null || _mobilenetResult != null || _inceptionResult != null) ...[
            Text(
              "⚖️ Model Predictions",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),

            // Horizontal Scroll View for Model Cards
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  // EfficientNetV2-B2 Card (Featured Winner)
                  _buildHorizontalModelCard(
                    theme: theme,
                    modelTitle: "EfficientNetV2-B2",
                    result: _efficientnetResult,
                    isActive: _activeModelForRag == "EfficientNetV2",
                    isTopWinner: true,
                    onTapSelect: () {
                      setState(() {
                        _activeModelForRag = "EfficientNetV2";
                        _selectedPlantName = _efficientnetResult?.predictedSpecies;
                        _ragReportText = null;
                        _isLoadingReport = false;
                      });
                    },
                  ),

                  // MobileNetV2 Card
                  _buildHorizontalModelCard(
                    theme: theme,
                    modelTitle: "MobileNetV2",
                    result: _mobilenetResult,
                    isActive: _activeModelForRag == "MobileNetV2",
                    onTapSelect: () {
                      setState(() {
                        _activeModelForRag = "MobileNetV2";
                        _selectedPlantName = _mobilenetResult?.predictedSpecies;
                        _ragReportText = null;
                        _isLoadingReport = false;
                      });
                    },
                  ),

                  // InceptionV3 Card
                  _buildHorizontalModelCard(
                    theme: theme,
                    modelTitle: "InceptionV3",
                    result: _inceptionResult,
                    isActive: _activeModelForRag == "InceptionV3",
                    onTapSelect: () {
                      setState(() {
                        _activeModelForRag = "InceptionV3";
                        _selectedPlantName = _inceptionResult?.predictedSpecies;
                        _ragReportText = null;
                        _isLoadingReport = false;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // On-Demand RAG Report Button (Saves Tokens!)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_pharmacy,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Selected: ${_selectedPlantName ?? 'Unknown Plant'}",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    ElevatedButton.icon(
                      onPressed: _isLoadingReport ? null : _generateReportForSelectedPlant,
                      icon: const Icon(Icons.menu_book),
                      label: Text(
                        _ragReportText != null
                            ? "Re-Generate Report"
                            : "📄 Generate Pharmacological Report",
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // RAG Generated Report Section with Markdown Styling & NON-OVERFLOWING loading text
            if (_isLoadingReport)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          "Generating report for $_selectedPlantName...",
                          style: theme.textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_ragReportText != null)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.verified,
                            color: theme.colorScheme.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Pharmacological Profile: $_selectedPlantName",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Styled Markdown Renderer
                      MarkdownBody(
                        data: _ragReportText!,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                          p: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.55,
                            fontSize: 14,
                          ),
                          h1: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                          h2: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                          h3: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                          strong: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          listBullet: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
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
}

// ─── Smooth Bilinear Interpolated Grad-CAM CustomPainter ────────────────────

class GradCamHeatmapPainter extends CustomPainter {
  final List<List<double>> grid;
  final double opacity;

  GradCamHeatmapPainter({required this.grid, this.opacity = 0.55});

  Color _getJetColor(double v) {
    v = v.clamp(0.0, 1.0);
    // Smooth JET colormap: Blue -> Cyan -> Green -> Yellow -> Red
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

    double v00 = grid[y0][x0];
    double v10 = grid[y0][x1];
    double v01 = grid[y1][x0];
    double v11 = grid[y1][x1];

    double top = v00 * (1 - dx) + v10 * dx;
    double bottom = v01 * (1 - dx) + v11 * dx;

    return top * (1 - dy) + bottom * dy;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (grid.isEmpty || grid[0].isEmpty) return;
    final int rows = grid.length;
    final int cols = grid[0].length;

    // Smooth high-resolution rendering using 48x48 bilinear sub-sampling
    const int subStepsX = 48;
    const int subStepsY = 48;

    final double stepW = size.width / subStepsX;
    final double stepH = size.height / subStepsY;

    for (int sy = 0; sy < subStepsY; sy++) {
      for (int sx = 0; sx < subStepsX; sx++) {
        double gy = (sy + 0.5) / subStepsY * (rows - 1);
        double gx = (sx + 0.5) / subStepsX * (cols - 1);

        double val = _sampleBilinear(gx, gy, rows, cols);
        if (val <= 0.05) continue; // Skip cold background

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
