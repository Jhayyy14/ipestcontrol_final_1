import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:app_settings/app_settings.dart';
import 'package:url_launcher/url_launcher.dart';

class WiFiConnectionScreen extends StatefulWidget {
  const WiFiConnectionScreen({super.key});

  @override
  State<WiFiConnectionScreen> createState() => _WiFiConnectionScreenState();
}

class _WiFiConnectionScreenState extends State<WiFiConnectionScreen> {
  bool _isConnectedToWifi = false;
  bool _isMobileDataOn = false;
  final Connectivity _connectivity = Connectivity();
  final NetworkInfo _networkInfo = NetworkInfo();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  String _wifiName = "";

  /// ✨ Matching home screen colors
  static const Color primaryTeal = Color(0xFF00B4A6);
  static const Color primaryIndigo = Color(0xFF6366F1);
  static const Color softBg = Color(0xFFF8FAFC);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);

  // ✅ Constants for Pi Hotspot
  static const String PI_HOTSPOT_SSID = 'IPESTCONTROL';
  static const String PI_PORTAL_URL = 'http://10.42.0.1';
  static const String PI_HOSTNAME_URL = 'http://ipestcontrol.local';

  @override
  void initState() {
    super.initState();
    _checkWifiConnection();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);

    // Check WiFi status every 2 seconds
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _checkWifiConnection();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    _checkWifiConnection();
  }

  Future<void> _checkWifiConnection() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      bool isWifi = connectivityResult == ConnectivityResult.wifi;
      bool isMobile = connectivityResult == ConnectivityResult.mobile;

      // Check WiFi name (SSID)
      String? wifiName = "";
      try {
        wifiName = await _networkInfo.getWifiName();
        if (wifiName != null) {
          wifiName = wifiName
              .replaceAll('"', '')
              .replaceAll('<unknown ssid>', '');
        }
      } catch (e) {
        print('Error getting WiFi name: $e');
      }

      // Consider connected if WiFi is on
      bool isConnected = isWifi;

      if (mounted) {
        setState(() {
          _isConnectedToWifi = isConnected;
          _isMobileDataOn = isMobile;
          _wifiName = wifiName ?? "";
        });
      }
    } catch (e) {
      print('Error checking connectivity: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if specifically connected to the Pi Hotspot
    bool isConnectedToPi = _isConnectedToWifi && _wifiName == PI_HOTSPOT_SSID;

    return Scaffold(
      /// Main container with gradient background matching home screen
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment. bottomRight,
            colors: [Color(0xFFE0F2FE), Color(0xFFF8FAFC), Color(0xFFEDE9FE)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Modern Header with gradient
                  _buildModernHeader(context),

                  const SizedBox(height: 24),

                  /// ⚠️ Mobile Data Warning (if active)
                  if (_isMobileDataOn) _buildMobileDataWarning(),

                  /// Connection Status Card
                  _buildConnectionStatusCard(isConnectedToPi),

                  const SizedBox(height: 24),

                  /// Instructions Card
                  _buildInstructionsCard(isConnectedToPi),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Modern Header with gradient background
  Widget _buildModernHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryTeal, primaryIndigo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryIndigo.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          /// Back button with glassmorphism effect
          Container(
            decoration: BoxDecoration(
              color: Colors.white. withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 16),

          /// Title with icon
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.wifi_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'WiFi Setup',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Mobile Data Warning Banner
  Widget _buildMobileDataWarning() {
    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFF3CD).withOpacity(0.9),
            const Color(0xFFFFE5A0).withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF59E0B),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: Color(0xFFD97706),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚠️ Turn OFF Mobile Data',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Android may block the Pi hotspot connection if mobile data is enabled.',
                  style: TextStyle(
                    fontSize: 12,
                    color: textDark.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Connection Status Card
  Widget _buildConnectionStatusCard(bool isConnectedToPi) {
    Color statusColor = _isConnectedToWifi
        ? (isConnectedToPi ? const Color(0xFF10B981) : primaryTeal)
        : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          /// Status Icon with animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        statusColor.withOpacity(0.2),
                        statusColor.withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isConnectedToWifi
                        ? Icons.wifi_rounded
                        : Icons.wifi_off_rounded,
                    size: 52,
                    color: statusColor,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          /// Status Text
          Text(
            _isConnectedToWifi
                ? (isConnectedToPi
                    ? '✓ Connected to Pi Hotspot'
                    : '✓ Connected to WiFi')
                : 'Not Connected',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          /// Network Name Badge
          if (_wifiName.isNotEmpty && _isConnectedToWifi)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor.withOpacity(0.15),
                    statusColor.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius. circular(20),
                border: Border.all(
                  color: statusColor. withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.router_rounded,
                    size: 18,
                    color: statusColor,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _wifiName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 28),

          /// Open WiFi Settings Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton. icon(
              onPressed: () {
                AppSettings.openAppSettings(type: AppSettingsType.wifi);
              },
              icon: const Icon(Icons.settings_rounded, size: 20),
              label: const Text(
                'Open WiFi Settings',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: primaryTeal,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                shadowColor: primaryTeal.withOpacity(0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Instructions Card
  Widget _buildInstructionsCard(bool isConnectedToPi) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius. circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryIndigo.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment. start,
        children: [
          /// Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lightbulb_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Setup Instructions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          /// Steps
          _buildInstructionStep(
            '1',
            'Tap "Open WiFi Settings" above.',
            primaryTeal,
          ),
          const SizedBox(height: 14),
          _buildInstructionStep(
            '2',
            'Connect to the network: **$PI_HOTSPOT_SSID**',
            primaryTeal,
            isBold: true,
          ),
          const SizedBox(height: 14),
          _buildInstructionStep(
            '3',
            'Password is: **YOHANYOHAN**',
            primaryTeal,
          ),
          const SizedBox(height: 14),
          _buildInstructionStep(
            '4',
            'Once connected, tap the button below to open the configuration portal.',
            primaryIndigo,
          ),

          const SizedBox(height: 20),

          /// Portal Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton. icon(
              onPressed: isConnectedToPi
                  ? () async {
                      Uri url = Uri.parse(PI_PORTAL_URL);
                      try {
                        if (! await launchUrl(url,
                            mode: LaunchMode.externalApplication)) {
                          url = Uri.parse(PI_HOSTNAME_URL);
                          await launchUrl(url,
                              mode: LaunchMode. externalApplication);
                        }
                      } catch (e) {
                        print('Error launching URL: $e');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not open the portal page.'),
                              backgroundColor: Color(0xFFEF4444),
                            ),
                          );
                        }
                      }
                    }
                  : null,
              icon: const Icon(Icons.public_rounded, size: 20),
              label: const Text(
                'Open Configuration Portal',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton. styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor:
                    isConnectedToPi ? primaryIndigo : textMuted. withOpacity(0.3),
                foregroundColor: isConnectedToPi ?  Colors.white : textMuted,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          if (! isConnectedToPi && _isConnectedToWifi)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Center(
                child: Text(
                  'Connect to $PI_HOTSPOT_SSID to enable this button.',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          const SizedBox(height: 20),

          _buildInstructionStep(
            '5',
            'In the portal, select your home WiFi network.',
            const Color(0xFF10B981),
          ),
          const SizedBox(height: 14),
          _buildInstructionStep(
            '6',
            'Your phone and Pi are now connected!  Return to the main screen.',
            const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  /// Instruction Step Widget
  Widget _buildInstructionStep(
    String number,
    String text,
    Color color, {
    bool isBold = false,
  }) {
    // Simple markdown-like bold parsing
    List<InlineSpan> spans = [];
    text.split('**').asMap().forEach((index, part) {
      spans.add(TextSpan(
        text: part,
        style: TextStyle(
          fontWeight:
              (index % 2 == 1 || isBold) ? FontWeight.bold : FontWeight.w500,
          color: (index % 2 == 1) ? textDark : textMuted,
        ),
      ));
    });

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color,
                color.withOpacity(0.7),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                ),
                children: spans,
              ),
            ),
          ),
        ),
      ],
    );
  }
}