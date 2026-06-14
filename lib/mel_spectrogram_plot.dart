import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mel_spectrogram_flutter/color_map.dart';
import 'package:mel_spectrogram_flutter/playhead_painter.dart';
import 'package:mel_spectrogram_flutter/spectrogram_painter_widget.dart';

/// Displays a Mel Spectrogram from a 2-D float array.
///
/// [spectrogram] is indexed as [frame][band], matching the Kotlin
/// `Array<FloatArray>` layout.  Values can be raw linear magnitudes;
/// log₁₀ scaling and normalisation are applied internally.
class MelSpectrogramPlot extends StatefulWidget {
  final List<List<double>> spectrogram;
  final double height;
  final ColorMap colorMap;

  final Color playheadColor;
  // playheadPosition, range 0 to 1
  final double? playheadPosition;

  final Function(double)? onPlayheadPositionChanged;

  const MelSpectrogramPlot({
    super.key,
    required this.spectrogram,
    this.height = 200,
    this.colorMap = ColorMap.grayscale,
    this.playheadColor = Colors.red,
    this.playheadPosition,
    this.onPlayheadPositionChanged,
  });

  @override
  State<MelSpectrogramPlot> createState() => _MelSpectrogramPlotState();
}

class _MelSpectrogramPlotState extends State<MelSpectrogramPlot> {
  double? _playheadPosition;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    // Bug fix: was assigning _playheadPosition to itself
    _playheadPosition = widget.playheadPosition;
  }

  @override
  void didUpdateWidget(covariant MelSpectrogramPlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only accept external updates when not dragging
    if (!_isDragging && widget.playheadPosition != oldWidget.playheadPosition) {
      setState(() {
        _playheadPosition = widget.playheadPosition;
      });
    }
  }

  void _onDragUpdate(Offset localPosition, double totalWidth) {
    final newPosition = (localPosition.dx / totalWidth).clamp(0.0, 1.0);
    setState(() {
      _isDragging = true;
      _playheadPosition = newPosition;
    });
  }

  void _onDragEnd() {
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
          // Handle tapping directly on a position
          onTapDown: (details) {
            _onDragUpdate(details.localPosition, totalWidth);
            _onDragEnd();
          },
          // Handle dragging
          onHorizontalDragStart: (details) {
            _onDragUpdate(details.localPosition, totalWidth);
          },
          onHorizontalDragUpdate: (details) {
            _onDragUpdate(details.localPosition, totalWidth);
          },
          onHorizontalDragEnd: (_) => _onDragEnd(),
          onHorizontalDragCancel: _onDragEnd,
          child: Stack(
            children: [
              SizedBox(
                height: widget.height,
                width: double.infinity,
                child: SpectrogramPainterWidget(
                  spectrogram: widget.spectrogram,
                  colorMap: widget.colorMap,
                ),
              ),
              if (_playheadPosition != null)
                Positioned.fill(
                  child: CustomPaint(
                    painter: PlayheadPainter(
                      _playheadPosition!,
                      widget.playheadColor,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
