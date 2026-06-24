// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mel_spectrogram_flutter/mel_spectrogram_flutter.dart';
import 'package:mel_spectrogram_flutter/mel_spectrogram_plot.dart';
import 'package:mel_spectrogram_flutter/waveform_plot.dart';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

void printMemory(String label) {
  final mb = (ProcessInfo.currentRss / 1024 / 1024).toStringAsFixed(2);
  // ignore: avoid_print
  print('[$label] RSS: ${mb}MB');
}

Future<void> main() async {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getPlatformVersion', (WidgetTester tester) async {
    final plugin = MelSpectrogramFlutter();
    final String? version = await plugin.getPlatformVersion();
    // The version string depends on the host platform running the test, so
    // just assert that some non-empty string is returned.
    expect(version?.isNotEmpty, true);
  });

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

  testWidgets('readAndComputeMelSpectrogram_profile', (
    WidgetTester tester,
  ) async {
    printMemory("before MelSpectrogramFlutter");
    final plugin = MelSpectrogramFlutter();
    printMemory("after MelSpectrogramFlutter");

    final outPath = p.join(
      (await getTemporaryDirectory()).path,
      'waveform.wav',
    );
    final audioFile = File(outPath);
    await audioFile.writeAsBytes(
      (await rootBundle.load('assets/test_large_96k.wav')).buffer.asUint8List(),
    );

    final sampleRate = 44100;

    for (var i = 0; i < 10; i++) {
      printMemory("before $i");
      var spec = await plugin.decodeFileAndComputeMelSpectrogram(
        filePath: outPath,
        sampleRate: sampleRate,
        frameSize: 2048,
        hopSize: 256,
        numBands: 50,
      );
      expect(spec.length, greaterThan(0));
      printMemory("after $i");
    }
  });

  testWidgets('readAndComputeMelSpectrogram_mp3', (WidgetTester tester) async {
    final plugin = MelSpectrogramFlutter();

    final outPath = p.join(
      (await getTemporaryDirectory()).path,
      'waveform.mp3',
    );
    final audioFile = File(outPath);
    await audioFile.writeAsBytes(
      (await rootBundle.load('assets/test_44k.mp3')).buffer.asUint8List(),
    );

    final sampleRate = 44100;
    final numBands = 50;
    var spec = await plugin.decodeFileAndComputeMelSpectrogram(
      filePath: outPath,
      sampleRate: sampleRate,
      frameSize: 2048,
      hopSize: 256,
      numBands: numBands,
    );
    expect(spec.length, greaterThan(0));
    expect(spec[0].length, equals(numBands));
  });

  testWidgets('MelSpectrogramPlot_mp3', (WidgetTester tester) async {
    final plugin = MelSpectrogramFlutter();

    final outPath = p.join(
      (await getTemporaryDirectory()).path,
      'waveform.mp3',
    );
    final audioFile = File(outPath);
    await audioFile.writeAsBytes(
      (await rootBundle.load('assets/test_44k.mp3')).buffer.asUint8List(),
    );

    final sampleRate = 44100;
    final numBands = 50;
    var spec = await plugin.decodeFileAndComputeMelSpectrogram(
      filePath: outPath,
      sampleRate: sampleRate,
      frameSize: 2048,
      hopSize: 256,
      numBands: numBands,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: MelSpectrogramPlot(spectrogram: spec)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('test_44k.mp3');
  });

  testWidgets('MelSpectrogramPlot_wav', (WidgetTester tester) async {
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
    final numBands = 50;
    var spec = await plugin.decodeFileAndComputeMelSpectrogram(
      filePath: outPath,
      sampleRate: sampleRate,
      frameSize: 2048,
      hopSize: 256,
      numBands: numBands,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: MelSpectrogramPlot(spectrogram: spec)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('test_large_96k.wav');
  });

  testWidgets('decodeFile', (WidgetTester tester) async {
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
  });

  testWidgets('computeMelSpectrogram', (WidgetTester tester) async {
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

    final numBands = 60;
    var spec = await plugin.computeMelSpectrogram(
      audioSamples: samples,
      sampleRate: sampleRate,
      frameSize: 2048,
      hopSize: 256,
      numBands: numBands,
    );
    expect(spec.length, greaterThan(0));
    expect(spec[0].length, equals(numBands));
  });
}
