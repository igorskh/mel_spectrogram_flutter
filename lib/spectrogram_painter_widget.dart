import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mel_spectrogram_flutter/build_spectrogram_image.dart';
import 'package:mel_spectrogram_flutter/color_map.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Internal async-image builder + painter
// ─────────────────────────────────────────────────────────────────────────────

class SpectrogramPainterWidget extends StatefulWidget {
  final List<List<double>> spectrogram;
  final ColorMap colorMap;

  const SpectrogramPainterWidget({
    super.key,
    required this.spectrogram,
    required this.colorMap,
  });

  @override
  State<SpectrogramPainterWidget> createState() =>
      _SpectrogramPainterWidgetState();
}

class _SpectrogramPainterWidgetState extends State<SpectrogramPainterWidget> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _buildImage();
  }

  @override
  void didUpdateWidget(covariant SpectrogramPainterWidget old) {
    super.didUpdateWidget(old);
    if (old.spectrogram != widget.spectrogram ||
        old.colorMap != widget.colorMap) {
      _buildImage();
    }
  }

  Future<void> _buildImage() async {
    final img = await buildSpectrogramImage(
      widget.spectrogram,
      widget.colorMap,
    );
    if (mounted) setState(() => _image = img);
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (image == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return CustomPaint(
      painter: _SpectrogramPainter(image),
      child: const SizedBox.expand(),
    );
  }
}

class _SpectrogramPainter extends CustomPainter {
  final ui.Image image;
  _SpectrogramPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    // Equivalent to ContentScale.FillBounds — stretches to fill exactly
    canvas.drawImageRect(image, src, dst, Paint());
  }

  @override
  bool shouldRepaint(_SpectrogramPainter old) => old.image != image;
}
