import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RpiService {
  static const _hotspotIp = '10.42.0.1';
  static const _mdnsHost = 'ipestcontrol.local';
  static const _port = 5000;
  static const _cacheKey = 'rpi_last_wifi_ip';

  String? _currentIp;
  String? _mode;

  String? get rpiIpAddress => _currentIp;
  String? get connectionMode => _mode;

  /// ============================
  /// AUTO CONNECT (FINAL)
  /// ============================
  Future<bool> connectAuto() async {
    // 1️⃣ HOTSPOT (FIXED)
    if (await _try('$_hotspotIp', mode: 'hotspot')) {
      return true;
    }

    // 2️⃣ mDNS (WIFI)
    if (await _try(_mdnsHost, mode: 'wifi')) {
      return true;
    }

    // 3️⃣ Cached Wi-Fi IP (fallback)
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);

    if (cached != null) {
      if (await _try(cached, mode: 'wifi')) {
        return true;
      }
    }

    return false;
  }

  /// ============================
  /// INTERNAL HANDSHAKE
  /// ============================
  Future<bool> _try(String host, {required String mode}) async {
    try {
      final res = await http
          .get(Uri.parse('http://$host:$_port/whoami'))
          .timeout(const Duration(seconds: 3));

      if (res.statusCode != 200) return false;

      final data = jsonDecode(res.body);

      _currentIp = host; // IMPORTANT
      _mode = mode;

      if (mode == 'wifi' && data['ip'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheKey, data['ip']);
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  /// ============================
  /// STREAM URL
  /// ============================
  String get videoFeedUrl {
    if (_currentIp == null) {
      throw Exception('Pi not connected');
    }
    return 'http://$_currentIp:$_port/video_feed';
  }
}
