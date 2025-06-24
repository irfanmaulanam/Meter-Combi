class SensorData {
  double speed; // RPM/Speed dari Rotary Encoder
  double temperature; // Suhu dari DS18B20
  double level; // Jarak/Level dari Ultrasonik (0-100 cm)
  double pressure; // Berat/Tekanan dari HX711 (0-100)
  double voltage; // Tegangan dari INA219 (0-100)
  bool brake; // Status rem
  bool abs; // Status ABS
  bool airbag; // Status Airbag
  bool seatbelt; // Status Sabuk Pengaman

  SensorData({
    required this.speed,
    required this.temperature,
    required this.level,
    required this.pressure,
    required this.voltage,
    required this.brake,
    required this.abs,
    required this.airbag,
    required this.seatbelt,
  });

  // Factory constructor dari JSON (tidak ada perubahan signifikan di sini)
  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      level: (json['level'] as num?)?.toDouble() ?? 0.0,
      pressure: (json['pressure'] as num?)?.toDouble() ?? 0.0,
      voltage: (json['voltage'] as num?)?.toDouble() ?? 0.0,
      brake: (json['brake'] is bool) ? json['brake'] : (json['brake'] as int? ?? 0) == 1,
      abs: (json['abs'] is bool) ? json['abs'] : (json['abs'] as int? ?? 0) == 1,
      airbag: (json['airbag'] is bool) ? json['airbag'] : (json['airbag'] as int? ?? 0) == 1,
      seatbelt: (json['seatbelt'] is bool) ? json['seatbelt'] : (json['seatbelt'] as int? ?? 0) == 1,
    );
  }

  // Factory constructor untuk data dummy awal
  factory SensorData.initial() {
    return SensorData(
      speed: 0.0,
      temperature: 0.0,
      level: 0.0,
      pressure: 0.0,
      voltage: 0.0,
      brake: false,
      abs: false,
      airbag: false,
      seatbelt: false,
    );
  }
}