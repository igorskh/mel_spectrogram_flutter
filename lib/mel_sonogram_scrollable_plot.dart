import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mel_spectrogram_flutter/color_map.dart';
import 'package:mel_spectrogram_flutter/playhead_painter.dart';
import 'package:mel_spectrogram_flutter/sonogram_axes_painter.dart';
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
  final Function()? onPlayheadDragStart;
  final Function()? onPlayheadDragEnd;
  final Function(double)? onTapped;
  final int tapDebounceMillis;

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

  /// Whether to draw time ticks (bottom) and frequency ticks (left).
  final bool showAxes;

  /// Frequency range covered by the mel bands, used for the frequency ticks.
  /// Defaults match a 44.1 kHz sample rate (0 Hz to Nyquist).
  final double minFrequencyHz;
  final double maxFrequencyHz;

  /// Color of the frequency ticks, drawn over the spectrogram.
  final Color axisColor;

  /// Color of the time ticks, drawn below the spectrogram. Defaults to the
  /// theme's `onSurface` color.
  final Color? timeAxisColor;

  /// Height reserved below the spectrogram for time labels when [showAxes].
  static const double timeAxisHeight = 20;

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
    this.onPlayheadDragStart,
    this.onPlayheadDragEnd,
    this.onTapped,
    this.tapDebounceMillis = 200,
    this.showAxes = true,
    this.minFrequencyHz = 0,
    this.maxFrequencyHz = 22050,
    this.axisColor = Colors.white70,
    this.timeAxisColor,
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
  bool _hasActiveSeekGesture = false;

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

  void _beginSeekGesture() {
    if (_hasActiveSeekGesture) {
      return;
    }
    _hasActiveSeekGesture = true;
    widget.onPlayheadDragStart?.call();
  }

  void _onTapped({
    required Offset localPosition,
    required double viewportWidth,
    required double plotWidth,
  }) {
    Future.delayed(Duration(milliseconds: widget.tapDebounceMillis), () {
      if (_hasActiveSeekGesture) {
        return;
      }
      final fraction = _localXToFraction(
        localX: localPosition.dx,
        viewportWidth: viewportWidth,
        plotWidth: plotWidth,
      );
      widget.onTapped?.call(fraction);
    });
  }

  void _onSeekEnd() {
    if (!_hasActiveSeekGesture) {
      return;
    }
    _hasActiveSeekGesture = false;
    widget.onPlayheadDragEnd?.call();
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
          _isDragging = true;
          if (notification.dragDetails != null) {
            _beginSeekGesture();
          }
        } else if (notification is ScrollEndNotification) {
          _isDragging = false;
        }

        if (notification is ScrollUpdateNotification &&
            notification.dragDetails != null &&
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
              _lastViewportWidth != viewportWidth ||
              _lastPlotWidth != plotWidth;
          _lastViewportWidth = viewportWidth;
          _lastPlotWidth = plotWidth;

          if (dimensionsChanged) {
            _scheduleCentering();
          }

          final axisHeight = widget.showAxes
              ? MelSonogramScrollablePlot.timeAxisHeight
              : 0.0;
          final availableHeight = constraints.maxHeight.isFinite
              ? min(widget.height, constraints.maxHeight)
              : widget.height;
          final plotHeight = max(0.0, availableHeight - axisHeight);

          return SizedBox(
            height: widget.height,
            child: Stack(
              children: [
                Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerUp: (_) => _onSeekEnd(),
                  onPointerCancel: (_) => _onSeekEnd(),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) {
                      _onTapped(
                        localPosition: details.localPosition,
                        viewportWidth: viewportWidth,
                        plotWidth: plotWidth,
                      );
                    },
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      child: SizedBox(
                        width: contentWidth,
                        height: widget.height,
                        child: Column(
                          children: [
                            SizedBox(
                              height: plotHeight,
                              child: Row(
                                children: [
                                  SizedBox(width: viewportWidth / 2),
                                  SizedBox(
                                    width: plotWidth,
                                    height: plotHeight,
                                    child: SpectrogramPainterWidget(
                                      spectrogram: widget.spectrogram,
                                      colorMap: widget.colorMap,
                                    ),
                                  ),
                                  SizedBox(width: viewportWidth / 2),
                                ],
                              ),
                            ),
                            if (widget.showAxes)
                              SizedBox(
                                width: contentWidth,
                                height: axisHeight,
                                child: CustomPaint(
                                  painter: TimeAxisPainter(
                                    leadingPadding: viewportWidth / 2,
                                    plotWidth: plotWidth,
                                    totalDuration: totalDuration,
                                    color:
                                        widget.timeAxisColor ??
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.showAxes)
                  Positioned(
                    left: 0,
                    top: 0,
                    width: 40,
                    height: plotHeight,
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: FrequencyAxisPainter(
                          minFrequencyHz: widget.minFrequencyHz,
                          maxFrequencyHz: widget.maxFrequencyHz,
                          color: widget.axisColor,
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
