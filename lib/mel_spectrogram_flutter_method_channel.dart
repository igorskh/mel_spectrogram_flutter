import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'mel_spectrogram_flutter_platform_interface.dart';

/// An implementation of [MelSpectrogramFlutterPlatform] that uses method channels.
class MethodChannelMelSpectrogramFlutter extends MelSpectrogramFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('mel_spectrogram_flutter');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<List<List<double>>> computeMelSpectrogram({
    required List<double> audioSamples,
    required int sampleRate,
    required int frameSize,
    required int hopSize,
    required int numBands,
    int? minFreq,
    int? maxFreq,
    double? power,
  }) async {
    final samples = Float32List.fromList(audioSamples);
    final arguments = {
      'audioSamples': Platform.isIOS ? audioSamples : samples,
      'sampleRate': sampleRate,
      'frameSize': frameSize,
      'hopSize': hopSize,
      'numBands': numBands,
      'minFreq': minFreq ?? 0,
      'maxFreq': maxFreq ?? (sampleRate / 2).floor(),
      'power': power ?? 2.0,
    };

    final result = await methodChannel.invokeMethod<List<dynamic>>(
      'computeMelSpectrogram',
      arguments,
    );

    return (result ?? [])
        .map<List<double>>((row) => List<double>.from(row))
        .toList();
  }

  @override
  Future<List<double>> decodeFile({
    required String filePath,
    int sampleRate = 44100,
  }) async {
    final arguments = {'filePath': filePath, 'targetSampleRate': sampleRate};
    final result = await methodChannel.invokeMethod<List<dynamic>>(
      'decodeFile',
      arguments,
    );

    return List<double>.from(result ?? []);
  }

  @override
  Future<List<List<double>>> decodeFileAndComputeMelSpectrogram({
    required String filePath,
    required int sampleRate,
    required int frameSize,
    required int hopSize,
    required int numBands,
    int? minFreq,
    int? maxFreq,
    double? power,
  }) async {
    final arguments = {
      'filePath': filePath,
      'sampleRate': sampleRate,
      'frameSize': frameSize,
      'hopSize': hopSize,
      'numBands': numBands,
      'minFreq': minFreq ?? 0,
      'maxFreq': maxFreq ?? (sampleRate / 2).floor(),
      'power': power ?? 2.0,
    };

    final result = await methodChannel.invokeMethod<List<dynamic>>(
      'decodeFileAndComputeMelSpectrogram',
      arguments,
    );

    return (result ?? [])
        .map<List<double>>((row) => List<double>.from(row))
        .toList();
  }

  @override
  Future<List<String>> listCaptureDevices() async {
    final result = await methodChannel.invokeMethod<List<dynamic>>(
      'listCaptureDevices',
    );

    return List<String>.from(result ?? []);
  }
}
