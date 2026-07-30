import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mel_spectrogram_flutter/mel_sonogram_scrollable_plot.dart';

void main() {
  testWidgets(
    'tap seek does not fire drag lifecycle callbacks',
    (tester) async {
      var dragStartCount = 0;
      var dragEndCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 120,
                child: MelSonogramScrollablePlot(
                  spectrogram: List<List<double>>.generate(
                    20,
                    (_) => List<double>.filled(8, 0.5),
                  ),
                  frameDurationSeconds: 1.0,
                  visibleSeconds: 5.0,
                  playheadPosition: 0.0,
                  onPlayheadPositionChanged: (_) {},
                  onPlayheadDragStart: () {
                    dragStartCount += 1;
                  },
                  onPlayheadDragEnd: () {
                    dragEndCount += 1;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(MelSonogramScrollablePlot));
      await tester.pump();

      expect(dragStartCount, 0);
      expect(dragEndCount, 0);
    },
  );

  testWidgets(
    'onPlayheadDragEnd waits for pointer release',
    (tester) async {
      var dragStartCount = 0;
      var dragEndCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 120,
                child: MelSonogramScrollablePlot(
                  spectrogram: List<List<double>>.generate(
                    20,
                    (_) => List<double>.filled(8, 0.5),
                  ),
                  frameDurationSeconds: 1.0,
                  visibleSeconds: 5.0,
                  playheadPosition: 0.0,
                  onPlayheadPositionChanged: (_) {},
                  onPlayheadDragStart: () {
                    dragStartCount += 1;
                  },
                  onPlayheadDragEnd: () {
                    dragEndCount += 1;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(MelSonogramScrollablePlot)),
      );
      await tester.pump();

      await gesture.moveBy(const Offset(-40, 0));
      await tester.pump();

      expect(dragStartCount, 1);
      expect(dragEndCount, 0);

      await gesture.up();
      await tester.pump();

      expect(dragEndCount, 1);
    },
  );
}