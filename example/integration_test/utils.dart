import 'dart:io' show ProcessInfo;

void printMemory(String label) {
  final mb = (ProcessInfo.currentRss / 1024 / 1024).toStringAsFixed(2);
  // ignore: avoid_print
  print('[$label] RSS: ${mb}MB');
}
