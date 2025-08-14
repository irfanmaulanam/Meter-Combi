import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../widgets/main_gauge.dart';
import '../models/sensordata.dart';
import '../services/data_services.dart'; // Import data_services.dart (dengan 's')

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _BottomBarBackgroundPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;

  _BottomBarBackgroundPainter({
    required this.fillColor,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // --- Definisi Path untuk bentuk custom ---
    final path = Path();
    // Sesuaikan nilai ini untuk mengubah kemiringan atau bentuk ujungnya
    // Nilai lebih besar akan membuat sudut lebih tajam/miring ke dalam
    double cornerBevel = 59.0; // Potongan sudut atas (lebih besar dari 15)
    double sideSlope = 20.0; // Kemiringan sisi ke dalam di bagian bawah (lebih besar dari 15)

    // --- Efek Glow (Digambar di BELAKANG bentuk utama) ---
    // Gambar path yang sedikit lebih besar dan transparan untuk efek cahaya
    final glowPath = Path();
    double glowBevel = cornerBevel + 5.0; // Bevel glow sedikit lebih besar
    double glowSlope = sideSlope + 5.0; // Slope glow sedikit lebih besar

    glowPath.moveTo(glowBevel, 0);
    glowPath.lineTo(size.width - glowBevel, 0);
    glowPath.lineTo(size.width - glowSlope, size.height);
    glowPath.lineTo(glowSlope, size.height);
    glowPath.close();

    final glowPaint = Paint()
      ..color = Colors.blue.withOpacity(0.15) // Warna biru transparan untuk glow
      ..style = PaintingStyle.fill;
    canvas.drawPath(glowPath, glowPaint);


    // --- Bentuk Utama (Digambar di ATAS efek glow) ---
    path.moveTo(cornerBevel, 0); // Mulai dari kiri atas (setelah dipotong)
    path.lineTo(size.width - cornerBevel, 0); // Ke kanan atas (setelah dipotong)
    path.lineTo(size.width - sideSlope, size.height); // Ke kanan bawah
    path.lineTo(sideSlope, size.height); // Ke kiri bawah
    path.close(); // Tutup path

    // Gambar isi (fill)
    final fillPaint = Paint()..color = fillColor..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Gambar border (garis tepi)
    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _BottomBarBackgroundPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth;
  }
}

// Lokasi: lib/screens/dashboard_screen.dart (setelah _buildStatusIndicator class)
class _TopBarBackgroundPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;

  _TopBarBackgroundPainter({
    required this.fillColor,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // --- Definisi Path untuk bentuk custom ---
    final path = Path();
    // Sesuaikan nilai ini untuk mengubah kemiringan atau bentuk ujungnya
    // Nilai lebih besar akan membuat sudut lebih tajam/miring ke dalam
    double cornerBevel = 59.0; // Potongan sudut atas (lebih besar dari 15)
    double sideSlope = 20.0; // Kemiringan sisi ke dalam di bagian bawah (lebih besar dari 15)

    // --- Efek Glow (Digambar di BELAKANG bentuk utama) ---
    // Gambar path yang sedikit lebih besar dan transparan untuk efek cahaya
    final glowPath = Path();
    double glowBevel = cornerBevel + 5.0; // Bevel glow sedikit lebih besar
    double glowSlope = sideSlope + 5.0; // Slope glow sedikit lebih besar

    glowPath.moveTo(glowBevel, 0);
    glowPath.lineTo(size.width - glowBevel, 0);
    glowPath.lineTo(size.width - glowSlope, size.height);
    glowPath.lineTo(glowSlope, size.height);
    glowPath.close();

    final glowPaint = Paint()
      ..color = Colors.blue.withOpacity(0.15) // Warna biru transparan untuk glow
      ..style = PaintingStyle.fill;
    canvas.drawPath(glowPath, glowPaint);


    // --- Bentuk Utama (Digambar di ATAS efek glow) ---
    path.moveTo(cornerBevel, 0); // Mulai dari kiri atas (setelah dipotong)
    path.lineTo(size.width - cornerBevel, 0); // Ke kanan atas (setelah dipotong)
    path.lineTo(size.width - sideSlope, size.height); // Ke kanan bawah
    path.lineTo(sideSlope, size.height); // Ke kiri bawah
    path.close(); // Tutup path

    // Gambar isi (fill)
    final fillPaint = Paint()..color = fillColor..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Gambar border (garis tepi)
    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _TopBarBackgroundPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth;
  }
}


class _DashboardScreenState extends State<DashboardScreen> {
  late SensorData _currentData; // Variabel untuk menyimpan data sensor terbaru
  // Timer? _timer; // Tidak lagi diperlukan untuk polling, diganti dengan stream
  final DataService _dataService = DataService(); // Menggunakan DataService (serial-based)
  String _errorMessage = ''; // Untuk menampilkan pesan error serial

  // Variabel untuk simulasi instantFuelConsumption (tetap ada, karena tidak dari sensor)
  double _instantFuelConsumption = 0.0;
  DateTime _currentTime = DateTime.now(); // <<< TAMBAH: Variabel untuk menyimpan waktu saat ini
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _currentData = SensorData.initial(); // Inisialisasi data awal

    // <<< PERUBAHAN UTAMA DI SINI: MEMULAI MENDENGARKAN SERIAL DAN BERLANGGANAN STREAM >>>
    try {
      _dataService.startListening(); // Memulai proses mendengarkan port serial
      //_errorMessage = 'Serial Port: ${_dataService.status}'; // Tampilkan status awal

      // Berlangganan (subscribe) ke setiap stream data yang dipancarkan oleh DataService
      // Setiap kali ada data baru dari stream, setState akan dipanggil untuk update UI
      _dataService.speedStream.listen((value) {
        if (mounted) setState(() => _currentData.speed = value);
      }, onError: (e) => _handleSerialError(e)); // Penanganan error per stream

      _dataService.temperatureStream.listen((value) {
        if (mounted) setState(() => _currentData.temperature = value);
      }, onError: (e) => _handleSerialError(e));

      _dataService.levelStream.listen((value) {
        if (mounted) setState(() => _currentData.level = value);
      }, onError: (e) => _handleSerialError(e));

      _dataService.pressureStream.listen((value) {
        if (mounted) setState(() => _currentData.pressure = value);
      }, onError: (e) => _handleSerialError(e));

      _dataService.voltageStream.listen((value) {
        if (mounted) setState(() => _currentData.voltage = value);
      }, onError: (e) => _handleSerialError(e));

      _dataService.brakeStream.listen((value) {
        if (mounted) setState(() => _currentData.brake = value);
      }, onError: (e) => _handleSerialError(e));

      _dataService.absStream.listen((value) {
        if (mounted) setState(() => _currentData.abs = value);
      }, onError: (e) => _handleSerialError(e));

      _dataService.airbagStream.listen((value) {
        if (mounted) setState(() => _currentData.airbag = value);
      }, onError: (e) => _handleSerialError(e));

      _dataService.seatbeltStream.listen((value) {
        if (mounted) setState(() => _currentData.seatbelt = value);
      }, onError: (e) => _handleSerialError(e));

    } catch (e) {
      _errorMessage = 'Gagal memulai serial: $e'; // Menangkap error saat startListening()
      print(_errorMessage);
    }
    // <<< AKHIR PERUBAHAN INITSTATE >>>
    _startClockTimer();
  }
  void _startClockTimer() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now(); // Update waktu saat ini
        });
      }
    });
  }
  // Fungsi untuk menangani error dari stream serial
  void _handleSerialError(dynamic error) {
    if (mounted)

    {
      setState(() {
        _errorMessage = 'Serial Error: ${error.toString()}';
      });
    }
  }

  // Fungsi _startFetchingData dan _fetchData (polling) tidak lagi diperlukan, bisa dihapus
  // double _clamp tetap dibutuhkan
  double _clamp(double value, double min, double max) {
    return value.clamp(min, max);
  }

  @override
  void dispose() {
    // PENTING: Panggil dispose pada layanan serial saat widget dibuang
    _dataService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hitung instantFuelConsumption di sini karena _currentData.speed diupdate oleh stream
    _instantFuelConsumption = _clamp(_currentData.speed * 0.1 + 5, 5, 20);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF101015),
          image: DecorationImage(
            image: AssetImage('assets/images/background.jpg'),
            fit: BoxFit.cover,
            opacity: 0.25,
          ),
        ),
        child: Stack(
          children: [
            // Tampilan Error Message (jika ada error serial)
            if (_errorMessage.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            Positioned(
              top: 10, // Posisi vertikal
              left: 0, // Mengisi lebar penuh untuk memusatkan
              right: 0, // Mengisi lebar penuh untuk memusatkan
              child: Center( // Pusatkan Stack secara horizontal
                child: Stack( // <<< TAMBAH: Bungkus dengan Stack
                  alignment: Alignment.center, // Pusatkan children Stack
                  children: [
                    // Lapisan bawah: Background kotak custom (CustomPaint)
                   // CustomPaint(
                      // Ukuran CustomPaint akan disesuaikan agar cocok dengan Padding dan Row
                      // Berikan ukuran yang cukup untuk menampung teks dan padding
                   //   size: const Size(380, 40), // <<< SESUAIKAN UKURAN INI (Lebar, Tinggi)
                     // painter: _TopBarBackgroundPainter(
                     //   fillColor: const Color(0xFF1A1A1A), // Warna isi kotak (sama dengan background)
                     //   borderColor: Colors.white.withOpacity(0.5), // Warna border (putih transparan)
                     //   borderWidth: 1.0, // Ketebalan border
                     // ),
                   // ),
                    // Lapisan atas: Teks Tanggal, Jam, Suhu
                    Padding( // Tambahkan Padding untuk memberi ruang antara teks dan border kotak
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0), // Sesuaikan padding
                      child: Row(
                        mainAxisSize: MainAxisSize.min, // Agar Row hanya mengambil lebar kontennya
                        children: [
                          const SizedBox(width: 15),
                          Text(
                            '${_currentTime.hour.toString().padLeft(2, '0')}.'
                                '${_currentTime.minute.toString().padLeft(2, '0')}',
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ), // <<< AKHIR STACK
              ),
            ),
            // Top Left: Instant Fuel Consumption
            // Left: Suhu
            Positioned(
              bottom: 20,
              left: 20,
              child: Row(
                children: [
                  const Icon(Icons.thermostat_outlined, color: Color.fromARGB(255, 255, 255, 255), size: 24),
                  const SizedBox(width: 8),
                  Text(
                    '${_currentData.temperature.toStringAsFixed(1)}°C',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Tengah: Main Gauge (Speedometer)
            Center(
              child: Transform.translate(
                offset: const Offset(0.0, -90.0),
                child: MainGauge(
                  speedKmhValue: _currentData.speed, // Meneruskan nilai kecepatan dari data serial
                ),
              ),
            ),

            // Gambar Mobil di Tengah
            Positioned(
              bottom: 50,
              left: 0, right: 0,
              child: Center(
                child: Image.asset(
                  'assets/images/yariscross.png',
                  height: 230,
                  fit: BoxFit.contain,
                 // color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),

            // Fuel Indicator: Horizontal Bar
            Positioned(
              bottom: 20,
              right: 250,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/images/fuel.svg',
                      colorFilter: const ColorFilter.mode(Color(0xFFFCFCFC), BlendMode.srcIn),
                      width: 25, height: 25,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 150, height: 20,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 150 * (_currentData.level / 100.0).clamp(0.0, 1.0),
                          height: 30,
                          decoration: BoxDecoration(color: const Color(
                              0xFF0066FF), borderRadius: BorderRadius.circular(5)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'F',
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0, // Posisi dari bawah layar
              left: 0, right: 0, // Pusatkan secara horizontal
              child: Center(
                child: Stack( // <<< GANTI CONTAINER INI DENGAN STACK >>>
                  alignment: Alignment.center, // Pusatkan children Stack
                  children: [
                    // Lapisan bawah: Background kotak custom (CustomPaint)
                    CustomPaint(
                      // SESUAIKAN UKURAN KOTAK INI AGAR CUKUP MENAMPUNG TEKS PRND
                      // Lebar sekitar 380-400 mungkin diperlukan karena letterSpacing dan padding
                      size: const Size(590, 60), // <<< Sesuaikan ukuran ini
                      painter: _TopBarBackgroundPainter( // REUSE _TopBarBackgroundPainter
                        fillColor: Colors.black.withOpacity(1), // Warna isi kotak
                        borderColor: Colors.white.withOpacity(0.0), // Warna border
                        borderWidth: 1.0,
                      ),
                    ),
                    // Lapisan atas: Teks PRND (dengan Padding)
                    Padding( // Tambahkan Padding untuk memberi ruang antara teks dan border kotak
                      padding: const EdgeInsets.symmetric(horizontal: 120.0, vertical: 5.0), // Padding yang sama seperti sebelumnya
                      child: RichText( // Isi RichText seperti sebelumnya
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'P R N ',
                              style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.5), fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 10.0,),
                            ),
                            TextSpan(
                              text: 'D',
                              style: GoogleFonts.poppins(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold,letterSpacing: 10.0,),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ), // <<< AKHIR STACK
              ),
            ),
            // Odometer (Static Text)
            Positioned(
              bottom: 50,
              right: 325,// Posisikan di kanan
              child: RichText( // <<< UBAH DARI 'Text' MENJADI 'RichText'
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'ODO 174 ', // Bagian "ODO 174"
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: 'km', // Bagian "km" dengan gaya berbeda
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16, // Ukuran font lebih kecil
                        fontWeight: FontWeight.normal, // Ketebalan font normal
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom Status Indicators: Rem, ABS, Airbag, Sabuk
            Positioned(
              bottom: 80,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.translate(
                    offset: const Offset(-240.0, -550.0),
                    child: _buildStatusIndicator('HANDBRAKE', _currentData.brake, Colors.red),
                  ),
                  const SizedBox(width: 15),
                  Transform.translate(
                    offset: const Offset(-260.0, -510.0),
                    child: _buildStatusIndicator('ABS', _currentData.abs, Colors.red),
                  ),
                  Transform.translate(
                      offset: const Offset(-995.0, -550),
                      child: _buildStatusIndicator('AIRBAG', _currentData.airbag, Colors.red),
                  ),
                  const SizedBox(width: 15),
                  Transform.translate(
                      offset: const Offset(-1095.0,-510),
                      child : _buildStatusIndicator('SEATBELT', _currentData.seatbelt, Colors.red),
                  )

                ],
              ),
            ),

            // Bottom Left: Pressure dan Voltage
            Positioned(
              bottom: 10,
              left: 250,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Kolom untuk Tekanan
                  Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 30.0 + 4.0),
                        child: SizedBox(
                          width: 100.0,
                          child: Text(
                            '${_currentData.pressure.toStringAsFixed(1)} psi',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.7), fontSize: 20),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0, left: 0, right: 0,
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/images/tire_pressure.svg',
                            colorFilter: ColorFilter.mode(const Color(
                                0xFFFFFFFF), BlendMode.srcIn),
                            width: 30, height: 30,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),

                  // Kolom untuk Tegangan
                  Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 30.0 + 4.0),
                        child: SizedBox(
                          width: 100.0,
                          child: Text(
                            '${_currentData.voltage.toStringAsFixed(2)} V',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.7), fontSize: 20),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0, left: 0, right: 0,
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/images/Battery.svg',
                            colorFilter: ColorFilter.mode(const Color(
                                0xFFFFFFFF), BlendMode.srcIn),
                            width: 30, height: 30,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // Helper function untuk membangun indikator status
  Widget _buildStatusIndicator(String label, bool isActive, Color activeColor) {
    String iconPath;
    switch (label) {
      case 'HANDBRAKE':
        iconPath = 'assets/images/Brake.svg';
        break;
      case 'ABS':
        iconPath = 'assets/images/abs.svg';
        break;
      case 'AIRBAG':
        iconPath = 'assets/images/Airbag.svg';
        break;
      case 'SEATBELT':
        iconPath = 'assets/images/SeatBelt.svg';
        break;
      default:
        iconPath = 'assets/images/default_icon.svg';
        break;
    }
    return Column(
      children: [
        SvgPicture.asset(
          iconPath,
          colorFilter: ColorFilter.mode(
            isActive ? activeColor : Colors.white.withOpacity(0.5),
            BlendMode.srcIn,
          ),
          width: 40,
          height: 40,
        ),
        //const SizedBox(height: 4),
        //Text(
          //label,
          //style: GoogleFonts.poppins(
            //color: isActive ? activeColor : Colors.white.withOpacity(0.5),
            //fontSize: 12,
            //fontWeight: FontWeight.w600,
          //),
        //),
      ],
    );
  }
}