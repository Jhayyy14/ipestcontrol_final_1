import 'package:flutter/material.dart';

/// Main screen widget for displaying information about the developers
/// This is a StatefulWidget because it needs to track the current page in the PageView
class AboutDevelopersScreen extends StatefulWidget {
  const AboutDevelopersScreen({super.key});

  @override
  State<AboutDevelopersScreen> createState() => _AboutDevelopersScreenState();
}

/// State class for AboutDevelopersScreen
/// Manages the PageController and current page index
class _AboutDevelopersScreenState extends State<AboutDevelopersScreen> {
  /// Controller for managing the PageView navigation
  late PageController _pageController;

  /// Tracks which developer card is currently being displayed (0-4)
  int _currentPage = 0;

  /// ✨ Matching home screen colors
  static const Color primaryTeal = Color(0xFF00B4A6);
  static const Color primaryIndigo = Color(0xFF6366F1);
  static const Color softBg = Color(0xFFF8FAFC);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);

  /// List of developer information objects
  /// Contains data for all 5 team members
  final List<DeveloperInfo> developers = [
    DeveloperInfo(
      nickName: 'Dev',
      fullName: 'Jhay Penaloza',
      role: 'Lead Developer',
      email: 'jhay.@gmail.com',
      education: 'Bachelor of Science in Information Technology',
      color: primaryTeal, // ✅ Fixed: Now a const Color
    ),
    DeveloperInfo(
      nickName: 'Designer',
      fullName: 'Mark James',
      role: 'UI/UX Designer',
      email: 'mark.@gmail.com',
      education: 'Bachelor of Science in Information Technology',
      color: primaryIndigo, // ✅ Fixed: Now a const Color
    ),
    DeveloperInfo(
      nickName: 'Hardware co Designer',
      fullName: 'Jamescharr Aujero',
      role: 'Hardware Designer',
      email: 'James.j@gmail.com',
      education: 'Bachelor of Science in Information Technology',
      color: const Color(0xFFEC4899), // ✅ Fixed: Added const
    ),
    DeveloperInfo(
      nickName: 'QA',
      fullName: 'Ludygario Tipawan Jr.',
      role: 'Quality Assurance',
      email: 'ludds.w@gmail. com',
      education: 'Bachelor of Science in Information Technology',
      color: const Color(0xFFF59E0B), // ✅ Fixed: Added const
    ),
    DeveloperInfo(
      nickName: 'Documents',
      fullName: 'Marvin Gonzales',
      role: 'Main Docu',
      email: 'vin.@gmail. com',
      education: 'Bachelor of Science in Information Technology',
      color: const Color(0xFF8B5CF6), // ✅ Fixed: Added const
    ),
  ];

  /// Initialize the PageController when the widget is first created
  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
  }

  /// Clean up the PageController when the widget is removed from the tree
  /// This prevents memory leaks
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Builds the main UI for the screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// Main container with gradient background matching home screen
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE0F2FE), Color(0xFFF8FAFC), Color(0xFFEDE9FE)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),

        /// SafeArea ensures content doesn't overlap with system UI
        child: SafeArea(
          child: Column(
            children: [
              /// Custom App Bar with gradient
              _buildModernHeader(),

              const SizedBox(height: 24),

              /// "Meet Our Team" Section
              _buildTeamHeader(),

              const SizedBox(height: 28),

              /// Developer Cards Section (PageView)
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: developers.length,
                  itemBuilder: (context, index) {
                    return _buildModernDeveloperCard(developers[index], index);
                  },
                ),
              ),

              const SizedBox(height: 24),

              /// Modern Page Indicator
              _buildModernPageIndicator(),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  /// Modern Header with gradient background
  Widget _buildModernHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              color: Colors.white.withOpacity(0.2),
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
                    Icons.groups_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'About Developers',
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

  /// Team Header Section
  Widget _buildTeamHeader() {
    return Column(
      children: [
        Text(
          'Meet Our Team',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: textDark,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'The minds behind the innovation',
          style: TextStyle(fontSize: 14, color: textMuted, letterSpacing: 0.3),
        ),
      ],
    );
  }

  /// Modern Developer Card with 3D effect
  Widget _buildModernDeveloperCard(DeveloperInfo developer, int index) {
    bool isActive = index == _currentPage;

    return AnimatedScale(
      scale: isActive ? 1.0 : 0.9,
      duration: const Duration(milliseconds: 300),
      child: AnimatedOpacity(
        opacity: isActive ? 1.0 : 0.6,
        duration: const Duration(milliseconds: 300),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: developer.color.withOpacity(0.3),
                blurRadius: isActive ? 30 : 15,
                offset: Offset(0, isActive ? 15 : 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: SingleChildScrollView(
              // ✅ Added to prevent overflow
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// Top section with gradient
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          developer.color,
                          developer.color.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        /// Decorative circles
                        Positioned(
                          top: -30,
                          right: -30,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -40,
                          left: -40,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
  
                        /// Avatar
                        Center(
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              backgroundColor: Colors.white.withOpacity(0.9),
                              child: Icon(
                                Icons.person_rounded,
                                size: 60,
                                color: developer.color,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// Bottom section with info
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        /// Nick Name Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                developer.color.withOpacity(0.2),
                                developer.color.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: developer.color.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            developer.nickName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: developer.color,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// Full Name
                        Text(
                          developer.fullName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                            height: 1.2,
                          ),
                        ),

                        const SizedBox(height: 12),

                        /// Role Chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: textDark,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: textDark.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            developer.role,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// Divider
                        Container(
                          height: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                textMuted.withOpacity(0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// Email Row
                        _buildInfoRow(
                          Icons.email_rounded,
                          developer.email,
                          developer.color,
                        ),

                        const SizedBox(height: 14),

                        /// Education Row
                        _buildInfoRow(
                          Icons.school_rounded,
                          developer.education,
                          developer.color,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Info Row Widget (reusable)
  Widget _buildInfoRow(IconData icon, String text, Color accentColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: accentColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: textMuted,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Modern Page Indicator with animated dots
  Widget _buildModernPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(developers.length, (index) {
        bool isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(colors: [primaryTeal, primaryIndigo])
                : null,
            color: isActive ? null : textMuted.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: primaryIndigo.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

/// Data model class for storing developer information
class DeveloperInfo {
  final String nickName;
  final String fullName;
  final String role;
  final String email;
  final String education;
  final Color color; // ✅ Now properly typed as non-nullable Color

  DeveloperInfo({
    required this.nickName,
    required this.fullName,
    required this.role,
    required this.email,
    required this.education,
    required this.color, // ✅ Required and properly typed
  });
}
