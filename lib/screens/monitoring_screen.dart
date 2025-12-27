import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import '../services/rpi_service.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  final RpiService _rpiService = RpiService();

  bool _isConnected = false;
  bool _isConnecting = false;
  String? _mode;
  String? _error;

  WebViewController? _webViewController;

  Timer? _fpsTimer;
  int? _fps;

  @override
  void dispose() {
    _fpsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isHotspot = _mode == 'hotspot';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FB),
      body: SafeArea(
        child: Column(
          children: [
            _header(isHotspot),
            const SizedBox(height: 16),
            _videoPreview(),
            const SizedBox(height: 16),
            _statusCard(),
            const SizedBox(height: 12),
            _fpsIndicator(),
            const SizedBox(height: 16),
            _controlButtons(),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _header(bool isHotspot) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF00B4A6), Color(0xFF6366F1)],
          ),
        ),
        child: Row(
          children: [
            _iconButton(Icons.videocam_rounded),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LIVE\nMONITORING',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _modeBadge(isHotspot),
                ],
              ),
            ),
            _iconButton(Icons.refresh_rounded),
          ],
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon) {
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: Colors.white),
    );
  }

  Widget _modeBadge(bool isHotspot) {
    if (_isConnecting) {
      return _badge('Connecting...', Icons.sync, Colors.white70);
    }
    if (!_isConnected) {
      return _badge('Offline', Icons.wifi_off, Colors.grey);
    }
    return _badge(
      isHotspot ? 'Hotspot Mode' : 'WiFi Mode',
      isHotspot ? Icons.wifi_tethering : Icons.wifi,
      isHotspot ? Colors.amber : Colors.lightBlue,
    );
  }

  Widget _badge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ================= VIDEO =================
  Widget _videoPreview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 230,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(24),
        ),
        child: _isConnecting
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : !_isConnected
            ? const Center(
          child: Text('Camera Offline',
              style: TextStyle(color: Colors.white54)),
        )
            : ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: WebViewWidget(controller: _webViewController!),
        ),
      ),
    );
  }

  // ================= STATUS =================
  Widget _statusCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 4,
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _isConnected ? Colors.green : Colors.grey,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isConnected ? '✓ Streaming' : 'Not Connected',
                  style: TextStyle(
                    color: _isConnected ? Colors.green : Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _error ?? (_isConnected ? 'Video stream active' : 'Press START'),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= FPS =================
  Widget _fpsIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.speed_rounded, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              _fps == null ? 'FPS: N/A' : 'FPS: $_fps',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= CONTROLS =================
  Widget _controlButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _actionButton(
              label: 'START',
              icon: Icons.play_arrow_rounded,
              color: Colors.teal,
              enabled: !_isConnecting && !_isConnected,
              onTap: _start,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _actionButton(
              label: 'STOP',
              icon: Icons.stop_rounded,
              color: Colors.redAccent,
              enabled: _isConnected,
              onTap: _stop,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _start() async {
    setState(() {
      _isConnecting = true;
      _error = null;
    });

    final ok = await _rpiService.connectAuto();
    if (!mounted) return;

    if (ok) {
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(_rpiService.videoFeedUrl));

      _startFpsPolling();
    }

    setState(() {
      _isConnecting = false;
      _isConnected = ok;
      _mode = ok ? _rpiService.connectionMode : null;
      _error = ok ? null : 'Connection failed';
    });
  }

  void _stop() {
    _fpsTimer?.cancel();
    setState(() {
      _isConnected = false;
      _mode = null;
      _error = null;
      _fps = null;
      _webViewController = null;
    });
  }

  // ================= FPS POLLING =================
  void _startFpsPolling() {
    _fpsTimer?.cancel();

    _fpsTimer = Timer.periodic(
      const Duration(milliseconds: 500),
          (_) async {
        try {
          final res = await http.get(
            Uri.parse('http://${_rpiService.rpiIpAddress}:5000/metadata'),
          );

          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            if (mounted) {
              setState(() {
                _fps = data['fps'];
              });
            }
          }
        } catch (_) {}
      },
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
