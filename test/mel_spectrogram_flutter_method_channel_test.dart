import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mel_spectrogram_flutter/mel_spectrogram_flutter_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelMelSpectrogramFlutter platform = MethodChannelMelSpectrogramFlutter();
  const MethodChannel channel = MethodChannel('mel_spectrogram_flutter');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return '42';
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
