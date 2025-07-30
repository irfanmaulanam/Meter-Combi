import 'package:flutter/material.dart';
import 'dart:math' as math; // Menggunakan alias 'math'
import 'package:google_fonts/google_fonts.dart'; // Untuk menggunakan font kustom

class MainGauge extends StatelessWidget {
  final double speedKmhValue; // Nilai kecepatan (km/h) yang akan ditampilkan dan menggerakkan progress fill
  final double maxSpeedKmh;    // Nilai kecepatan maksimum pada skala speedometer (misal 200 km/h)

  const MainGauge({
    super.key, // Konstruktor modern
    required this.speedKmhValue,
    this.maxSpeedKmh = 200.0, // Batas kecepatan dari gambar referensi terbaru (0-200)
  });

  @override
  Widget build(BuildContext context) {
    // CustomPaint adalah widget yang memungkinkan kita menggambar grafis kustom menggunakan Canvas
    return CustomPaint(
      // Ukuran area gambar untuk speedometer: Lebar 280, Tinggi 140
      size: const Size(650, 350),
      // Painter yang bertanggung jawab untuk menggambar visual speedometer
      painter: _MainGaugePainter(
        speedKmhValue: speedKmhValue, // Meneruskan nilai kecepatan ke painter
        maxSpeedKmh: maxSpeedKmh,     // Meneruskan nilai kecepatan maksimum ke painter
      ),
    );
  }
}

// Painter kustom untuk menggambar speedometer
class _MainGaugePainter extends CustomPainter {
  final double speedKmhValue; // Nilai kecepatan aktual yang diterima
  final double maxSpeedKmh;    // Nilai maksimum skala speedometer

  _MainGaugePainter({
    required this.speedKmhValue,
    required this.maxSpeedKmh,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Pusat lingkaran: di bagian tengah bawah area gambar CustomPaint.
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;
    const strokeWidth = 30.0; // Ketebalan garis busur

    // --- Definisi Sudut untuk Busur Setengah Lingkaran ---
    final startAngle = math.pi;
    final totalSweepAngle = math.pi;

    // --- Menghitung Warna Dinamis untuk Progress Fill ---
    final double normalizedSpeed = (speedKmhValue / maxSpeedKmh).clamp(0.0, 1.0);
    final Color activeArcColor = _getDynamicColorForSpeed(normalizedSpeed);

    // --- 1. Busur Latar Belakang (Tidak Aktif) ---
    final backgroundStaticPaint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(0.1);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      startAngle,
      totalSweepAngle,
      false,
      backgroundStaticPaint,
    );

    // --- 2. Busur Aktif (Progress Fill) ---
    final fillSweepAngle = totalSweepAngle * normalizedSpeed;

    final activeFillPaint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = activeArcColor;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      startAngle,
      fillSweepAngle,
      false,
      activeFillPaint,
    );

    // --- 3. Tick Marks (Tanda Skala) ---
    final numMajorTicks = (maxSpeedKmh / 20).ceil();
    final numMinorTicks = 4;

    final tickPaint = Paint()
      ..color = Colors.white.withOpacity(0.5) // Warna tick
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Jarak angka dari pusat busur (sekarang tidak dipakai untuk angka, hanya untuk posisi tick)
    final numberRadius = radius - strokeWidth - 10;

    for (var i = 0; i <= numMajorTicks * (numMinorTicks + 1); i++) {
      final value = i * (maxSpeedKmh / (numMajorTicks * (numMinorTicks + 1)));
      if (value > maxSpeedKmh) continue;

      final angle = startAngle + totalSweepAngle * (value / maxSpeedKmh);
      final isMajorTick = i % (numMinorTicks + 1) == 0;
      final tickLength = isMajorTick ? 10.0 : 5.0; // Panjang major tick lebih panjang

      // Menggambar garis tick (tetap ada)
      final outerPoint = center + Offset(radius * math.cos(angle), radius * math.sin(angle));
      final innerPoint = center + Offset((radius - tickLength) * math.cos(angle), (radius - tickLength) * math.sin(angle));
      canvas.drawLine(innerPoint, outerPoint, tickPaint);

      // --- HILANGKAN ANGKA SKALA: BLOK IF (isMajorTick) DIHAPUS/DIKOMENTARI ---
      // if (isMajorTick) {
      //   final textPainter = TextPainter(
      //     text: TextSpan(
      //       text: value.toInt().toString(),
      //       style: GoogleFonts.poppins(
      //         fontSize: 14,
      //         fontWeight: FontWeight.w500,
      //         color: Colors.white,
      //       ),
      //     ),
      //     textDirection: TextDirection.ltr,
      //   );
      //   textPainter.layout();
      //   final textOffset = Offset(
      //       (numberRadius) * math.cos(angle),
      //       (numberRadius) * math.sin(angle));
      //   textPainter.paint(canvas, textOffset - Offset(textPainter.width / 2, textPainter.height / 2));
      // }
      // --- AKHIR PENGHILANGAN ---
    }

    // --- 4. Jarum Speedometer (dihilangkan) ---
    // Tidak ada jarum sesuai permintaan sebelumnya.

    // --- 5. Speed Value Text (Angka Kecepatan Besar di Tengah) ---
    final speedTextPainter = TextPainter(
      text: TextSpan(
        text: speedKmhValue.toInt().toString(),
        style: GoogleFonts.poppins(
          fontSize: 76,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    speedTextPainter.layout();
    speedTextPainter.paint(canvas, Offset(center.dx - speedTextPainter.width / 2, center.dy - radius / 2 - speedTextPainter.height / 2));

    // --- 6. "km/h" Text ---
    const unitText = 'km/h';
    final unitTextPainter = TextPainter(
      text: TextSpan(
        text: unitText,
        style: GoogleFonts.poppins(
          fontSize: 32,
          color: Colors.white.withOpacity(0.7),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    unitTextPainter.layout();
    unitTextPainter.paint(canvas, Offset(center.dx - unitTextPainter.width / 2, center.dy - radius / 2 + speedTextPainter.height / 2 - 5));

    // --- 7. Angka 0 di Bawah Tengah (INI SUDAH DIHAPUS DARI KONTEKS SEBELUMNYA) ---
    // --- 8. Teks Waktu di Bawah Speedometer (INI JUGA SUDAH DIHAPUS DARI KONTEKS SEBELUMNYA) ---
    // --- 9. Teks SPORT di Atas Tengah (INI JUGA SUDAH DIHAPUS DARI KONTEKS SEBELUMNYA) ---
  }

  @override
  bool shouldRepaint(covariant _MainGaugePainter oldDelegate) {
    return oldDelegate.speedKmhValue != speedKmhValue;
  }
}

// Fungsi helper untuk mendapatkan warna dinamis berdasarkan nilai kecepatan (0.0 - 1.0)
Color _getDynamicColorForSpeed(double t) {
  const double threshold1 = 50.0 / 200.0;
  const double threshold2 = 100.0 / 200.0;

  const Color lightBlue = Color(0xFF87CEFA);
  const Color mediumBlue = Color(0xFF1E90FF);
  const Color darkBlue = Color(0xFF0000CD);
  const Color veryDarkBlue = Color(0xFF00008B);

  if (t <= threshold1) {
    return Color.lerp(lightBlue, mediumBlue, t / threshold1)!;
  } else if (t <= threshold2) {
    return Color.lerp(mediumBlue, darkBlue, (t - threshold1) / (threshold2 - threshold1))!;
  } else {
    return Color.lerp(darkBlue, veryDarkBlue, (t - threshold2) / (1.0 - threshold2))!;
  }
}
