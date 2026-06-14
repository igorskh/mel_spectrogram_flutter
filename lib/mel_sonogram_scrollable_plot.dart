import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mel_spectrogram_flutter/color_map.dart';
import 'package:mel_spectrogram_flutter/playhead_painter.dart';
import 'package:mel_spectrogram_flutter/spectrogram_painter_widget.dart';

/// Scrollable Mel sonogram view that keeps [currentTimeSeconds] centered.
///
/// The plot width grows with the full spectrogram duration, while the viewport
/// shows only [visibleSeconds] at a time.
///
/// Tapping or dragging seeks to the touched position and calls
/// [onPlayheadPositionChanged] with the new position in the range [0, 1].
/// [playheadPosition] is accepted for API symmetry with [MelSpectrogramPlot]
/// but the visible playhead is always drawn at the viewport center since the
/// spectrogram auto-scrolls to keep the current time centered.
class MelSonogramScrollablePlot extends StatefulWidget {
  final List<List<double>> spectrogram;
  final double height;
  final ColorMap colorMap;

  /// How many seconds should be visible in the viewport at once.
  final double visibleSeconds;

  /// Duration represented by one spectrogram frame in seconds.
  ///
  /// Typical value is `hopSize / sampleRate`.
  final double frameDurationSeconds;

  final Color playheadColor;

  /// Current playhead position in [0, 1]. Drives both the scroll offset
  /// (keeping the playhead centered) and is reported back via
  /// [onPlayheadPositionChanged] when the user seeks.
  final double? playheadPosition;

  /// Called when the user taps or finishes dragging, with the new position
  /// in [0, 1] relative to the full spectrogram duration.
  final Function(double)? onPlayheadPositionChanged;

  const MelSonogramScrollablePlot({
    super.key,
    required this.spectrogram,
    required this.frameDurationSeconds,
    this.playheadPosition,
    this.visibleSeconds = 5.0,
    this.height = 200,
    this.colorMap = ColorMap.grayscale,
    this.playheadColor = Colors.red,
    this.onPlayheadPositionChanged,
  });

  @override
  State<MelSonogramScrollablePlot> createState() =>
      _MelSonogramScrollablePlotState();
}

class _MelSonogramScrollablePlotState extends State<MelSonogramScrollablePlot> {
  final ScrollController _scrollController = ScrollController();
  double? _lastViewportWidth;
  double? _lastPlotWidth;
  bool _isDragging = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MelSonogramScrollablePlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    final needsRecenter =
        !_isDragging &&
        (oldWidget.playheadPosition != widget.playheadPosition ||
            oldWidget.visibleSeconds != widget.visibleSeconds ||
            oldWidget.frameDurationSeconds != widget.frameDurationSeconds ||
            oldWidget.spectrogram.length != widget.spectrogram.length);
    if (needsRecenter) {
      _scheduleCentering();
    }
  }

  /// Converts a local-x touch position in the viewport to a 0-1 fraction of
  /// the full spectrogram, accounting for the current scroll offset and
  /// centered edge padding.
  double _localXToFraction({
    required double localX,
    required double viewportWidth,
    required double plotWidth,
  }) {
    final scrollOffset = _scrollController.hasClients
        ? _scrollController.offset
        : 0.0;
    final leadingPadding = viewportWidth / 2;
    final contentX = scrollOffset + localX;
    final plotX = (contentX - leadingPadding).clamp(0.0, plotWidth);
    if (plotWidth <= 0) return 0.0;
    return plotX / plotWidth;
  }

  void _onSeekUpdate({
    required Offset localPosition,
    required double viewportWidth,
    required double plotWidth,
  }) {
    final fraction = _localXToFraction(
      localX: localPosition.dx,
      viewportWidth: viewportWidth,
      plotWidth: plotWidth,
    );
    setState(() => _isDragging = true);
    widget.onPlayheadPositionChanged?.call(fraction);
  }

  void _onSeekEnd() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _isDragging = false);
    });
  }

  void _scheduleCentering() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _lastViewportWidth == null ||
          _lastPlotWidth == null ||
          !_scrollController.hasClients) {
        return;
      }
      _centerCurrentTime(
        viewportWidth: _lastViewportWidth!,
        plotWidth: _lastPlotWidth!,
      );
    });
  }

  void _centerCurrentTime({
    required double viewportWidth,
    required double plotWidth,
  }) {
    final position = (widget.playheadPosition ?? 0.0).clamp(0.0, 1.0);
    final leadingPadding = viewportWidth / 2;
    final currentX = leadingPadding + position * plotWidth;
    final contentWidth = plotWidth + viewportWidth;
    final maxOffset = max(0.0, contentWidth - viewportWidth);
    final targetOffset = (currentX - viewportWidth / 2).clamp(0.0, maxOffset);

    final currentOffset = _scrollController.offset;
    if ((currentOffset - targetOffset).abs() > 0.5) {
      _scrollController.jumpTo(targetOffset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalDuration =
        widget.spectrogram.length * widget.frameDurationSeconds;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification) {
          setState(() => _isDragging = true);
        } else if (notification is ScrollEndNotification) {
          setState(() => _isDragging = false);
        }

        if (notification is ScrollUpdateNotification &&
            _lastViewportWidth != null &&
            _lastPlotWidth != null) {
          final scrollOffset = notification.metrics.pixels;
          final viewportWidth = notification.metrics.viewportDimension;
          final plotWidth = _lastPlotWidth!;

          final leadingPadding = viewportWidth / 2;
          final currentX = scrollOffset + viewportWidth / 2;
          final plotX = (currentX - leadingPadding).clamp(0.0, plotWidth);
          final fraction = plotWidth > 0 ? plotX / plotWidth : 0.0;

          widget.onPlayheadPositionChanged?.call(fraction);
        }
        return false;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final safeVisibleSeconds = max(widget.visibleSeconds, 1e-6);
        final durationScale = totalDuration <= 0
            ? 1.0
            : totalDuration / safeVisibleSeconds;
        final plotWidth = max(viewportWidth, viewportWidth * durationScale);
        final contentWidth = plotWidth + viewportWidth;

        final dimensionsChanged =
            _lastViewportWidth != viewportWidth || _lastPlotWidth != plotWidth;
        _lastViewportWidth = viewportWidth;
        _lastPlotWidth = plotWidth;

        if (dimensionsChanged) {
          _scheduleCentering();
        }

        return SizedBox(
          height: widget.height,
          child: Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  _onSeekUpdate(
                    localPosition: details.localPosition,
                    viewportWidth: viewportWidth,
                    plotWidth: plotWidth,
                  );
                  _onSeekEnd();
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: SizedBox(
                    width: contentWidth,
                    height: widget.height,
                    child: Row(
                      children: [
                        SizedBox(width: viewportWidth / 2),
                        SizedBox(
                          width: plotWidth,
                          height: widget.height,
                          child: SpectrogramPainterWidget(
                            spectrogram: widget.spectrogram,
                            colorMap: widget.colorMap,
                          ),
                        ),
                        SizedBox(width: viewportWidth / 2),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: PlayheadPainter(0.5, widget.playheadColor),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
}

typedef MelSpectrogramScrollablePlot = MelSonogramScrollablePlot;
