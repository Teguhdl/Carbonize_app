import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Custom painter for the donut chart showing emission progress.
class DonutChartPainter extends CustomPainter {
  final double percentage;
  final Color backgroundColor;
  final Color progressColor;

  DonutChartPainter({
    required this.percentage,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = radius * 0.3; // 30% of radius for donut thickness

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - (strokeWidth / 2), backgroundPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressAngle = 2 * math.pi * (percentage / 100);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - (strokeWidth / 2)),
      -math.pi / 2, // Start from top
      progressAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Custom painter for dashed border around image upload areas.
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double radius;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ));

    // Draw dashed border
    final dashWidth = 5.0;
    final dashSpace = gap;
    double distance = 0.0;
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      while (distance < metric.length) {
        if (distance + dashWidth > metric.length) {
          // Draw remaining dash
          canvas.drawPath(
            metric.extractPath(distance, metric.length),
            paint,
          );
          distance = metric.length;
        } else {
          // Draw dash
          canvas.drawPath(
            metric.extractPath(distance, distance + dashWidth),
            paint,
          );
          distance += dashWidth;
        }
        // Add gap
        distance += dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
