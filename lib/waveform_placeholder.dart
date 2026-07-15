import 'package:flutter/material.dart';
import '../color_map.dart';

class WaveformPlaceholder extends StatelessWidget {
  final double height;
  final int barsCount;
  final ColorMap colorMap;

  const WaveformPlaceholder({
    super.key,
    this.height = 200,
    this.barsCount = 64,
    this.colorMap = ColorMap.grayscale,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        return CustomPaint(
          painter: _WaveformPlaceholderPainter(
            height: height,
            barsCount: barsCount,
            colorMap: colorMap,
            totalWidth: totalWidth,
          ),
          size: Size(double.infinity, height),
        );
      },
    );
  }
}

class _WaveformPlaceholderPainter extends CustomPainter {
  final double height;
  final int barsCount;
  final ColorMap colorMap;
  final double totalWidth;

  _WaveformPlaceholderPainter({
    required this.height,
    required this.barsCount,
    required this.colorMap,
    required this.totalWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double barSpacing = totalWidth / barsCount;
    final double barStrokeWidth = (totalWidth / barsCount).clamp(1.0, 3.0);
    final double centerY = size.height / 2;

    final Paint paint = Paint()
      ..strokeWidth = barStrokeWidth
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < barsCount; i++) {
      final double x = (i + 0.5) * barSpacing;
      final double normalized = (i / barsCount).clamp(0.0, 1.0);
      paint.color = Color(colorMap.toArgb(normalized));
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPlaceholderPainter oldDelegate) {
    return height != oldDelegate.height ||
        barsCount != oldDelegate.barsCount ||
        colorMap != oldDelegate.colorMap ||
        totalWidth != oldDelegate.totalWidth;
  }
}
