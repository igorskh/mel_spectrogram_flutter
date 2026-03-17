import 'package:flutter_test/flutter_test.dart';
import 'package:mel_spectrogram_flutter/mel_spectrogram_flutter.dart';
import 'package:mel_spectrogram_flutter/mel_spectrogram_flutter_platform_interface.dart';
import 'package:mel_spectrogram_flutter/mel_spectrogram_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMelSpectrogramFlutterPlatform
    with MockPlatformInterfaceMixin
    implements MelSpectrogramFlutterPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final MelSpectrogramFlutterPlatform initialPlatform = MelSpectrogramFlutterPlatform.instance;

  test('$MethodChannelMelSpectrogramFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelMelSpectrogramFlutter>());
  });

  test('getPlatformVersion', () async {
    MelSpectrogramFlutter melSpectrogramFlutterPlugin = MelSpectrogramFlutter();
    MockMelSpectrogramFlutterPlatform fakePlatform = MockMelSpectrogramFlutterPlatform();
    MelSpectrogramFlutterPlatform.instance = fakePlatform;

    expect(await melSpectrogramFlutterPlugin.getPlatformVersion(), '42');
  });
}
