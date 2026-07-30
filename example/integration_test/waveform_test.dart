import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mel_spectrogram_flutter/color_map.dart';

import 'package:mel_spectrogram_flutter/mel_spectrogram_flutter.dart';
import 'package:mel_spectrogram_flutter/waveform_placeholder.dart';
import 'package:mel_spectrogram_flutter/waveform_plot.dart';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('read and compute waveform from wav test', (
    WidgetTester tester,
  ) async {
    final plugin = MelSpectrogramFlutter();

    final outPath = p.join(
      (await getTemporaryDirectory()).path,
      'waveform.wav',
    );
    final audioFile = File(outPath);
    await audioFile.writeAsBytes(
      (await rootBundle.load('assets/test_large_96k.wav')).buffer.asUint8List(),
    );

    final sampleRate = 44100;

    var samples = await plugin.decodeFile(
      filePath: outPath,
      sampleRate: sampleRate,
    );

    expect(samples.length, greaterThan(0));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: WaveformPlot(
              waveform: samples,
              waveformSampleRateHz: sampleRate.toDouble(),
              paintedSamplesPerSecond: 10,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('test_large_96k_waveform.wav');
  });

  testWidgets('read and compute waveform from wav with bar count test', (
    WidgetTester tester,
  ) async {
    final plugin = MelSpectrogramFlutter();

    final outPath = p.join(
      (await getTemporaryDirectory()).path,
      'waveform.wav',
    );
    final audioFile = File(outPath);
    await audioFile.writeAsBytes(
      (await rootBundle.load('assets/test_large_96k.wav')).buffer.asUint8List(),
    );

    final sampleRate = 44100;

    var samples = await plugin.decodeFile(
      filePath: outPath,
      sampleRate: sampleRate,
    );

    expect(samples.length, greaterThan(0));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: WaveformPlot(
              waveform: samples,
              waveformSampleRateHz: sampleRate.toDouble(),
              paintedSamplesPerSecond: 10,
              barsCount: 100,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('test_large_96k_with_bar_count_waveform.wav');
  });

  testWidgets('waveform plaaceholder', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: WaveformPlaceholder(
              height: 200,
              barsCount: 100,
              colorMap: ColorMap.inverseGrayscale,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('test_large_96k_waveform_placeholder');
  });
}
