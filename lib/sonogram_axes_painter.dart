import 'dart:math';

import 'package:flutter/material.dart';

double _hzToMel(double hz) => 2595.0 * log(1.0 + hz / 700.0) / ln10;

/// Picks the first "nice" step from [candidates] that is at least [minStep].
double _niceStep(double minStep, List<double> candidates) {
  for (final c in candidates) {
    if (c >= minStep) return c;
  }
  return candidates.last;
}

const _timeSteps = <double>[
  0.1, 0.2, 0.5, 1, 2, 5, 10, 15, 30, 60, 120, 300, 600, 1800, 3600, //
];

String formatTimeLabel(double seconds, double step) {
  final total = seconds.round();
  final m = total ~/ 60;
  final s = total % 60;
  if (step < 1) {
    return seconds.toStringAsFixed(1);
  }
  if (seconds >= 3600) {
    final h = total ~/ 3600;
    return '$h:${((total % 3600) ~/ 60).toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }
  return '$m:${s.toString().padLeft(2, '0')}';
}

String formatFrequencyLabel(double hz) {
  if (hz >= 1000) {
    final k = hz / 1000;
    return '${k == k.roundToDouble() ? k.toStringAsFixed(0) : k.toStringAsFixed(1)}k';
  }
  return hz.round().toString();
}

/// Draws time ticks with labels along the bottom of a scrolling plot.
///
/// The painter covers the full scroll content: [leadingPadding] pixels of
/// empty space, then [plotWidth] pixels representing [totalDuration] seconds.
class TimeAxisPainter extends CustomPainter {
  final double leadingPadding;
  final double plotWidth;
  final double totalDuration;
  final Color color;
  final double minTickSpacing;

  TimeAxisPainter({
    required this.leadingPadding,
    required this.plotWidth,
    required this.totalDuration,
    required this.color,
    this.minTickSpacing = 56,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalDuration <= 0 || plotWidth <= 0) return;
    final pxPerSec = plotWidth / totalDuration;
    final step = _niceStep(minTickSpacing / pxPerSec, _timeSteps);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final style = TextStyle(color: color, fontSize: 10);

    final count = (totalDuration / step).floor();
    for (var i = 0; i <= count; i++) {
      final t = i * step;
      final x = leadingPadding + t * pxPerSec;
      canvas.drawLine(Offset(x, 0), Offset(x, 4), paint);
      final tp = TextPainter(
        text: TextSpan(text: formatTimeLabel(t, step), style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, 5));
    }
  }

  @override
  bool shouldRepaint(TimeAxisPainter old) =>
      old.leadingPadding != leadingPadding ||
      old.plotWidth != plotWidth ||
      old.totalDuration != totalDuration ||
      old.color != color ||
      old.minTickSpacing != minTickSpacing;
}

/// Draws frequency ticks with labels along the left edge. Bands are assumed
/// to be spaced linearly on the mel scale between [minFrequencyHz] and
/// [maxFrequencyHz], with low frequencies at the bottom.
class FrequencyAxisPainter extends CustomPainter {
  final double minFrequencyHz;
  final double maxFrequencyHz;
  final Color color;
  final double minTickSpacing;

  FrequencyAxisPainter({
    required this.minFrequencyHz,
    required this.maxFrequencyHz,
    required this.color,
    this.minTickSpacing = 28,
  });

  static const _candidates = <double>[
    50, 100, 200, 300, 500, 700, 1000, 1500, 2000, 3000, 4000, 5000, //
    6000, 8000, 10000, 12000, 16000, 20000,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final melMin = _hzToMel(minFrequencyHz);
    final melMax = _hzToMel(maxFrequencyHz);
    if (melMax <= melMin || size.height <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final style = TextStyle(
      color: color,
      fontSize: 10,
      shadows: const [Shadow(color: Colors.black87, blurRadius: 2)],
    );

    double? lastY;
    for (final hz in _candidates) {
      if (hz < minFrequencyHz || hz > maxFrequencyHz) continue;
      final frac = (_hzToMel(hz) - melMin) / (melMax - melMin);
      final y = size.height * (1 - frac);
      if (lastY != null && (lastY - y).abs() < minTickSpacing) continue;
      lastY = y;
      canvas.drawLine(Offset(0, y), Offset(5, y), paint);
      final tp = TextPainter(
        text: TextSpan(text: formatFrequencyLabel(hz), style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      final ty = (y - tp.height / 2).clamp(0.0, size.height - tp.height);
      tp.paint(canvas, Offset(7, ty));
    }
  }

  @override
  bool shouldRepaint(FrequencyAxisPainter old) =>
      old.minFrequencyHz != minFrequencyHz ||
      old.maxFrequencyHz != maxFrequencyHz ||
      old.color != color ||
      old.minTickSpacing != minTickSpacing;
}
