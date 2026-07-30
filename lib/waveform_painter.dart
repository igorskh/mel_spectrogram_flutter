import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../color_map.dart';

class WaveformPainter extends CustomPainter {
  final List<double> waveform;
  final ColorMap colorMap;
  final Color playheadColor;
  final double? playheadPosition;
  final double? waveformSampleRateHz;
  final double? paintedSamplesPerSecond;
  final int? barsCount;

  WaveformPainter({
    required this.waveform,
    required this.colorMap,
    required this.playheadColor,
    this.playheadPosition,
    this.waveformSampleRateHz,
    this.paintedSamplesPerSecond,
    this.barsCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveform.isEmpty || size.width <= 0 || size.height <= 0) {
      return;
    }

    final double centerY = size.height / 2;
    final double halfHeight = size.height / 2;
    final double maxAbs = waveform
        .map((v) => v.abs())
        .reduce((a, b) => a > b ? a : b);
    final double normalization = maxAbs == 0 ? 1.0 : maxAbs;

    int sampleStride = 1;
    if (waveformSampleRateHz != null &&
        paintedSamplesPerSecond != null &&
        waveformSampleRateHz! > 0 &&
        paintedSamplesPerSecond! > 0) {
      sampleStride = math.max(
        1,
        (waveformSampleRateHz! / paintedSamplesPerSecond!).round(),
      );
    }

    int barCount;
    if (barsCount != null && barsCount! > 0) {
      barCount = barsCount!;
    } else {
      barCount = ((waveform.length + sampleStride - 1) ~/ sampleStride).clamp(
        1,
        waveform.length,
      );
    }
    final double barSpacing = size.width / barCount;
    final double barStrokeWidth = barSpacing.clamp(1.0, 3.0);

    final Paint paint = Paint()
      ..strokeWidth = barStrokeWidth
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < barCount; i++) {
      final int sampleIndex = barsCount != null && barsCount! > 0
          ? ((i * waveform.length) / barCount).round().clamp(
              0,
              waveform.length - 1,
            )
          : math.min(i * sampleStride, waveform.length - 1);
      final double normalized = (waveform[sampleIndex].abs() / normalization)
          .clamp(0.0, 1.0);
      final double barHalf = normalized * halfHeight;
      final double x = (i + 0.5) * barSpacing;

      paint.color = Color(colorMap.toArgb(normalized));
      canvas.drawLine(
        Offset(x, centerY - barHalf),
        Offset(x, centerY + barHalf),
        paint,
      );
    }

    if (playheadPosition != null) {
      final double x = playheadPosition!.clamp(0.0, 1.0) * size.width;
      final Paint playheadPaint = Paint()
        ..color = playheadColor
        ..strokeWidth = 2.0;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), playheadPaint);
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return waveform != oldDelegate.waveform ||
        colorMap != oldDelegate.colorMap ||
        playheadColor != oldDelegate.playheadColor ||
        playheadPosition != oldDelegate.playheadPosition ||
        waveformSampleRateHz != oldDelegate.waveformSampleRateHz ||
        paintedSamplesPerSecond != oldDelegate.paintedSamplesPerSecond ||
        barsCount != oldDelegate.barsCount;
  }
}
