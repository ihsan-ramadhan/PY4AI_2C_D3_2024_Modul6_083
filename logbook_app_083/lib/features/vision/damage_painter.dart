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

    // 2. Menghitung Dimensi Kotak Responsif (Scaled)
    // Membuat kotak seukuran 40% dari lebar layar
    double boxSize = size.width * 0.4;
    
    // Transformasi Koordinat Normalisasi (0.0 - 1.0) ke Logical Pixels Layar
    double centerX = rawX * size.width;
    double centerY = rawY * size.height;

    double left = centerX - (boxSize / 2);
    double top = centerY - (boxSize / 2);
    
    // Mencegah box meluber keluar tepi layar (UX Enhancement)
    if (left < 0) left = 0;
    if (top < 0) top = 0;
    if (left + boxSize > size.width) left = size.width - boxSize;
    if (top + boxSize > size.height) top = size.height - boxSize;

    final rect = Rect.fromLTWH(left, top, boxSize, boxSize);

    // Styling Konfigurasi Berdasarkan Skor/Level (Homework: Detection Style & Color Branding)
    bool isSevere = qualityScore > 0.7;
    Color severityColor = isSevere ? Colors.redAccent : Colors.yellowAccent;
    String damageLabel = isSevere ? "[D40] POTHOLE" : "[D00] LONG CRACK";

    // 1. Konfigurasi "Kuas" Digital
    final paint = Paint()
      ..color = severityColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke; // Garis pinggir saja

    // 3. Menggambar Bounding Box
    canvas.drawRect(rect, paint);

    // 4. Konstruksi Label Tipe Kerusakan
    int percentage = (qualityScore * 100).round();
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.bold,
      backgroundColor: severityColor,
      shadows: const [
        Shadow( // Efek bayangan / Shadow (Homework)
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

    // 5. Proses Layouting & Rendering Teks
    textPainter.layout();
    
    // Logika agar teks tidak terpotong tepi layar atas
    double textTop = top - 25;
    if (textTop < 0) {
      textTop = top + boxSize + 5; // Pindah ke bawah kotak
    }

    textPainter.paint(canvas, Offset(left, textTop));
  }

  @override
  bool shouldRepaint(covariant DamagePainter oldDelegate) {
    // Mengembalikan true karena kita punya timer dinamis yang mengubah posisi
    return oldDelegate.rawX != rawX || oldDelegate.rawY != rawY;
  }
}
