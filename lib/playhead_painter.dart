import 'package:flutter/material.dart';

class PlayheadPainter extends CustomPainter {
  final double playheadPosition; // 0 to 1
  final Color playheadColor;

  PlayheadPainter(this.playheadPosition, this.playheadColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = playheadColor
      ..strokeWidth = 2.0;
    final x = playheadPosition.clamp(0, 1) * size.width;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
  }

  @override
  bool shouldRepaint(PlayheadPainter old) =>
      old.playheadPosition != playheadPosition;
}
