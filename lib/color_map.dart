
// ─────────────────────────────────────────────────────────────────────────────
// Color maps  (mirrors heatmapColor / grayscaleColor)
// ─────────────────────────────────────────────────────────────────────────────

enum ColorMap {
  /// Black → white  (mirrors Kotlin `grayscaleColor`)
  grayscale,

  /// White → black (inverse of `grayscaleColor`, for testing)
  inverseGrayscale,

  /// Dark blue → cyan → yellow → white  (mirrors Kotlin `heatmapColor`)
  heatmap;

  /// Returns a packed RGBA int for [v] ∈ [0, 1].
  int toArgb(double v) {
    switch (this) {
      case ColorMap.grayscale:
        return _grayscaleColor(v);
      case ColorMap.heatmap:
        return _heatmapColor(v);
      case ColorMap.inverseGrayscale:
        return _inverseGrayscaleColor(v);
    }
  }
}

/// `grayscaleColor`: [0,1] → RGBA black→white
int _grayscaleColor(double v) {
  final f = v.clamp(0.0, 1.0);
  final c = (255 * f).toInt();
  // RGBA8888: R=c, G=c, B=c, A=255
  return (c) | (c << 8) | (c << 16) | (0xFF << 24);
}

/// Inverse grayscale: [0,1] → RGBA white→black
int _inverseGrayscaleColor(double v) {
  final f = v.clamp(0.0, 1.0);
  final c = (255 * (1.0 - f)).toInt(); // <-- invert here
  // RGBA8888: R=c, G=c, B=c, A=255
  return (c) | (c << 8) | (c << 16) | (0xFF << 24);
}

/// `heatmapColor`: [0,1] → RGBA dark-blue→cyan→yellow→white
int _heatmapColor(double v) {
  final f = v.clamp(0.0, 1.0);
  final r = ((255 * (f * 2.0 - 1.0).clamp(0.0, 1.0))).toInt();
  final g = ((255 * (1.0 - (2.0 * f - 1.0).abs()))).toInt();
  final b = ((255 * (1.0 - (f * 2.0 - 1.0).clamp(0.0, 1.0)))).toInt();
  // RGBA8888
  return (r) | (g << 8) | (b << 16) | (0xFF << 24);
}
