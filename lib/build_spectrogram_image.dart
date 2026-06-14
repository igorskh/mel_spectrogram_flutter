import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mel_spectrogram_flutter/color_map.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Core bitmap builder  (mirrors buildSpectrogramBitmap exactly)
// ─────────────────────────────────────────────────────────────────────────────

/// Builds a [ui.Image] from a 2-D spectrogram array.
Future<ui.Image> buildSpectrogramImage(
  List<List<double>> spectrogram,
  ColorMap colorMap,
) async {
  final numFrames = spectrogram.length;
  if (numFrames == 0) return _emptyImage();

  final numBands = spectrogram[0].length;
  if (numBands == 0) return _emptyImage();

  // 1. Log scale + find global min/max in one pass
  var globalMin = double.maxFinite;
  var globalMax = -double.maxFinite;

  final logSpec = List.generate(numFrames, (t) {
    return Float32List.fromList(
      List.generate(numBands, (b) {
        final v = log10(max(spectrogram[t][b], 1e-6));
        if (v < globalMin) globalMin = v;
        if (v > globalMax) globalMax = v;

        return v;
      }),
    );
  });

  final range = max(globalMax - globalMin, 1e-6);

  // 2. Fill pixel buffer — RGBA bytes, row-major, Y-flipped
  //    Width = numFrames, Height = numBands
  final pixels = Uint32List(numFrames * numBands);

  for (int t = 0; t < numFrames; t++) {
    for (int b = 0; b < numBands; b++) {
      final normalized = (logSpec[t][b] - globalMin) / range;
      final row = numBands - 1 - b; // Y-flip: low freq → bottom
      final col = t;
      pixels[row * numFrames + col] = colorMap.toArgb(normalized);
    }
  }

  // 3. Decode raw RGBA bytes → ui.Image
  final byteData = pixels.buffer.asUint8List();
  final completer = Completer<ui.Image>();

  ui.decodeImageFromPixels(
    byteData,
    numFrames, // width
    numBands, // height
    ui.PixelFormat.rgba8888,
    completer.complete,
  );

  return completer.future;
}

Future<ui.Image> _emptyImage() async {
  final recorder = ui.PictureRecorder();
  Canvas(
    recorder,
  ).drawRect(const Rect.fromLTWH(0, 0, 1, 1), Paint()..color = Colors.black);
  return recorder.endRecording().toImage(1, 1);
}

double log10(double x) => log(x) / ln10;
