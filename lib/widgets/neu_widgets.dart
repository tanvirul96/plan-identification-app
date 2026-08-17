import 'package:flutter/material.dart';

/// Neumorphism Design System — Shared constants, helpers, and widget builders
/// for the Medicinal Plant RAG Application.

class NeuTheme {
  // ── Light Mode (Herbal Sage & Leaf Green) ──
  static const Color lightBg = Color(0xFFE2EFE4);
  static const Color lightSurface = Color(0xFFE2EFE4);
  static const Color lightShadowDark = Color(0xFFBDD2C0);
  static const Color lightShadowLight = Color(0xFFF6FFF8);
  static const Color lightPrimary = Color(0xFF1B5E20);
  static const Color lightPrimaryMuted = Color(0xFF2E7D32);
  static const Color lightOnSurface = Color(0xFF0F2914);
  static const Color lightSubtle = Color(0xFF4A6B50);

  // ── Dark Mode (Deep Rainforest & Emerald Foliage) ──
  static const Color darkBg = Color(0xFF0D1C12);
  static const Color darkSurface = Color(0xFF0D1C12);
  static const Color darkShadowDark = Color(0xFF050C07);
  static const Color darkShadowLight = Color(0xFF183020);
  static const Color darkPrimary = Color(0xFF4ADE80);
  static const Color darkPrimaryMuted = Color(0xFF86EFAC);
  static const Color darkOnSurface = Color(0xFFE8F5E9);
  static const Color darkSubtle = Color(0xFF8BAE93);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color bgColor(BuildContext context) =>
      isDark(context) ? darkBg : lightBg;

  static Color surfaceColor(BuildContext context) =>
      isDark(context) ? darkSurface : lightSurface;

  static Color shadowDark(BuildContext context) =>
      isDark(context) ? darkShadowDark : lightShadowDark;

  static Color shadowLight(BuildContext context) =>
      isDark(context) ? darkShadowLight : lightShadowLight;

  static Color primaryColor(BuildContext context) =>
      isDark(context) ? darkPrimary : lightPrimary;

  static Color primaryMuted(BuildContext context) =>
      isDark(context) ? darkPrimaryMuted : lightPrimaryMuted;

  static Color onSurface(BuildContext context) =>
      isDark(context) ? darkOnSurface : lightOnSurface;

  static Color subtleText(BuildContext context) =>
      isDark(context) ? darkSubtle : lightSubtle;
}

/// A raised Neumorphic container with dual box-shadows.
class NeuContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool isPressed;
  final double blurRadius;
  final double spreadRadius;
  final Offset offset;
  final Color? color;
  final double? width;
  final double? height;

  const NeuContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.isPressed = false,
    this.blurRadius = 16,
    this.spreadRadius = 1,
    this.offset = const Offset(6, 6),
    this.color,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? NeuTheme.surfaceColor(context);
    final dark = NeuTheme.shadowDark(context);
    final light = NeuTheme.shadowLight(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // For pressed/inset: use slightly darker bg + reversed smaller shadows
        color: isPressed
            ? Color.lerp(bg, dark, 0.06)!
            : bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: isPressed
            ? Border.all(
                color: dark.withValues(alpha: 0.12),
                width: 1,
              )
            : null,
        boxShadow: isPressed
            ? [
                // Simulate inset: light shadow top-left (inner highlight)
                BoxShadow(
                  color: light.withValues(alpha: 0.3),
                  offset: offset,
                  blurRadius: blurRadius * 0.5,
                  spreadRadius: -spreadRadius * 2,
                ),
                // Simulate inset: dark shadow bottom-right (inner depth)
                BoxShadow(
                  color: dark.withValues(alpha: 0.4),
                  offset: -offset,
                  blurRadius: blurRadius * 0.5,
                  spreadRadius: -spreadRadius * 2,
                ),
              ]
            : [
                BoxShadow(
                  color: dark.withValues(alpha: 0.5),
                  offset: offset,
                  blurRadius: blurRadius,
                  spreadRadius: spreadRadius,
                ),
                BoxShadow(
                  color: light.withValues(alpha: 0.7),
                  offset: -offset,
                  blurRadius: blurRadius,
                  spreadRadius: spreadRadius,
                ),
              ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: child,
      ),
    );
  }
}

/// A Neumorphic elevated button with press animation.
class NeuButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? width;

  const NeuButton({
    super.key,
    required this.child,
    this.onPressed,
    this.borderRadius = 16,
    this.padding,
    this.color,
    this.width,
  });

  @override
  State<NeuButton> createState() => _NeuButtonState();
}

class _NeuButtonState extends State<NeuButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onPressed != null
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: () => setState(() => _isPressed = false),
      child: NeuContainer(
        isPressed: _isPressed,
        borderRadius: widget.borderRadius,
        padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        color: widget.color,
        width: widget.width,
        blurRadius: 10,
        spreadRadius: 0,
        offset: const Offset(4, 4),
        child: Center(child: widget.child),
      ),
    );
  }
}

/// An inset (concave) Neumorphic text field container.
class NeuInsetContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;

  const NeuInsetContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return NeuContainer(
      isPressed: true,
      borderRadius: borderRadius,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      margin: margin,
      blurRadius: 8,
      spreadRadius: 0,
      offset: const Offset(3, 3),
      child: child,
    );
  }
}

/// A small Neumorphic icon button.
class NeuIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? iconColor;
  final String? tooltip;

  const NeuIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 44,
    this.iconColor,
    this.tooltip,
  });

  @override
  State<NeuIconButton> createState() => _NeuIconButtonState();
}

class _NeuIconButtonState extends State<NeuIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final btn = GestureDetector(
      onTapDown: widget.onPressed != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onPressed != null
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: () => setState(() => _isPressed = false),
      child: NeuContainer(
        isPressed: _isPressed,
        borderRadius: widget.size / 2,
        padding: EdgeInsets.zero,
        width: widget.size,
        height: widget.size,
        blurRadius: 8,
        spreadRadius: 0,
        offset: const Offset(3, 3),
        child: Icon(
          widget.icon,
          color: widget.iconColor ?? NeuTheme.primaryColor(context),
          size: 20,
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: btn);
    }
    return btn;
  }
}
