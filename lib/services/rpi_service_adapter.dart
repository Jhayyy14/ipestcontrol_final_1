import 'dart:convert';
import 'package:http/http.dart' as http;
import 'rpi_service.dart';

class RpiServiceAdapter {
  final RpiService _service = RpiService();

  /// ============================
  /// CONNECTION
  /// ============================
  Future<bool> scanAndConnect() async {
    return await _service.connectAuto();
  }

  void stopStreaming() {}

  Future<void> shutdownSystem() async {}

  /// ============================
  /// MODE CONTROL (STAGE 12)
  /// ============================
  ///
  /// Sends mode state to ESP32
  /// ESP32 endpoint: http://10.42.0.50/update_mode
  ///
  /// pestMode   → MDL relay + strobe
  /// insectMode → Blue light + HV interval
  ///
  Future<void> setSystemModes(bool pestMode, bool insectMode) async {
    const esp32Ip = '10.42.0.50';
    const url = 'http://$esp32Ip/update_mode';

    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'pest_mode': pestMode,
          'insect_mode': insectMode,
        }),
      ).timeout(const Duration(seconds: 2));

      if (res.statusCode == 200) {
        print('✅ ESP32 MODES UPDATED → Pest:$pestMode Insect:$insectMode');
      } else {
        print('⚠️ ESP32 MODE UPDATE FAILED: ${res.statusCode}');
      }
    } catch (e) {
      print('❌ ESP32 MODE REQUEST ERROR: $e');
    }
  }

  /// ============================
  /// GETTERS
  /// ============================
  String? get rpiIpAddress => _service.rpiIpAddress;
  String? get connectionMode => _service.connectionMode;

  /// ============================
  /// BATTERY STREAM (ALREADY WORKING)
  /// ============================
  Stream<Map<String, dynamic>> get batteryStream =>
      _service.batteryStream;

  RpiService get raw => _service;
}