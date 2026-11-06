import 'dart:math' as math;

import 'package:flutter/material.dart';

class LiquidProgressBar extends StatelessWidget {
  const LiquidProgressBar({
    required this.value,
    required this.color,
    this.height = 12,
    this.radius,
    this.label,
    super.key,
  });

  final double value;
  final Color color;
  final double height;
  final double? radius;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0, 1).toDouble();
    final effectiveRadius = radius ?? height / 2;
    final labelText = label;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _LiquidProgressPainter(
                value: clamped,
                color: color,
                radius: effectiveRadius,
                surface: Theme.of(context).colorScheme.surface,
                isDark: isDark,
              ),
            ),
          ),
          if (labelText != null)
            Positioned(
              right: height * 0.42,
              child: _ProgressLabel(
                label: labelText,
                height: height,
                color: color,
                isDark: isDark,
              ),
            ),
        ],
      ),
    );
  }
}

class _LiquidProgressPainter extends CustomPainter {
  const _LiquidProgressPainter({
    required this.value,
    required this.color,
    required this.radius,
    required this.surface,
    required this.isDark,
  });

  final double value;
  final Color color;
  final double radius;
  final Color surface;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final track = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(math.min(radius, size.height / 2)),
    );
    final fillWidth = (size.width * value).clamp(0.0, size.width);

    _drawOuterGlow(canvas, size, track);
    _drawTrack(canvas, size, track);
    if (fillWidth > 0.5) {
      _drawLiquid(canvas, size, track, fillWidth);
    }
    _drawGlassHighlights(canvas, size, track);
    _drawRightLens(canvas, size, track);
    _drawSparkles(canvas, size, fillWidth);
    _drawBorder(canvas, track);
  }

  void _drawOuterGlow(Canvas canvas, Size size, RRect track) {
    final shadow = Paint()
      ..color = color.withValues(alpha: isDark ? 0.09 : 0.18)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        size.height * (isDark ? 0.34 : 0.46),
      );
    canvas.drawRRect(track.shift(Offset(0, size.height * 0.09)), shadow);

    if (!isDark) {
      final lift = Paint()
        ..color = Colors.white.withValues(alpha: 0.64)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.height * 0.18);
      canvas.drawRRect(track.shift(Offset(0, -size.height * 0.08)), lift);
    }
  }

  void _drawTrack(Canvas canvas, Size size, RRect track) {
    final trackPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          isDark
              ? Color.alphaBlend(
                  color.withValues(alpha: 0.10),
                  const Color(0xFF2A2F2C),
                ).withValues(alpha: 0.96)
              : Colors.white.withValues(alpha: 0.86),
          Color.alphaBlend(
            color.withValues(alpha: isDark ? 0.16 : 0.10),
            surface,
          ).withValues(alpha: isDark ? 0.92 : 0.86),
          isDark
              ? const Color(0xFF202522).withValues(alpha: 0.98)
              : Colors.white.withValues(alpha: 0.70),
        ],
        stops: const [0.0, 0.56, 1.0],
      ).createShader(Offset.zero & size);

    canvas.drawRRect(track, trackPaint);

    final innerShade = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          color.withValues(alpha: isDark ? 0.12 : 0.08),
          Colors.white.withValues(alpha: isDark ? 0.05 : 0.16),
          color.withValues(alpha: isDark ? 0.10 : 0.06),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(track.deflate(size.height * 0.08), innerShade);
  }

  void _drawLiquid(Canvas canvas, Size size, RRect track, double fillWidth) {
    final liquidRect = Rect.fromLTWH(0, 0, fillWidth, size.height);
    final liquidRRect = RRect.fromRectAndRadius(
      liquidRect,
      Radius.circular(size.height / 2),
    );

    canvas.save();
    canvas.clipRRect(track);

    final liquidPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          color.withValues(alpha: 0.98),
          _mix(color, Colors.white, 0.18).withValues(alpha: 0.83),
          _mix(color, Colors.white, 0.40).withValues(alpha: 0.62),
          color.withValues(alpha: 0.22),
        ],
        stops: const [0.0, 0.48, 0.78, 1.0],
      ).createShader(liquidRect);
    canvas.drawRRect(liquidRRect, liquidPaint);

    final lowerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.02),
          color.withValues(alpha: 0.18),
        ],
      ).createShader(liquidRect);
    canvas.drawRRect(liquidRRect, lowerPaint);

    if (fillWidth > size.height * 1.5) {
      final meniscusRect = Rect.fromLTWH(
        fillWidth - size.height * 2.6,
        size.height * 0.08,
        size.height * 2.6,
        size.height * 0.84,
      );
      final meniscusPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.white.withValues(alpha: 0.02),
            Colors.white.withValues(alpha: 0.46),
            Colors.white.withValues(alpha: 0.08),
          ],
          stops: const [0.0, 0.64, 1.0],
        ).createShader(meniscusRect);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          meniscusRect,
          Radius.circular(size.height / 2),
        ),
        meniscusPaint,
      );
    }

    canvas.restore();
  }

  void _drawGlassHighlights(Canvas canvas, Size size, RRect track) {
    canvas.save();
    canvas.clipRRect(track);

    final topStripe = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.height * 0.50,
        size.height * 0.13,
        size.width - size.height,
        size.height * 0.18,
      ),
      Radius.circular(size.height),
    );
    canvas.drawRRect(
      topStripe,
      Paint()..color = Colors.white.withValues(alpha: isDark ? 0.10 : 0.52),
    );

    final leftBloomRect = Rect.fromLTWH(
      size.height * 0.32,
      size.height * 0.18,
      size.width * 0.24,
      size.height * 0.70,
    );
    final leftBloom = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.90, -0.50),
        radius: 1.0,
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.08 : 0.38),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(leftBloomRect);
    canvas.drawOval(leftBloomRect, leftBloom);

    final bottomLine = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.height * 0.52,
        size.height * 0.72,
        size.width - size.height * 1.04,
        size.height * 0.10,
      ),
      Radius.circular(size.height),
    );
    canvas.drawRRect(
      bottomLine,
      Paint()..color = color.withValues(alpha: 0.10),
    );

    canvas.restore();
  }

  void _drawRightLens(Canvas canvas, Size size, RRect track) {
    final lensWidth = math.min(size.width * 0.26, size.height * 5.8);
    final lensRect = Rect.fromLTWH(
      size.width - lensWidth,
      size.height * 0.08,
      lensWidth,
      size.height * 0.84,
    );

    canvas.save();
    canvas.clipRRect(track);
    final lensPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: isDark ? 0.12 : 0.42),
          Colors.white.withValues(alpha: isDark ? 0.18 : 0.70),
        ],
        stops: const [0.0, 0.66, 1.0],
      ).createShader(lensRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(lensRect, Radius.circular(size.height / 2)),
      lensPaint,
    );

    final capPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.36, -0.18),
        radius: 0.82,
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.14 : 0.58),
          Colors.white.withValues(alpha: isDark ? 0.03 : 0.08),
        ],
      ).createShader(lensRect);
    canvas.drawOval(lensRect, capPaint);
    canvas.restore();
  }

  void _drawSparkles(Canvas canvas, Size size, double fillWidth) {
    if (size.width < size.height * 8) return;

    final specs = <_SparkleSpec>[
      const _SparkleSpec(0.20, 0.48, 0.34, _SparkleShape.dot),
      const _SparkleSpec(0.32, 0.42, 0.54, _SparkleShape.star),
      const _SparkleSpec(0.49, 0.50, 0.40, _SparkleShape.diamond),
      const _SparkleSpec(0.61, 0.63, 0.28, _SparkleShape.dot),
      const _SparkleSpec(0.68, 0.42, 0.56, _SparkleShape.diamond),
      const _SparkleSpec(0.77, 0.52, 0.34, _SparkleShape.star),
      const _SparkleSpec(0.88, 0.35, 0.32, _SparkleShape.dot),
    ];

    for (final spec in specs) {
      final center = Offset(size.width * spec.x, size.height * spec.y);
      final inLiquid = center.dx <= fillWidth + size.height * 0.40;
      final sparkleColor = inLiquid
          ? Colors.white.withValues(alpha: 0.70)
          : color.withValues(alpha: 0.18);
      final sparkleSize = size.height * spec.scale;

      switch (spec.shape) {
        case _SparkleShape.dot:
          canvas.drawCircle(
            center,
            sparkleSize * 0.34,
            Paint()..color = sparkleColor,
          );
        case _SparkleShape.diamond:
          _drawDiamond(canvas, center, sparkleSize, sparkleColor);
        case _SparkleShape.star:
          _drawStar(canvas, center, sparkleSize, sparkleColor);
      }
    }
  }

  void _drawBorder(Canvas canvas, RRect track) {
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.14 : 0.92),
          color.withValues(alpha: isDark ? 0.34 : 0.48),
          color.withValues(alpha: isDark ? 0.18 : 0.22),
        ],
      ).createShader(track.outerRect);
    canvas.drawRRect(track.deflate(0.45), borderPaint);

    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.white.withValues(alpha: isDark ? 0.10 : 0.46);
    canvas.drawRRect(track.deflate(2), rimPaint);
  }

  static void _drawDiamond(
    Canvas canvas,
    Offset center,
    double size,
    Color color,
  ) {
    final path = Path()
      ..moveTo(center.dx, center.dy - size * 0.55)
      ..lineTo(center.dx + size * 0.48, center.dy)
      ..lineTo(center.dx, center.dy + size * 0.55)
      ..lineTo(center.dx - size * 0.48, center.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.6, size * 0.08)
        ..color = Colors.white.withValues(alpha: 0.30),
    );
  }

  static void _drawStar(
    Canvas canvas,
    Offset center,
    double size,
    Color color,
  ) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final angle = -math.pi / 2 + i * math.pi / 4;
      final radius = i.isEven ? size * 0.62 : size * 0.18;
      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  static Color _mix(Color a, Color b, double amount) {
    return Color.lerp(a, b, amount) ?? a;
  }

  @override
  bool shouldRepaint(covariant _LiquidProgressPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.surface != surface ||
        oldDelegate.isDark != isDark;
  }
}

class _ProgressLabel extends StatelessWidget {
  const _ProgressLabel({
    required this.label,
    required this.height,
    required this.color,
    required this.isDark,
  });

  final String label;
  final double height;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height * 0.76,
      constraints: BoxConstraints(minWidth: height * 3.4),
      padding: EdgeInsets.symmetric(horizontal: height * 0.48),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2B302D).withValues(alpha: 0.96)
            : Theme.of(context).colorScheme.surface.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.40),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.06 : 0.10),
            blurRadius: height * (isDark ? 0.18 : 0.26),
            offset: Offset(0, height * 0.08),
          ),
        ],
      ),
      child: Text(
        label,
        maxLines: 1,
        style: TextStyle(
          color: color.withValues(alpha: 0.94),
          fontSize: height * 0.56,
          fontWeight: FontWeight.w800,
          height: 1,
          letterSpacing: 0,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _SparkleSpec {
  const _SparkleSpec(this.x, this.y, this.scale, this.shape);

  final double x;
  final double y;
  final double scale;
  final _SparkleShape shape;
}

enum _SparkleShape { dot, diamond, star }
