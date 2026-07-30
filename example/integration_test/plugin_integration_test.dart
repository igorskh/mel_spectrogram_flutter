import 'memory_test.dart' as memory_test;
import 'sonogram_test.dart' as sonogram_test;
import 'waveform_test.dart' as waveform_test;

Future<void> main() async {
  memory_test.main();
  sonogram_test.main();
  waveform_test.main();
}
