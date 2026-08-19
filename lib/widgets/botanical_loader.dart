import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'neu_widgets.dart';

/// A unique, highly visible animated botanical leaf loader.
///
/// Renders rotating, stylized leaf petals around a glowing botanical core,
/// giving an unmistakable "blooming plant" aesthetic.
class BotanicalLoader extends StatefulWidget {
  final double size;
  final int petalCount;
  final Color? color;
  final String? label;

  const BotanicalLoader({
    super.key,
    this.size = 48,
    this.petalCount = 6,
    this.color,
    this.label,
  });

  @override
  State<BotanicalLoader> createState() => _BotanicalLoaderState();
}

class _BotanicalLoaderState extends State<BotanicalLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = widget.color ?? NeuTheme.primaryColor(context);
    final Color subtle = NeuTheme.subtleText(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            return CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _BotanicalLeafPainter(
                progress: _ctrl.value,
                petalCount: widget.petalCount,
                color: primary,
              ),
            );
          },
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 10),
          Text(
            widget.label!,
            style: TextStyle(fontSize: 12, color: subtle, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _BotanicalLeafPainter extends CustomPainter {
  final double progress; // 0.0 -> 1.0
  final int petalCount;
  final Color color;

  _BotanicalLeafPainter({
    required this.progress,
    required this.petalCount,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double maxR = math.min(cx, cy);

    // Pulse effect
    final double pulse = 0.5 + 0.5 * math.sin(progress * 2 * math.pi);

    // Central Sprout Core
    final corePaint = Paint()
      ..color = color.withAlpha(220)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), maxR * 0.16 + (maxR * 0.04 * pulse), corePaint);

    // Central Core Ring
    final ringPaint = Paint()
      ..color = color.withAlpha(100)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(cx, cy), maxR * 0.28, ringPaint);

    // Draw Petals
    final double baseAngle = progress * 2 * math.pi;
    final double petalLength = maxR * 0.65;
    final double petalWidth = maxR * 0.28;

    for (int i = 0; i < petalCount; i++) {
      final double fraction = i / petalCount;
      final double angle = baseAngle + fraction * 2 * math.pi;

      // Staggered opacity around the wheel
      final double phase = ((progress - fraction) % 1.0 + 1.0) % 1.0;
      final double opacity = 0.25 + 0.75 * math.sin(phase * math.pi).abs();
      final int alpha = (opacity * 255).round().clamp(50, 255);

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle);

      // Distinct Leaf Silhouette (stem to leaf tip)
      final Path leafPath = Path();
      leafPath.moveTo(0, -maxR * 0.20);
      leafPath.cubicTo(
        petalWidth, -maxR * 0.35,
        petalWidth * 0.8, -petalLength * 0.8,
        0, -petalLength,
      );
      leafPath.cubicTo(
        -petalWidth * 0.8, -petalLength * 0.8,
        -petalWidth, -maxR * 0.35,
        0, -maxR * 0.20,
      );
      leafPath.close();

      // Leaf body
      final leafPaint = Paint()
        ..color = color.withAlpha(alpha)
        ..style = PaintingStyle.fill;
      canvas.drawPath(leafPath, leafPaint);

      // Central Leaf Vein
      final veinPaint = Paint()
        ..color = Colors.white.withAlpha((alpha * 0.6).round())
        ..strokeWidth = math.max(0.8, maxR * 0.035)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(0, -maxR * 0.22),
        Offset(0, -petalLength * 0.85),
        veinPaint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BotanicalLeafPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// Compact inline loader for buttons, headers, and list rows
class BotanicalLoaderInline extends StatelessWidget {
  final double size;
  final Color? color;

  const BotanicalLoaderInline({
    super.key,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return BotanicalLoader(
      size: size,
      petalCount: 5,
      color: color,
    );
  }
}

/// A dedicated thinking / generating response card for chat stream
class BotanicalThinkingCard extends StatelessWidget {
  final String statusText;
  final bool isBangla;

  const BotanicalThinkingCard({
    super.key,
    required this.statusText,
    required this.isBangla,
  });

  @override
  Widget build(BuildContext context) {
    final primary = NeuTheme.primaryColor(context);
    final subtle = NeuTheme.subtleText(context);

    return NeuContainer(
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      blurRadius: 10,
      offset: const Offset(3, 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BotanicalLoader(
            size: 32,
            petalCount: 5,
            color: primary,
          ),
          const SizedBox(width: 14),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isBangla
                      ? "ভেষজ ডাটাবেস ও গবেষণাপত্র বিশ্লেষণ হচ্ছে..."
                      : "Analyzing botanical monograph & clinical pharmacology...",
                  style: TextStyle(
                    fontSize: 11,
                    color: subtle,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
