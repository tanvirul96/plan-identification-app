import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../services/localization_service.dart';
import 'neu_widgets.dart';

class ImageEditorDialog extends StatefulWidget {
  final Uint8List initialImageBytes;

  const ImageEditorDialog({
    super.key,
    required this.initialImageBytes,
  });

  @override
  State<ImageEditorDialog> createState() => _ImageEditorDialogState();
}

class _ImageEditorDialogState extends State<ImageEditorDialog> {
  late Uint8List _currentBytes;
  int _rotationAngle = 0;
  bool _isFlippedH = false;
  bool _isProcessing = false;
  double _cropFactor = 1.0; // 1.0 = full, 0.85 = tight, 0.7 = close-up

  @override
  void initState() {
    super.initState();
    _currentBytes = widget.initialImageBytes;
  }

  Future<void> _applyTransformations({int? rotateDelta, bool? toggleFlip, double? newCrop}) async {
    setState(() => _isProcessing = true);

    try {
      final img.Image? original = img.decodeImage(widget.initialImageBytes);
      if (original == null) {
        setState(() => _isProcessing = false);
        return;
      }

      if (rotateDelta != null) {
        _rotationAngle = (_rotationAngle + rotateDelta) % 360;
      }
      if (toggleFlip == true) {
        _isFlippedH = !_isFlippedH;
      }
      if (newCrop != null) {
        _cropFactor = newCrop;
      }

      img.Image processed = original;

      // 1. Rotation
      if (_rotationAngle != 0) {
        processed = img.copyRotate(processed, angle: _rotationAngle);
      }

      // 2. Horizontal Flip
      if (_isFlippedH) {
        processed = img.copyFlip(processed, direction: img.FlipDirection.horizontal);
      }

      // 3. Center Crop
      if (_cropFactor < 0.99) {
        final int cropW = (processed.width * _cropFactor).round();
        final int cropH = (processed.height * _cropFactor).round();
        final int x = (processed.width - cropW) ~/ 2;
        final int y = (processed.height - cropH) ~/ 2;
        processed = img.copyCrop(processed, x: x, y: y, width: cropW, height: cropH);
      }

      final encoded = Uint8List.fromList(img.encodeJpg(processed, quality: 90));

      if (mounted) {
        setState(() {
          _currentBytes = encoded;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _reset() {
    _rotationAngle = 0;
    _isFlippedH = false;
    _cropFactor = 1.0;
    setState(() {
      _currentBytes = widget.initialImageBytes;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService();
    final isBn = loc.isBangla;
    final primary = NeuTheme.primaryColor(context);
    final onSurf = NeuTheme.onSurface(context);

    return Dialog(
      backgroundColor: NeuTheme.surfaceColor(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.crop_rotate, color: primary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      isBn ? "ছবি সম্পাদনা ও ক্রপ" : "Edit & Crop Specimen",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: onSurf,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Image Preview Container
            Expanded(
              child: Center(
                child: NeuContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(6),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _currentBytes,
                          fit: BoxFit.contain,
                        ),
                      ),
                      if (_isProcessing)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Transformation Controls (Rotate Left, Rotate Right, Flip, Reset)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                NeuIconButton(
                  icon: Icons.rotate_90_degrees_ccw,
                  tooltip: isBn ? "বামে ৯০° ঘোরান" : "Rotate 90° CCW",
                  onPressed: _isProcessing ? null : () => _applyTransformations(rotateDelta: -90),
                ),
                NeuIconButton(
                  icon: Icons.rotate_90_degrees_cw,
                  tooltip: isBn ? "ডানে ৯০° ঘোরান" : "Rotate 90° CW",
                  onPressed: _isProcessing ? null : () => _applyTransformations(rotateDelta: 90),
                ),
                NeuIconButton(
                  icon: Icons.flip,
                  tooltip: isBn ? "ফ্লিপ করুন" : "Flip Horizontal",
                  onPressed: _isProcessing ? null : () => _applyTransformations(toggleFlip: true),
                ),
                NeuIconButton(
                  icon: Icons.restart_alt,
                  iconColor: Colors.orange.shade700,
                  tooltip: isBn ? "রিসেট" : "Reset",
                  onPressed: _isProcessing ? null : _reset,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Crop Preset Chips (Full, 85% Focus, 70% Tight Leaf)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isBn ? "ক্রপ জুম:" : "Focus:",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurf),
                ),
                const SizedBox(width: 8),
                _buildCropChip("100%", 1.0),
                const SizedBox(width: 6),
                _buildCropChip("85%", 0.85),
                const SizedBox(width: 6),
                _buildCropChip("70%", 0.70),
              ],
            ),
            const SizedBox(height: 16),

            // Action Buttons (Cancel / Apply)
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      isBn ? "বাতিল" : "Cancel",
                      style: TextStyle(color: NeuTheme.subtleText(context)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NeuButton(
                    onPressed: _isProcessing ? null : () => Navigator.of(context).pop(_currentBytes),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check, size: 18, color: Colors.green),
                        const SizedBox(width: 6),
                        Text(
                          isBn ? "প্রয়োগ করুন" : "Apply",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: onSurf,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropChip(String label, double factor) {
    final bool isSelected = (_cropFactor - factor).abs() < 0.01;
    final primary = NeuTheme.primaryColor(context);

    return GestureDetector(
      onTap: _isProcessing ? null : () => _applyTransformations(newCrop: factor),
      child: NeuContainer(
        isPressed: isSelected,
        borderRadius: 12,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        blurRadius: 4,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? primary : NeuTheme.onSurface(context),
          ),
        ),
      ),
    );
  }
}
