// lib/services/rpi_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RpiService {
  static const _hotspotIp = '10.42.0.1';
  static const _mdnsHost = 'ipestcontrol.local';
  static const _port = 5000;
  static const _cacheKey = 'rpi_last_wifi_ip';

  /// 🔴 BATTERY THRESHOLDS (STAGE 10)
  static const int LOW_BATTERY_PERCENT = 20;

  String? _currentIp;
  String? _mode;

  final _batteryController =
  StreamController<Map<String, dynamic>>.broadcast();

  Timer? _batteryTimer;

  String? get rpiIpAddress => _currentIp;
  String? get connectionMode => _mode;

  Stream<Map<String, dynamic>> get batteryStream =>
      _batteryController.stream;

  // ============================
  // AUTO CONNECT
  // ============================
  Future<bool> connectAuto() async {
    if (await _try(_hotspotIp, mode: 'hotspot')) {
      _startBatteryPolling();
      return true;
    }

    if (await _try(_mdnsHost, mode: 'wifi')) {
      _startBatteryPolling();
      return true;
    }

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);

    if (cached != null && await _try(cached, mode: 'wifi')) {
      _startBatteryPolling();
      return true;
    }

    return false;
  }

  // ============================
  // HANDSHAKE
  // ============================
  Future<bool> _try(String host, {required String mode}) async {
    try {
      final res = await http
          .get(Uri.parse('http://$host:$_port/whoami'))
          .timeout(const Duration(seconds: 3));

      if (res.statusCode != 200) return false;

      _currentIp = host;
      _mode = mode;

      if (mode == 'wifi') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheKey, host);
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  // ============================
  // BATTERY POLLING (STAGE 10 READY)
  // ============================
  void _startBatteryPolling() {
    _batteryTimer?.cancel();

    _batteryTimer = Timer.periodic(
      const Duration(seconds: 2),
          (_) async {
        if (_currentIp == null) return;

        try {
          final res = await http.get(
            Uri.parse('http://$_currentIp:$_port/metadata'),
            headers: {'Accept': 'application/json'},
          );

          if (res.statusCode != 200) return;

          final data = jsonDecode(res.body);
          final external = data['external'];

          int extPercent = external?['percent'] ?? 0;
          bool extAvailable = external?['available'] ?? false;

          final bool isLowBattery =
              extAvailable && extPercent <= LOW_BATTERY_PERCENT;

          _batteryController.add({
            // INTERNAL UPS (future-proof)
            "internal": data["internal"],

            // EXTERNAL 12V SYSTEM
            "external": {
              "available": extAvailable,
              "voltage": external?['voltage'] ?? 0.0,
              "percent": extPercent,
              "low_battery": isLowBattery,
              "critical": isLowBattery, // same rule for now
            },
          });
        } catch (_) {
          // silent fail
        }
      },
    );
  }

  // ============================
  // VIDEO
  // ============================
  String get videoFeedUrl {
    if (_currentIp == null) {
      throw Exception('Pi not connected');
    }
    return 'http://$_currentIp:$_port/video_feed';
  }

  void dispose() {
    _batteryTimer?.cancel();
    _batteryController.close();
  }
}