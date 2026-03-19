import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'mel_spectrogram_flutter_method_channel.dart';

abstract class MelSpectrogramFlutterPlatform extends PlatformInterface {
  /// Constructs a MelSpectrogramFlutterPlatform.
  MelSpectrogramFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static MelSpectrogramFlutterPlatform _instance = MethodChannelMelSpectrogramFlutter();

  /// The default instance of [MelSpectrogramFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelMelSpectrogramFlutter].
  static MelSpectrogramFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MelSpectrogramFlutterPlatform] when
  /// they register themselves.
  static set instance(MelSpectrogramFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
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
    throw UnimplementedError(
      'computeMelSpectrogram() has not been implemented.',
    );
  }

  Future<List<double>> decodeFile({
    required String filePath,
    int sampleRate = 44100,
  }) {
    throw UnimplementedError('decodeFile() has not been implemented.');
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
    throw UnimplementedError(
      'readAndComputeMelSpectrogram() has not been implemented.',
    );
  }

  Future<List<String>> listCaptureDevices() {
    throw UnimplementedError('listCaptureDevices() has not been implemented.');
  }
}
