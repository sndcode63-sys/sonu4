import 'dart:ui';
import 'package:flutter/material.dart';

class AppDottedBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color? backgroundColor;
  final double strokeWidth;
  final double radius;
  final List<double> dashPattern;
  final EdgeInsetsGeometry? padding;

  const AppDottedBorder({
    super.key,
    required this.child,
    this.color = const Color(0xFF0A5C4A),
    this.backgroundColor,
    this.strokeWidth = 1.5,
    this.radius = 12.0,
    this.dashPattern = const [6, 4],
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedBorderPainter(
        color: color,
        backgroundColor: backgroundColor,
        strokeWidth: strokeWidth,
        radius: radius,
        dashPattern: dashPattern,
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: child,
      ),
    );
  }
}

class _DottedBorderPainter extends CustomPainter {
  final Color color;
  final Color? backgroundColor;
  final double strokeWidth;
  final double radius;
  final List<double> dashPattern;

  _DottedBorderPainter({
    required this.color,
    this.backgroundColor,
    required this.strokeWidth,
    required this.radius,
    required this.dashPattern,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    if (backgroundColor != null) {
      final fillPaint = Paint()
        ..color = backgroundColor!
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rrect, fillPaint);
    }

    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()..addRRect(rrect);
    final dashedPath = _createDashedPath(path, dashPattern);
    canvas.drawPath(dashedPath, strokePaint);
  }

  Path _createDashedPath(Path source, List<double> pattern) {
    final Path dest = Path();
    for (final PathMetric metric in source.computeMetrics()) {
      double distance = 0.0;
      int patternIndex = 0;
      while (distance < metric.length) {
        final double length = pattern[patternIndex % pattern.length];
        if (patternIndex % 2 == 0) {
          dest.addPath(
            metric.extractPath(distance, (distance + length).clamp(0.0, metric.length)),
            Offset.zero,
          );
        }
        distance += length;
        patternIndex++;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant _DottedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius;
  }
}
