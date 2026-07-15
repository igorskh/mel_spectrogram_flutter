import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:integration_test/integration_test.dart';

import 'package:mel_spectrogram_flutter/mel_spectrogram_flutter.dart';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'utils.dart';

Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

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
}
