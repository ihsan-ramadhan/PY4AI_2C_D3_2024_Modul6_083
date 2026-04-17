import 'package:flutter/material.dart';

class DamagePainter extends CustomPainter {
  final double rawX;
  final double rawY;
  final double qualityScore;

  DamagePainter({
    required this.rawX,
    required this.rawY,
    required this.qualityScore,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;

    double boxSize = size.width * 0.4;
    
    double centerX = rawX * size.width;
    double centerY = rawY * size.height;

    double left = centerX - (boxSize / 2);
    double top = centerY - (boxSize / 2);
    
    if (left < 0) left = 0;
    if (top < 0) top = 0;
    if (left + boxSize > size.width) left = size.width - boxSize;
    if (top + boxSize > size.height) top = size.height - boxSize;

    final rect = Rect.fromLTWH(left, top, boxSize, boxSize);

    bool isSevere = qualityScore > 0.7;
    Color severityColor = isSevere ? Colors.redAccent : Colors.yellowAccent;
    String damageLabel = isSevere ? "[D40] POTHOLE" : "[D00] LONG CRACK";

    final paint = Paint()
      ..color = severityColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    canvas.drawRect(rect, paint);

    int percentage = (qualityScore * 100).round();
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.bold,
      backgroundColor: severityColor,
      shadows: const [
        Shadow(
          offset: Offset(1.0, 1.0),
          blurRadius: 3.0,
          color: Colors.black87,
        ),
      ],
    );

    final textSpan = TextSpan(
      text: " $damageLabel - $percentage% ", 
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    
    double textTop = top - 25;
    if (textTop < 0) {
      textTop = top + boxSize + 5;
    }

    textPainter.paint(canvas, Offset(left, textTop));
  }

  @override
  bool shouldRepaint(covariant DamagePainter oldDelegate) {
    return oldDelegate.rawX != rawX || oldDelegate.rawY != rawY;
  }
}
