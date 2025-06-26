import 'dart:async';
import 'dart:developer';
import 'package:flutter_libserialport/flutter_libserialport.dart';

// Definisi Error Khusus untuk Serial Port
class SerialPortError implements Exception {
  final String message;
  SerialPortError(this.message);
  @override
  String toString() => 'SerialPortError: $message';
}

class DataService {
  // <<< PERBAIKAN DI SINI: _port dideklarasikan final dan diinisialisasi sekali >>>
  late SerialPort _port;
  late SerialPortReader _reader;

  // Constructor Anda tetap sama, tidak perlu diubah.
  DataService({String portName = 'COM33'}) : _port = SerialPort(portName);

  // --- SISA KODE TIDAK PERLU DIUBAH SAMA SEKALI ---

  String _rawData = '';
  String _status = 'Port not opened';

  final StreamController<double> _speedController = StreamController<double>.broadcast();
  final StreamController<double> _temperatureController = StreamController<double>.broadcast();
  final StreamController<double> _levelController = StreamController<double>.broadcast();
  final StreamController<double> _pressureController = StreamController<double>.broadcast();
  final StreamController<double> _voltageController = StreamController<double>.broadcast();
  final StreamController<bool> _brakeController = StreamController<bool>.broadcast();
  final StreamController<bool> _absController = StreamController<bool>.broadcast();
  final StreamController<bool> _airbagController = StreamController<bool>.broadcast();
  final StreamController<bool> _seatbeltController = StreamController<bool>.broadcast();

  Stream<double> get speedStream => _speedController.stream;
  Stream<double> get temperatureStream => _temperatureController.stream;
  Stream<double> get levelStream => _levelController.stream;
  Stream<double> get pressureStream => _pressureController.stream;
  Stream<double> get voltageStream => _voltageController.stream;
  Stream<bool> get brakeStream => _brakeController.stream;
  Stream<bool> get absStream => _absController.stream;
  Stream<bool> get airbagStream => _airbagController.stream;
  Stream<bool> get seatbeltStream => _seatbeltController.stream;

  String get status => _status;
  set status(String value) { _status = value; }

/*  void startListening() {
    try {
      // <<< PERBAIKAN DI SINI: Atur baud rate SEBELUM membuka port >>>
      _port.config.baudRate = 115200; // PASTIKAN BAUD RATE INI SAMA DENGAN ESP32

      // <<< PERBAIKAN DI SINI: Hanya panggil openReadWrite() SEKALI sebagai kondisi >>>
      if (_port.openReadWrite()) {
        _status = '';
        print(_status);

        _reader = SerialPortReader(_port);
        _reader.stream.listen((data) {
          _rawData += String.fromCharCodes(data);
          _processRawData();
        }, onError: (e) {
          _status = 'Serial stream error: ${e.message}';
          print(_status);
        });
      } else {
        _status = 'Failed to open port: ${SerialPort.lastError}';
        print(_status);
        throw SerialPortError(_status);
      }
    } on SerialPortError catch (e) {
      _status = 'Error opening port: ${e.message}';
      print(_status);
      throw SerialPortError(_status);
    } catch (e) {
      _status = 'An unexpected error occurred: $e';
      print(_status);
      throw SerialPortError(_status);
    }
  }
*/
  void startListening() {
    try {
      final listPort = SerialPort.availablePorts;
      print('Available Ports: $listPort'); // Debugging

      // Variabel sementara untuk menampung port yang ditemukan
      SerialPort? foundPort;

      for (var portName in listPort) {
        var p = SerialPort(portName);
        print('Checking port: ${p.name}, Serial: ${p.serialNumber}');

        if (p.serialNumber == '5735016773') {
          // Jangan langsung assign ke _port, tapi simpan di variabel sementara
          foundPort = p;
          break; // Exit loop once found
        }
        // Tutup port sementara jika bukan yang dicari
        p.close();
      }

      // Setelah loop selesai, barulah assign ke _port jika ditemukan
      if (foundPort != null) {
        _port = foundPort;
      } else {
        // Jika tidak ditemukan, kita anggap akan memakai port dari constructor
        print('⚠️ Port dengan serial number tidak ditemukan. Mencoba menggunakan port default: ${_port.name}');
      }

      if (!_port.isOpen && !_port.openReadWrite()) {
        print('❌ Error: Failed to open port ${_port.name}');
        return;
      }

      print('✅ Port yang digunakan: ${_port.name}');

      final config = _port.config;
      config.baudRate = 115200;
      _port.config = config;

      _reader = SerialPortReader(_port);

      print('🎧 Listening to stream...');

      _reader.stream.listen((data) {
        _rawData += String.fromCharCodes(data);
        log('DATA : $_rawData'); // diganti menjadi _rawData

        _processRawData();
      }, onError: (error) {
        print('❌ Stream error: $error');
      }, onDone: () {
        print('✅ Stream closed.');
      });


    } catch (e) {
      print('❌ Exception during port setup: $e');
    }
  }

  void _processRawData() {
    final lines = _rawData.split('\n');

    for (int i = 0; i < lines.length - 1; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final parts = line.split(':');
      if (parts.length < 2) {
        print("Invalid data format: $line");
        continue;
      }

      final String key = parts[0].trim();
      final String valueStr = parts[1].trim();

      switch (key) {
        case 'Speed':
          double? val = double.tryParse(valueStr);
          if (val != null) _speedController.add(val);
          break;
        case 'Temperature':
          double? val = double.tryParse(valueStr);
          if (val != null) _temperatureController.add(val);
          break;
        case 'Level':
          double? val = double.tryParse(valueStr);
          if (val != null) _levelController.add(val);
          break;
        case 'Pressure':
          double? val = double.tryParse(valueStr);
          if (val != null) _pressureController.add(val);
          break;
        case 'Voltage':
          double? val = double.tryParse(valueStr);
          if (val != null) _voltageController.add(val);
          break;
        case 'Brake':
          bool val = (valueStr == "1" || valueStr.toLowerCase() == "true");
          _brakeController.add(val);
          break;
        case 'ABS':
          bool val = (valueStr == "1" || valueStr.toLowerCase() == "true");
          _absController.add(val);
          break;
        case 'Airbag':
          bool val = (valueStr == "1" || valueStr.toLowerCase() == "true");
          _airbagController.add(val);
          break;
        case 'Seatbelt':
          bool val = (valueStr == "1" || valueStr.toLowerCase() == "true");
          _seatbeltController.add(val);
          break;
        default:
          print("Unknown data key: $key with value: $valueStr");
          break;
      }
    }
    _rawData = lines.last;
  }

  void dispose() {
    _speedController.close();
    _temperatureController.close();
    _levelController.close();
    _pressureController.close();
    _voltageController.close();
    _brakeController.close();
    _absController.close();
    _airbagController.close();
    _seatbeltController.close();
    _reader.close(); // Pastikan _reader sudah diinisialisasi sebelum close dipanggil
    _port.close();
    print("Disposed of resources and closed the serial port");
  }

  static List<String> getAvailablePorts() {
    return SerialPort.availablePorts;
  }
}