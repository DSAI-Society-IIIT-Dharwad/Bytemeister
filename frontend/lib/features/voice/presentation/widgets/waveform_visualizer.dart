import 'package:flutter/material.dart';

class WaveformVisualizer extends CustomPainter {
  final List<double> data;
  final Color color;

  WaveformVisualizer({required this.data, this.color = Colors.deepPurple});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final centerY = size.height / 2;
    final spacing = size.width / (data.isNotEmpty ? data.length : 1);

    for (int i = 0; i < data.length; i++) {
      // Normalize amplitude (assuming dB from record package)
      // Record package dB is usually -160 to 0
      final normalizedValue = (data[i] + 160) / 160;
      final barHeight = normalizedValue * size.height * 0.8;

      canvas.drawLine(
        Offset(i * spacing, centerY - barHeight / 2),
        Offset(i * spacing, centerY + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
