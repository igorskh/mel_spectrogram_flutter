# MEL Sonogram Flutter Plugin

Flutter plugin for decoding audio and generating mel spectrograms on-device,
with ready-to-use widgets for rendering sonograms and an interactive playhead.

## Features

- Decode audio files (`mp3`, `wav`, etc.) to PCM samples.
- Compute mel spectrograms from raw samples or directly from a file.
- Render static spectrograms with `MelSpectrogramPlot`.
- Render centered-playhead, horizontally scrollable spectrograms with
	`MelSonogramScrollablePlot`.
- Interactive seeking via tap/drag callbacks.

## Installation

Add the dependency to your app:

```yaml
dependencies:
	mel_spectrogram_flutter: ^0.0.4
```

Then run:

```bash
flutter pub get
```

## Quick Start

### 1) Import package APIs

```dart
import 'package:mel_spectrogram_flutter/mel_spectrogram_flutter.dart';
import 'package:mel_spectrogram_flutter/mel_spectrogram_plot.dart';
import 'package:mel_spectrogram_flutter/mel_sonogram_scrollable_plot.dart';
import 'package:mel_spectrogram_flutter/color_map.dart';
```

### 2) Compute a spectrogram from an audio file

```dart
final plugin = MelSpectrogramFlutter();

final spectrogram = await plugin.decodeFileAndComputeMelSpectrogram(
	filePath: '/absolute/path/to/audio.wav',
	sampleRate: 44100,
	frameSize: 1024,
	hopSize: 256,
	numBands: 80,
	minFreq: 20,
	maxFreq: 16000,
	power: 2.0,
);
```

`spectrogram` shape is `[frame][band]`.

## Usage Examples

### Static spectrogram plot

```dart
class StaticSpecView extends StatefulWidget {
	const StaticSpecView({super.key});

	@override
	State<StaticSpecView> createState() => _StaticSpecViewState();
}

class _StaticSpecViewState extends State<StaticSpecView> {
	final plugin = MelSpectrogramFlutter();
	List<List<double>>? spectrogram;
	double playhead = 0.25;

	@override
	void initState() {
		super.initState();
		_load();
	}

	Future<void> _load() async {
		final spec = await plugin.decodeFileAndComputeMelSpectrogram(
			filePath: '/absolute/path/to/audio.wav',
			sampleRate: 44100,
			frameSize: 1024,
			hopSize: 256,
			numBands: 80,
		);
		if (!mounted) return;
		setState(() => spectrogram = spec);
	}

	@override
	Widget build(BuildContext context) {
		if (spectrogram == null) return const CircularProgressIndicator();

		return MelSpectrogramPlot(
			spectrogram: spectrogram!,
			height: 220,
			colorMap: ColorMap.heatmap,
			playheadPosition: playhead, // 0..1
			onPlayheadPositionChanged: (pos) {
				setState(() => playhead = pos);
			},
		);
	}
}
```

### Scrollable centered playhead sonogram

`MelSonogramScrollablePlot` keeps the playhead line in the middle of the
widget. The spectrogram scrolls under it.

- `playheadPosition = 0.0` means start of audio (0 seconds).
- `playheadPosition = 1.0` means end of audio.

```dart
class ScrollableSpecView extends StatefulWidget {
	const ScrollableSpecView({super.key});

	@override
	State<ScrollableSpecView> createState() => _ScrollableSpecViewState();
}

class _ScrollableSpecViewState extends State<ScrollableSpecView> {
	final plugin = MelSpectrogramFlutter();
	List<List<double>>? spectrogram;

	// Controlled by your player progress, range 0..1.
	double playheadPosition = 0.0;

	// Parameters used for spectrogram generation.
	static const int sampleRate = 44100;
	static const int hopSize = 256;

	@override
	void initState() {
		super.initState();
		_load();
	}

	Future<void> _load() async {
		final spec = await plugin.decodeFileAndComputeMelSpectrogram(
			filePath: '/absolute/path/to/audio.wav',
			sampleRate: sampleRate,
			frameSize: 1024,
			hopSize: hopSize,
			numBands: 80,
		);
		if (!mounted) return;
		setState(() => spectrogram = spec);
	}

	@override
	Widget build(BuildContext context) {
		if (spectrogram == null) return const CircularProgressIndicator();

		return MelSonogramScrollablePlot(
			spectrogram: spectrogram!,
			frameDurationSeconds: hopSize / sampleRate,
			visibleSeconds: 6.0,
			height: 220,
			colorMap: ColorMap.heatmap,
			playheadPosition: playheadPosition,
			onPlayheadPositionChanged: (pos) {
				// Seek your player here and update state.
				setState(() => playheadPosition = pos);
			},
		);
	}
}
```

## API Notes

- `computeMelSpectrogram(...)`: build spectrogram from PCM samples.
- `decodeFile(...)`: decode file to PCM samples.
- `decodeFileAndComputeMelSpectrogram(...)`: decode + compute in one call.
- `listCaptureDevices()`: list available capture devices on supported
	platforms.

Color maps:

- `ColorMap.grayscale`
- `ColorMap.inverseGrayscale`
- `ColorMap.heatmap`

## Run integration tests

Integration tests are implemented in `example/`.

```bash
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/plugin_integration_test.dart
```