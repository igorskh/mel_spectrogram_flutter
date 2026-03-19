import 'mel_spectrogram_flutter_platform_interface.dart';

class MelSpectrogramFlutter {
  Future<String?> getPlatformVersion() {
    return MelSpectrogramFlutterPlatform.instance.getPlatformVersion();
  }

  Future<List<List<double>>> computeMelSpectrogram({
    required List<double> audioSamples,
    required int sampleRate,
    required int frameSize,
    required int hopSize,
    required int numBands,
    int? minFreq,
    int? maxFreq,
    double? power,
  }) {
    return MelSpectrogramFlutterPlatform.instance.computeMelSpectrogram(
      audioSamples: audioSamples,
      sampleRate: sampleRate,
      frameSize: frameSize,
      hopSize: hopSize,
      numBands: numBands,
      minFreq: minFreq,
      maxFreq: maxFreq,
      power: power,
    );
  }

  Future<List<double>> decodeFile({
    required String filePath,
    int sampleRate = 44100,
  }) {
    return MelSpectrogramFlutterPlatform.instance.decodeFile(
      filePath: filePath,
      sampleRate: sampleRate,
    );
  }

  Future<List<List<double>>> decodeFileAndComputeMelSpectrogram({
    required String filePath,
    required int sampleRate,
    required int frameSize,
    required int hopSize,
    required int numBands,
    int? minFreq,
    int? maxFreq,
    double? power,
  }) {
    return MelSpectrogramFlutterPlatform.instance
        .decodeFileAndComputeMelSpectrogram(
          filePath: filePath,
          sampleRate: sampleRate,
          frameSize: frameSize,
          hopSize: hopSize,
          numBands: numBands,
          minFreq: minFreq,
          maxFreq: maxFreq,
          power: power,
        );
  }

  Future<List<String>> listCaptureDevices() {
    return MelSpectrogramFlutterPlatform.instance.listCaptureDevices();
  }
}
