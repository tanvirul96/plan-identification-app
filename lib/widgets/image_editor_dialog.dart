import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../services/localization_service.dart';
import 'botanical_loader.dart';
import 'neu_widgets.dart';

enum CropAspectRatio {
  free,
  square,   // 1:1
  ratio4_3, // 4:3
  ratio16_9,// 16:9
  ratio3_4, // 3:4
}

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
  img.Image? _decodedImage;
  int _rotationAngle = 0;
  bool _isFlippedH = false;
  bool _isProcessing = false;
  CropAspectRatio _selectedRatio = CropAspectRatio.free;

  // Normalized crop rectangle: [0.0, 1.0] relative to displayed image rect
  Rect _cropRectNorm = const Rect.fromLTWH(0.05, 0.05, 0.9, 0.9);

  // Active handle during drag
  _HandleType? _activeHandle;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  void _decode() {
    try {
      _decodedImage = img.decodeImage(widget.initialImageBytes);
      _rotationAngle = 0;
      _isFlippedH = false;
      _setAspectRatio(CropAspectRatio.free);
    } catch (_) {}
  }

  void _setAspectRatio(CropAspectRatio ratio) {
    _selectedRatio = ratio;
    double? targetRatio;
    switch (ratio) {
      case CropAspectRatio.square:
        targetRatio = 1.0;
        break;
      case CropAspectRatio.ratio4_3:
        targetRatio = 4.0 / 3.0;
        break;
      case CropAspectRatio.ratio16_9:
        targetRatio = 16.0 / 9.0;
        break;
      case CropAspectRatio.ratio3_4:
        targetRatio = 3.0 / 4.0;
        break;
      case CropAspectRatio.free:
        targetRatio = null;
        break;
    }

    if (targetRatio != null) {
      // Adjust cropRect to match target aspect ratio inside [0, 1]
      double w = 0.85;
      double h = w / targetRatio;
      if (h > 0.85) {
        h = 0.85;
        w = h * targetRatio;
      }
      final l = (1.0 - w) / 2.0;
      final t = (1.0 - h) / 2.0;
      setState(() {
        _cropRectNorm = Rect.fromLTWH(l.clamp(0.0, 1.0), t.clamp(0.0, 1.0), w.clamp(0.1, 1.0), h.clamp(0.1, 1.0));
      });
    } else {
      setState(() {
        _cropRectNorm = const Rect.fromLTWH(0.05, 0.05, 0.9, 0.9);
      });
    }
  }

  void _rotate(int delta) {
    setState(() {
      _rotationAngle = (_rotationAngle + delta) % 360;
    });
  }

  void _flip() {
    setState(() {
      _isFlippedH = !_isFlippedH;
    });
  }

  void _reset() {
    setState(() {
      _rotationAngle = 0;
      _isFlippedH = false;
      _setAspectRatio(CropAspectRatio.free);
    });
  }

  Future<void> _applyCropAndReturn() async {
    if (_decodedImage == null) return;
    setState(() => _isProcessing = true);

    try {
      img.Image processed = _decodedImage!;

      // 1. Rotation
      if (_rotationAngle != 0) {
        processed = img.copyRotate(processed, angle: _rotationAngle);
      }

      // 2. Horizontal Flip
      if (_isFlippedH) {
        processed = img.copyFlip(processed, direction: img.FlipDirection.horizontal);
      }

      // 3. Pixel-exact Crop
      final int imgW = processed.width;
      final int imgH = processed.height;

      final int cropX = (_cropRectNorm.left * imgW).round().clamp(0, imgW - 1);
      final int cropY = (_cropRectNorm.top * imgH).round().clamp(0, imgH - 1);
      final int cropW = (_cropRectNorm.width * imgW).round().clamp(10, imgW - cropX);
      final int cropH = (_cropRectNorm.height * imgH).round().clamp(10, imgH - cropY);

      final cropped = img.copyCrop(
        processed,
        x: cropX,
        y: cropY,
        width: cropW,
        height: cropH,
      );

      final encoded = Uint8List.fromList(img.encodeJpg(cropped, quality: 90));

      if (mounted) {
        Navigator.of(context).pop(encoded);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
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
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 720),
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.crop_rotate, color: primary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      isBn ? "ইন্টারেক্টিভ ছবি ক্রপ ও ঘোরান" : "Crop & Rotate Specimen",
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
            const SizedBox(height: 10),

            // Interactive Crop & Rotation Canvas Area
            Expanded(
              child: NeuContainer(
                borderRadius: 18,
                padding: const EdgeInsets.all(8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double canvasW = constraints.maxWidth;
                    final double canvasH = constraints.maxHeight;

                    // Calculate transformed image aspect ratio
                    double srcW = (_decodedImage?.width ?? 1).toDouble();
                    double srcH = (_decodedImage?.height ?? 1).toDouble();
                    if (_rotationAngle == 90 || _rotationAngle == 270) {
                      final tmp = srcW;
                      srcW = srcH;
                      srcH = tmp;
                    }

                    final double srcRatio = srcW / srcH;
                    final double canvasRatio = canvasW / canvasH;

                    double displayedW;
                    double displayedH;

                    if (srcRatio > canvasRatio) {
                      displayedW = canvasW;
                      displayedH = canvasW / srcRatio;
                    } else {
                      displayedH = canvasH;
                      displayedW = canvasH * srcRatio;
                    }

                    final double imgOffsetX = (canvasW - displayedW) / 2;
                    final double imgOffsetY = (canvasH - displayedH) / 2;
                    final Rect imgRect = Rect.fromLTWH(imgOffsetX, imgOffsetY, displayedW, displayedH);

                    // Crop rect in canvas coordinates
                    final Rect cropRectCanvas = Rect.fromLTWH(
                      imgRect.left + _cropRectNorm.left * imgRect.width,
                      imgRect.top + _cropRectNorm.top * imgRect.height,
                      _cropRectNorm.width * imgRect.width,
                      _cropRectNorm.height * imgRect.height,
                    );

                    return GestureDetector(
                      onPanStart: (details) {
                        final pos = details.localPosition;
                        _activeHandle = _detectHandle(pos, cropRectCanvas);
                      },
                      onPanUpdate: (details) {
                        if (_activeHandle == null) return;
                        final delta = details.delta;
                        _updateCropRect(delta, imgRect, _activeHandle!);
                      },
                      onPanEnd: (_) => _activeHandle = null,
                      onPanCancel: () => _activeHandle = null,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // 1. Transformed Base Image
                          Center(
                            child: SizedBox(
                              width: displayedW,
                              height: displayedH,
                              child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..rotateZ(_rotationAngle * math.pi / 180)
                                  ..scaleByDouble(_isFlippedH ? -1.0 : 1.0, 1.0, 1.0, 1.0),
                                child: Image.memory(
                                  widget.initialImageBytes,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),

                          // 2. Custom Painter for Dark Mask, Grid, and Draggable Crop Handles
                          CustomPaint(
                            size: Size(canvasW, canvasH),
                            painter: _CropOverlayPainter(
                              imgRect: imgRect,
                              cropRect: cropRectCanvas,
                              primaryColor: primary,
                            ),
                          ),

                          if (_isProcessing)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black38,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Center(
                                child: BotanicalLoader(size: 56, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Rotation & Transform Action Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                NeuIconButton(
                  icon: Icons.rotate_90_degrees_ccw,
                  tooltip: isBn ? "বামে ৯০° ঘোরান" : "Rotate 90° CCW",
                  onPressed: _isProcessing ? null : () => _rotate(-90),
                ),
                NeuIconButton(
                  icon: Icons.rotate_90_degrees_cw,
                  tooltip: isBn ? "ডানে ৯০° ঘোরান" : "Rotate 90° CW",
                  onPressed: _isProcessing ? null : () => _rotate(90),
                ),
                NeuIconButton(
                  icon: Icons.flip,
                  tooltip: isBn ? "ফ্লিপ করুন" : "Flip Horizontal",
                  onPressed: _isProcessing ? null : _flip,
                ),
                NeuIconButton(
                  icon: Icons.restart_alt,
                  iconColor: Colors.orange.shade700,
                  tooltip: isBn ? "রিসেট" : "Reset",
                  onPressed: _isProcessing ? null : _reset,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Aspect Ratio Selector Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildRatioChip(CropAspectRatio.free, isBn ? "কাস্টম / ফ্রি" : "Freeform"),
                  const SizedBox(width: 6),
                  _buildRatioChip(CropAspectRatio.square, "1:1"),
                  const SizedBox(width: 6),
                  _buildRatioChip(CropAspectRatio.ratio4_3, "4:3"),
                  const SizedBox(width: 6),
                  _buildRatioChip(CropAspectRatio.ratio16_9, "16:9"),
                  const SizedBox(width: 6),
                  _buildRatioChip(CropAspectRatio.ratio3_4, "3:4"),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Action Buttons (Cancel / Apply Crop)
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      isBn ? "বাতিল" : "Cancel",
                      style: TextStyle(color: NeuTheme.subtleText(context), fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NeuButton(
                    onPressed: _isProcessing ? null : _applyCropAndReturn,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check, size: 18, color: Colors.green),
                        const SizedBox(width: 6),
                        Text(
                          isBn ? "ক্রপ প্রয়োগ করুন" : "Apply Crop",
                          style: TextStyle(fontWeight: FontWeight.bold, color: onSurf),
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

  Widget _buildRatioChip(CropAspectRatio ratio, String label) {
    final bool isSelected = _selectedRatio == ratio;
    final primary = NeuTheme.primaryColor(context);

    return GestureDetector(
      onTap: _isProcessing ? null : () => _setAspectRatio(ratio),
      child: NeuContainer(
        isPressed: isSelected,
        borderRadius: 12,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  _HandleType _detectHandle(Offset pos, Rect cropRect) {
    const double touchRadius = 24.0;
    if ((pos - cropRect.topLeft).distance <= touchRadius) return _HandleType.topLeft;
    if ((pos - cropRect.topRight).distance <= touchRadius) return _HandleType.topRight;
    if ((pos - cropRect.bottomLeft).distance <= touchRadius) return _HandleType.bottomLeft;
    if ((pos - cropRect.bottomRight).distance <= touchRadius) return _HandleType.bottomRight;
    if (cropRect.contains(pos)) return _HandleType.center;
    return _HandleType.center;
  }

  void _updateCropRect(Offset delta, Rect imgRect, _HandleType handle) {
    final double dxNorm = delta.dx / imgRect.width;
    final double dyNorm = delta.dy / imgRect.height;

    double l = _cropRectNorm.left;
    double t = _cropRectNorm.top;
    double r = _cropRectNorm.right;
    double b = _cropRectNorm.bottom;

    const double minSize = 0.15;

    switch (handle) {
      case _HandleType.center:
        final double w = r - l;
        final double h = b - t;
        l = (l + dxNorm).clamp(0.0, 1.0 - w);
        t = (t + dyNorm).clamp(0.0, 1.0 - h);
        r = l + w;
        b = t + h;
        break;
      case _HandleType.topLeft:
        l = (l + dxNorm).clamp(0.0, r - minSize);
        t = (t + dyNorm).clamp(0.0, b - minSize);
        break;
      case _HandleType.topRight:
        r = (r + dxNorm).clamp(l + minSize, 1.0);
        t = (t + dyNorm).clamp(0.0, b - minSize);
        break;
      case _HandleType.bottomLeft:
        l = (l + dxNorm).clamp(0.0, r - minSize);
        b = (b + dyNorm).clamp(t + minSize, 1.0);
        break;
      case _HandleType.bottomRight:
        r = (r + dxNorm).clamp(l + minSize, 1.0);
        b = (b + dyNorm).clamp(t + minSize, 1.0);
        break;
    }

    setState(() {
      _cropRectNorm = Rect.fromLTRB(l, t, r, b);
    });
  }
}

enum _HandleType { topLeft, topRight, bottomLeft, bottomRight, center }

class _CropOverlayPainter extends CustomPainter {
  final Rect imgRect;
  final Rect cropRect;
  final Color primaryColor;

  _CropOverlayPainter({
    required this.imgRect,
    required this.cropRect,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Darkened outer mask outside crop box
    final maskPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRect(imgRect)
      ..addRect(cropRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, maskPaint);

    // 2. Crop Bounding Box Outline
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(cropRect, borderPaint);

    // 3. Rule of Thirds Grid Lines inside crop box
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final double stepX = cropRect.width / 3.0;
    final double stepY = cropRect.height / 3.0;

    canvas.drawLine(
        Offset(cropRect.left + stepX, cropRect.top), Offset(cropRect.left + stepX, cropRect.bottom), gridPaint);
    canvas.drawLine(
        Offset(cropRect.left + stepX * 2, cropRect.top), Offset(cropRect.left + stepX * 2, cropRect.bottom), gridPaint);
    canvas.drawLine(
        Offset(cropRect.left, cropRect.top + stepY), Offset(cropRect.right, cropRect.top + stepY), gridPaint);
    canvas.drawLine(
        Offset(cropRect.left, cropRect.top + stepY * 2), Offset(cropRect.right, cropRect.top + stepY * 2), gridPaint);

    // 4. Corner Handles (L-shaped prominent corner brackets)
    final handlePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const double cornerLen = 16.0;

    // Top-Left
    canvas.drawLine(cropRect.topLeft, cropRect.topLeft + const Offset(cornerLen, 0), handlePaint);
    canvas.drawLine(cropRect.topLeft, cropRect.topLeft + const Offset(0, cornerLen), handlePaint);

    // Top-Right
    canvas.drawLine(cropRect.topRight, cropRect.topRight + const Offset(-cornerLen, 0), handlePaint);
    canvas.drawLine(cropRect.topRight, cropRect.topRight + const Offset(0, cornerLen), handlePaint);

    // Bottom-Left
    canvas.drawLine(cropRect.bottomLeft, cropRect.bottomLeft + const Offset(cornerLen, 0), handlePaint);
    canvas.drawLine(cropRect.bottomLeft, cropRect.bottomLeft + const Offset(0, -cornerLen), handlePaint);

    // Bottom-Right
    canvas.drawLine(cropRect.bottomRight, cropRect.bottomRight + const Offset(-cornerLen, 0), handlePaint);
    canvas.drawLine(cropRect.bottomRight, cropRect.bottomRight + const Offset(0, -cornerLen), handlePaint);
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) =>
      oldDelegate.cropRect != cropRect || oldDelegate.imgRect != imgRect;
}
