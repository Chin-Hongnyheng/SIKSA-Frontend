import 'dart:math';
import 'package:flutter/material.dart';

class FloatingLinesBackground extends StatefulWidget {
  final List<Color> colors;
  final int lineCount;
  final double animationSpeed;

  const FloatingLinesBackground({
    super.key,
    this.colors = const [
      Color(0xFF00FF88),
      Color(0xFF4DFFA0),
      Color(0xFFFFFFFF),
    ],
    this.lineCount = 6,
    this.animationSpeed = 0.5,
  });

  @override
  State<FloatingLinesBackground> createState() =>
      _FloatingLinesBackgroundState();
}

class _FloatingLinesBackgroundState extends State<FloatingLinesBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: (30 / widget.animationSpeed).round()),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _FloatingLinesPainter(
            time: _controller.value * 2 * pi,
            colors: widget.colors,
            lineCount: widget.lineCount,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _FloatingLinesPainter extends CustomPainter {
  final double time;
  final List<Color> colors;
  final int lineCount;

  static const double diagonalSlant = 0.4;

  _FloatingLinesPainter({
    required this.time,
    required this.colors,
    required this.lineCount,
  });

  Color _getColor(double t) {
    if (colors.isEmpty) return const Color(0xFF00FF88);
    if (colors.length == 1) return colors[0];
    final scaled = t * (colors.length - 1);
    final idx = scaled.floor().clamp(0, colors.length - 2);
    final f = scaled - idx;
    return Color.lerp(colors[idx], colors[idx + 1], f)!;
  }

  void _drawGlowingCurve(
    Canvas canvas,
    Size size,
    double yCenter,
    double offset,
    double opacity,
    Color color,
    double curvature,
  ) {
    final path = Path();
    bool started = false;

    for (double x = -50; x <= size.width + 50; x += 3) {
      final t = x / size.width;
      final slantY = (0.5 - t) * size.height * diagonalSlant;

      // Even multiples of pi ensure seamless loop
      final y =
          yCenter +
          slantY +
          sin(t * pi * 2 + time + offset) * curvature * 0.4 +
          sin(t * pi * 4 + time * 0.6 + offset * 1.3) * curvature * 0.3 +
          sin(t * pi * 6 + time * 0.4 + offset * 0.7) * curvature * 0.3;

      if (!started) {
        path.moveTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
      }
    }

    final glowLayers = [
      (width: 40.0, opacity: 0.015),
      (width: 22.0, opacity: 0.04),
      (width: 12.0, opacity: 0.08),
      (width: 6.0, opacity: 0.2),
      (width: 2.5, opacity: 0.7),
      (width: 1.0, opacity: 1.0),
    ];

    for (final layer in glowLayers) {
      final paint = Paint()
        ..color = color.withOpacity((opacity * layer.opacity).clamp(0.0, 1.0))
        ..strokeWidth = layer.width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(path, paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF1E6B2D),
          const Color(0xFF165222),
          const Color(0xFF1E6B2D),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final middleY = size.height * 0.52;
    for (int i = 0; i < lineCount; i++) {
      final t = lineCount <= 1 ? 0.5 : i / (lineCount - 1);
      final color = _getColor(t);
      final spacing = (i - lineCount / 2) * 14.0;
      final edgeFade = 1.0 - (t - 0.5).abs() * 1.2;
      final opacity = (0.85 * edgeFade).clamp(0.0, 1.0);

      _drawGlowingCurve(
        canvas,
        size,
        middleY + spacing,
        i * 0.45,
        opacity,
        color,
        size.height * 0.18,
      );
    }

    final topY = size.height * 0.18;
    for (int i = 0; i < (lineCount * 0.6).round(); i++) {
      final t = i / max((lineCount * 0.6).round() - 1, 1);
      final color = _getColor(t * 0.5);
      final spacing = (i - lineCount * 0.3) * 12.0;
      final opacity = 0.25 * (1.0 - (t - 0.5).abs());

      _drawGlowingCurve(
        canvas,
        size,
        topY + spacing,
        i * 0.6 + 2.0,
        opacity,
        color,
        size.height * 0.12,
      );
    }

    final bottomY = size.height * 0.82;
    for (int i = 0; i < (lineCount * 0.5).round(); i++) {
      final t = i / max((lineCount * 0.5).round() - 1, 1);
      final color = _getColor(t * 0.4);
      final spacing = (i - lineCount * 0.25) * 10.0;
      final opacity = 0.18 * (1.0 - (t - 0.5).abs());

      _drawGlowingCurve(
        canvas,
        size,
        bottomY + spacing,
        i * 0.5 + 4.0,
        opacity,
        color,
        size.height * 0.08,
      );
    }

    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, 0.1),
        radius: 0.9,
        colors: [
          const Color(0xFF00FF88).withOpacity(0.12),
          const Color(0xFF00FF88).withOpacity(0.04),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);
  }

  @override
  bool shouldRepaint(_FloatingLinesPainter old) =>
      old.time != time || old.colors != colors || old.lineCount != lineCount;
}
