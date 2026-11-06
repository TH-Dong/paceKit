import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    this.tint,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.radius = 20,
    this.shadowAlpha,
    this.shadowBlur,
    this.shadowOffset,
    super.key,
  });

  final Widget child;
  final Color? tint;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final double? shadowAlpha;
  final double? shadowBlur;
  final Offset? shadowOffset;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // In light mode the card is white with a very faint tint wash.
    // In dark mode it is a dark surface with a faint tint wash.
    final Color baseWhite =
        isDark ? const Color(0xFF1E2320) : const Color(0xFFFCFFFD);
    final Color bg = tint != null
        ? Color.alphaBlend(
            tint!.withValues(alpha: isDark ? 0.10 : 0.055),
            baseWhite,
          )
        : baseWhite;

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Color.alphaBlend(
                  (tint ?? const Color(0xFF88A096)).withValues(alpha: 0.12),
                  const Color(0xFFE5ECE8),
                ),
        ),
        boxShadow: [
          BoxShadow(
            color: (tint ?? Colors.black).withValues(
              alpha: shadowAlpha ?? (isDark ? 0.16 : 0.055),
            ),
            blurRadius: shadowBlur ?? 20,
            offset: shadowOffset ?? const Offset(0, 8),
          ),
          if (!isDark && shadowAlpha != null)
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.70),
              blurRadius: 8,
              offset: const Offset(-2, -3),
            ),
        ],
      ),
      child: child,
    );
  }
}
