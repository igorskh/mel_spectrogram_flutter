import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../color_map.dart';

class WaveformPlot extends StatefulWidget {
  final List<double> waveform;
  final double height;
  final ColorMap colorMap;
  final Color playheadColor;
  final double? playheadPosition;
  final Function(double)? onPlayheadPositionChanged;
  final double? waveformSampleRateHz;
  final double? paintedSamplesPerSecond;

  const WaveformPlot({
    super.key,
    required this.waveform,
    this.colorMap = ColorMap.grayscale,
    this.playheadColor = Colors.red,
    this.height = 200,
    this.playheadPosition,
    this.onPlayheadPositionChanged,
    this.waveformSampleRateHz,
    this.paintedSamplesPerSecond,
  });

  @override
  State<WaveformPlot> createState() => _WaveformPlotState();
}

class _WaveformPlotState extends State<WaveformPlot> {
  double? _playheadPosition;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _playheadPosition = widget.playheadPosition;
  }

  @override
  void didUpdateWidget(covariant WaveformPlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging && widget.playheadPosition != oldWidget.playheadPosition) {
      setState(() {
        _playheadPosition = widget.playheadPosition;
      });
    }
  }

  void _onSeekUpdate(Offset localPosition, double totalWidth) {
    final newPosition = (localPosition.dx / totalWidth).clamp(0.0, 1.0);
    setState(() {
      _isDragging = true;
      _playheadPosition = newPosition;
    });
  }

  void _onSeekEnd() {
    if (_playheadPosition != null) {
      widget.onPlayheadPositionChanged?.call(_playheadPosition!);
    }
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() => _isDragging = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            _onSeekUpdate(details.localPosition, totalWidth);
            _onSeekEnd();
          },
          onHorizontalDragStart: (details) {
            _onSeekUpdate(details.localPosition, totalWidth);
          },
          onHorizontalDragUpdate: (details) {
            _onSeekUpdate(details.localPosition, totalWidth);
          },
          onHorizontalDragEnd: (_) => _onSeekEnd(),
          onHorizontalDragCancel: _onSeekEnd,
          child: CustomPaint(
            painter: WaveformPainter(
              waveform: widget.waveform,
              colorMap: widget.colorMap,
              playheadColor: widget.playheadColor,
              playheadPosition: _playheadPosition,
              waveformSampleRateHz: widget.waveformSampleRateHz,
              paintedSamplesPerSecond: widget.paintedSamplesPerSecond,
            ),
            size: Size(double.infinity, widget.height),
          ),
        );
      },
    );
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> waveform;
  final ColorMap colorMap;
  final Color playheadColor;
  final double? playheadPosition;
  final double? waveformSampleRateHz;
  final double? paintedSamplesPerSecond;

  WaveformPainter({
    required this.waveform,
    required this.colorMap,
    required this.playheadColor,
    this.playheadPosition,
    this.waveformSampleRateHz,
    this.paintedSamplesPerSecond,
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
      // Keep at most the configured number of painted samples per second.
      sampleStride = math.max(
        1,
        (waveformSampleRateHz! / paintedSamplesPerSecond!).round(),
      );
    }

    final int barCount = ((waveform.length + sampleStride - 1) ~/ sampleStride)
        .clamp(1, waveform.length);
    final double barSpacing = size.width / barCount;
    final double barStrokeWidth = barSpacing.clamp(1.0, 3.0);

    final Paint paint = Paint()
      ..strokeWidth = barStrokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw normalized bars around the horizontal center line.
    for (int i = 0; i < barCount; i++) {
      final int sampleIndex = math.min(i * sampleStride, waveform.length - 1);
      final double normalized =
          (waveform[sampleIndex].abs() / normalization).clamp(0.0, 1.0);
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
        paintedSamplesPerSecond != oldDelegate.paintedSamplesPerSecond;
  }
}