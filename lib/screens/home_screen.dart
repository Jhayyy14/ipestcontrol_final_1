import 'package:flutter/material.dart';
import 'package:ipestcontrol/widgets/mode_card.dart';
import 'package:ipestcontrol/screens/monitoring_screen.dart';
import 'package:ipestcontrol/screens/settings_screen.dart';
import 'package:ipestcontrol/services/rpi_service_adapter.dart';
import 'dart:math' as math;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// ✅ ADDED: WidgetsBindingObserver mixin
class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  int _selectedIndex = 0;
  late PageController _pageController;
  bool _isAnimating = false;

  final RpiServiceAdapter _rpiService = RpiServiceAdapter();



  bool pestMode = false;
  bool detectionMode = false;

  // --- SYSTEM A (Internal UPS) Data ---
  int _batteryPercentage = 0;
  bool _isCharging = false;
  bool _isPowerConnected = false;

  // --- SYSTEM B (External 12V) Data ---
  int _extPercentage = 0;
  double _extVoltage = 0.0;
  bool _extAvailable = false;

  // Battery animations (Internal)
  AnimationController? _pulseController;
  AnimationController? _waveController;
  AnimationController? _boltController;
  Animation<double>? _pulseAnimation;
  Animation<double>? _waveAnimation;
  Animation<double>? _boltAnimation;

  // ✨ Enhanced Color Palette
  static const Color primaryTeal = Color(0xFF00B4A6);
  static const Color primaryIndigo = Color(0xFF6366F1);
  static const Color accentAmber = Color(0xFFFFA726);
  static const Color softBg = Color(0xFFF8FAFC);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    // ✅ REGISTER OBSERVER (Detects App Open/Close)
    WidgetsBinding.instance.addObserver(this);

    _pageController = PageController(initialPage: _selectedIndex);

    // Initialize battery animations
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();
    _waveAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      _waveController!,
    );

    _boltController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _boltAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _boltController!, curve: Curves.elasticOut),
    );

    // ✅ AUTO-CONNECT ON LAUNCH
    // This starts the scanning process immediately when the app opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("🚀 App Launched: Starting Connection Scan...");
      _rpiService.scanAndConnect();
    });

    // Listen to combined battery updates
    _rpiService.batteryStream.listen((data) {
      if (mounted) {
        // Parse System A (Internal)
        final internal = data['internal'];
        final external = data['external'];

        final wasCharging = _isCharging;

        setState(() {
          // System A
          if (internal != null) {
            _batteryPercentage = internal['percentage'] ?? 0;
            _isCharging = internal['is_charging'] ?? false;
            _isPowerConnected = internal['power_connected'] ?? false;
          }

          // System B
          if (external != null) {
            _extPercentage = external['percent'] ?? 0;
            _extVoltage = (external['voltage'] ?? 0.0).toDouble();
            _extAvailable = external['available'] ?? false;
          }
        });

        // Control animations based on charging state (Internal only)
        if (_isCharging && !wasCharging) {
          _pulseController?.repeat(reverse: true);
          _boltController?.repeat(reverse: true);
        } else if (!_isCharging && wasCharging) {
          _pulseController?.stop();
          _boltController?.stop();
        }
      }
    });
  }

  @override
  void dispose() {
    // ✅ REMOVE OBSERVER
    WidgetsBinding.instance.removeObserver(this);
    
    _pageController.dispose();
    _pulseController?.dispose();
    _waveController?.dispose();
    _boltController?.dispose();
    super.dispose();
  }

  // ✅ DETECT APP RESUME (Switching back from Settings or background)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print("🚀 App Resumed: Refreshing Connection...");
      _rpiService.scanAndConnect();
    }
  }

  void _onItemTapped(int index) {
    if (_isAnimating || _selectedIndex == index) return;

    setState(() {
      _isAnimating = true;
      _selectedIndex = index;
    });

    _pageController
        .animateToPage(
          index,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
        )
        .then((_) {
          if (mounted) {
            setState(() {
              _isAnimating = false;
            });
          }
        });
  }

  // --- HELPERS FOR INTERNAL BATTERY ---
  Color _getBatteryColor() {
    if (_isCharging) return const Color(0xFF3B82F6);
    if (_batteryPercentage > 50) return const Color(0xFF10B981);
    if (_batteryPercentage > 20) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Color _getBatteryBgColor() {
    if (_isCharging) return const Color(0xFFDEEBFF);
    if (_batteryPercentage > 50) return const Color(0xFFD1FAE5);
    if (_batteryPercentage > 20) return const Color(0xFFFEF3C7);
    return const Color(0xFFFEE2E2);
  }

  IconData _getBatteryIcon() {
    if (_isCharging) return Icons.battery_charging_full_rounded;
    if (_batteryPercentage > 80) return Icons.battery_full_rounded;
    if (_batteryPercentage > 50) return Icons.battery_6_bar_rounded;
    if (_batteryPercentage > 20) return Icons.battery_3_bar_rounded;
    return Icons.battery_alert_rounded;
  }

  String _getBatteryStatus() {
    if (_isCharging) return 'Charging';
    if (_isPowerConnected) return 'Full';
    if (_batteryPercentage > 50) return 'Good';
    if (_batteryPercentage > 20) return 'Fair';
    return 'Low';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBg,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          if (!_isAnimating) {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildHomePage(),
          const MonitoringScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: RepaintBoundary(child: _buildBottomNavBar()),
      extendBody: true,
    );
  }

  Widget _buildHomePage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE0F2FE),
            Color(0xFFF8FAFC),
            Color(0xFFEDE9FE),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                
                // System A
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text("SYSTEM A (BRAIN)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMuted)),
                ),
                _buildBatteryCard(),
                
                const SizedBox(height: 16),
                
                // System B
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text("SYSTEM B (MUSCLE)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMuted)),
                ),
                _buildExternalBatteryCard(),

                const SizedBox(height: 32),
                _buildModeSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
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
            blurRadius: 24,
            offset: const Offset(0, 12),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset('assets/images/ipest_control_icon.png',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (c,o,s) => const Icon(Icons.pest_control, color: Colors.white, size: 30),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'IPESTCONTROL',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'IoT Pest Management',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
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

  // --- INTERNAL BATTERY CARD (SYSTEM A) ---
  Widget _buildBatteryCard() {
    final batteryColor = _getBatteryColor();
    final batteryBgColor = _getBatteryBgColor();
    final batteryIcon = _getBatteryIcon();

    if (_pulseAnimation == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _pulseAnimation!,
      builder: (context, child) {
        return Transform.scale(
          scale: _isCharging ? _pulseAnimation!.value : 1.0,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: batteryColor.withOpacity(0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Animated background
                  Positioned.fill(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            batteryBgColor.withOpacity(0.3),
                            Colors.white,
                            batteryBgColor.withOpacity(0.1),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Wave effect when charging
                  if (_isCharging && _waveAnimation != null)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _waveAnimation!,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: _WavePainter(
                              animation: _waveAnimation!.value,
                              color: batteryColor.withOpacity(0.08),
                            ),
                          );
                        },
                      ),
                    ),

                  // Main content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Battery icon
                            _buildBatteryIcon(
                              batteryIcon,
                              batteryColor,
                              batteryBgColor,
                            ),
                            const SizedBox(width: 20),

                            // Battery info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title and status badge
                                  Row(
                                    children: [
                                      const Text(
                                        'Pi Power',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: textMuted,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const Spacer(),
                                      _buildStatusBadge(batteryColor, _getBatteryStatus()),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Percentage
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      TweenAnimationBuilder<int>(
                                        duration: const Duration(milliseconds: 800),
                                        tween: IntTween(
                                          begin: 0,
                                          end: _batteryPercentage,
                                        ),
                                        builder: (context, value, child) {
                                          return Text(
                                            '$value',
                                            style: TextStyle(
                                              fontSize: 52,
                                              fontWeight: FontWeight.bold,
                                              color: batteryColor,
                                              height: 1,
                                            ),
                                          );
                                        },
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                          left: 4,
                                        ),
                                        child: Text(
                                          '%',
                                          style: TextStyle(
                                            fontSize: 30,
                                            fontWeight: FontWeight.w600,
                                            color: batteryColor.withOpacity(0.7),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Progress bar
                        _buildProgressBar(batteryColor, _batteryPercentage / 100),

                        const SizedBox(height: 16),

                        // Status text
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isCharging
                                  ? Icons.bolt_rounded
                                  : _isPowerConnected
                                      ?  Icons.power_rounded
                                      : Icons.battery_std_rounded,
                              size: 16,
                              color: batteryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isCharging
                                  ? 'Charging in progress'
                                  : _isPowerConnected
                                      ? 'Fully charged'
                                      : 'Running on UPS',
                              style: const TextStyle(
                                fontSize: 13,
                                color: textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- EXTERNAL BATTERY CARD (SYSTEM B) ---
  Widget _buildExternalBatteryCard() {
    // 12V System uses Amber/Orange to signify High Power / "Muscle"
    Color extColor = _extAvailable ? accentAmber : Colors.grey;
    Color extBg = _extAvailable ? const Color(0xFFFFF7ED) : const Color(0xFFF1F5F9);
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: extColor.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: extBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: extColor.withOpacity(0.3),
                ),
              ),
              child: Icon(
                _extAvailable ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                color: extColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "12V System",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                        ),
                      ),
                       _buildStatusBadge(
                         _extAvailable ? extColor : Colors.grey, 
                         _extAvailable ? "Active" : "Offline"
                       ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  if (_extAvailable)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          "${_extVoltage.toStringAsFixed(1)}",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: extColor,
                          ),
                        ),
                        Text(
                          " V",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: extColor.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(width: 1, height: 24, color: Colors.grey.withOpacity(0.3)),
                        const SizedBox(width: 12),
                        Text(
                          "$_extPercentage%",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textDark.withOpacity(0.7),
                          ),
                        ),
                      ],
                    )
                  else
                    const Text(
                      "Waiting for data...",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatteryIcon(IconData icon, Color color, Color bgColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, color: color, size: 44),
          if (_isCharging && _boltAnimation != null)
            AnimatedBuilder(
              animation: _boltAnimation!,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.5 + (_boltAnimation!.value * 0.3),
                  child: Icon(
                    Icons.bolt,
                    color: Colors.amber.shade400,
                    size: 28,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(Color color, String text) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(Color color, double value) {
    return Container(
      height: 10,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(
            begin: 0,
            end: value,
          ),
          builder: (context, val, child) {
            return Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: val.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.7),
                          color,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isCharging && _waveAnimation != null)
                  AnimatedBuilder(
                    animation: _waveAnimation!,
                    builder: (context, child) {
                      return Positioned(
                        left: (val * 300) - 80 +
                            (math.sin(_waveAnimation!.value) * 15),
                        child: Container(
                          width: 80,
                          height: 10,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0),
                                Colors.white.withOpacity(0.6),
                                Colors.white.withOpacity(0),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildModeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Control Modes',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textDark,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryTeal, primaryIndigo],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: primaryIndigo.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                '${(pestMode ?  1 : 0) + (detectionMode ? 1 : 0)}/2',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ModeCard(
          label: "Pest Mode",
          value: pestMode,
          icon: Icons.pest_control_rodent,
          iconColor: const Color(0xFF8B5A3C),
          onChanged: (v) {
            setState(() => pestMode = v);
            _rpiService.setSystemModes(pestMode, detectionMode);
          },
        ),
        const SizedBox(height: 16),
        ModeCard(
          label: "Insect Mode",
          value: detectionMode,
          icon: Icons.bug_report,
          iconColor: accentAmber,
          onChanged: (v) {
            setState(() => detectionMode = v);
          },
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      height: 70,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final navBarWidth = constraints.maxWidth;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 65,
                  decoration: BoxDecoration(
                    color: cardWhite,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: primaryIndigo.withOpacity(0.05),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                        spreadRadius: -8,
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                left: _getCirclePosition(navBarWidth),
                top: -5,
                child: Container(
                  width: 65,
                  height: 65,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: cardWhite,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(7.5),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [primaryTeal, primaryIndigo],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x406366F1),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getSelectedIcon(),
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 65,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavIcon(1, Icons.remove_red_eye_outlined, ''),
                      _buildNavIcon(0, Icons.home_rounded, ''),
                      _buildNavIcon(2, Icons.settings_outlined, ''),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _getSelectedIcon() {
    switch (_selectedIndex) {
      case 0:
        return Icons.home_rounded;
      case 1:
        return Icons.remove_red_eye_outlined;
      case 2:
        return Icons.settings_outlined;
      default:
        return Icons.home_rounded;
    }
  }

  double _getCirclePosition(double navBarWidth) {
    final itemWidth = navBarWidth / 3;

    switch (_selectedIndex) {
      case 0:
        return (navBarWidth / 2) - 32.5;
      case 1:
        return (itemWidth / 2) - 32.5;
      case 2:
        return (itemWidth * 2.5) - 32.5;
      default:
        return (navBarWidth / 2) - 32.5;
    }
  }

  Widget _buildNavIcon(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(height: isSelected ? 5 : 8),
            Icon(
              icon,
              size: 24,
              color: isSelected ?  Colors.transparent : textMuted.withOpacity(0.6),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ?  primaryIndigo : textMuted,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// Wave painter for charging animation
class _WavePainter extends CustomPainter {
  final double animation;
  final Color color;

  _WavePainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.5);

    for (double i = 0; i < size.width; i++) {
      path.lineTo(
        i,
        size.height * 0.5 +
            math.sin((i / size.width * 2 * math.pi) + animation) * 15,
      );
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) => true;
}