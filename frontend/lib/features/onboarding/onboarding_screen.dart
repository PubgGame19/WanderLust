import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../auth/auth_screen.dart';

class OnboardingPageData {
  final String title;
  final String subtitle;
  final String badgeText;
  final IconData icon;
  final List<Color> gradientColors;
  final String illustrationTag;

  const OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.icon,
    required this.gradientColors,
    required this.illustrationTag,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  double _currentPage = 0.0;
  int _currentIndex = 0;

  final List<OnboardingPageData> _pages = const [
    OnboardingPageData(
      badgeText: "SPATIAL TRAVEL INTELLIGENCE",
      title: "Real Places.\nZero Hallucinations.",
      subtitle: "Every review is strictly normalized to verified location nodes. Authentic travel insights powered by real community explorer trails.",
      icon: Icons.explore_rounded,
      gradientColors: [Color(0xFFFF6B4A), Color(0xFFFF8A65)],
      illustrationTag: "explore",
    ),
    OnboardingPageData(
      badgeText: "2-LAYER IMMUTABLE REVIEWS",
      title: "Instant AI Synthesis.\nRaw Truth Preserved.",
      subtitle: "Get immediate bulleted highlights & road alerts distilled by AI, or swipe to inspect the uncompressed unaltered traveler experience.",
      icon: Icons.layers_rounded,
      gradientColors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
      illustrationTag: "layers",
    ),
    OnboardingPageData(
      badgeText: "RAG TRAVEL COPILOT",
      title: "Ask Anything.\nGet Grounded Advice.",
      subtitle: "Plan budget-aware road trips, monsoon treks, and hidden coastal retreats with real community citations and verified prices.",
      icon: Icons.auto_awesome_rounded,
      gradientColors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
      illustrationTag: "assistant",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0.0;
        _currentIndex = _currentPage.round();
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);
    } catch (_) {}

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, anim, secondaryAnim) => const AuthScreen(),
          transitionsBuilder: (context, anim, secondaryAnim, child) {
            return FadeTransition(opacity: anim, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLastPage = _currentIndex == _pages.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          // Background ambient mesh glow
          Positioned(
            top: -100,
            right: -80,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _pages[_currentIndex].gradientColors[0].withOpacity(isDark ? 0.15 : 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _pages[_currentIndex].gradientColors[1].withOpacity(isDark ? 0.12 : 0.06),
              ),
            ),
          ),

          // Main PageView with Parallax Layers
          SafeArea(
            child: Column(
              children: [
                // Top Header: App Branding & Skip Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.sunsetAmber, AppColors.amberLight],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.flight_takeoff_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "WanderLust",
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                      if (!isLastPage)
                        TextButton(
                          onPressed: _completeOnboarding,
                          child: Text(
                            "Skip",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Carousel Body with Parallax Math
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      final delta = index - _currentPage;

                      // Parallax calculations:
                      // Background cards translate at delta * 60
                      final bgCardTranslation = delta * 60.0;
                      // Center icons translate at delta * 40
                      final iconTranslation = delta * 40.0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Parallax Visual Card
                            Transform.translate(
                              offset: Offset(bgCardTranslation, 0),
                              child: Container(
                                height: 260,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: isDark
                                        ? [AppColors.darkCardElevated, AppColors.darkCard]
                                        : [Colors.white, AppColors.lightCardElevated],
                                  ),
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: page.gradientColors[0].withOpacity(isDark ? 0.2 : 0.1),
                                      blurRadius: 30,
                                      offset: const Offset(0, 14),
                                    )
                                  ],
                                ),
                                child: Center(
                                  child: Transform.translate(
                                    offset: Offset(iconTranslation, 0),
                                    child: Container(
                                      width: 110,
                                      height: 110,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: page.gradientColors,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: page.gradientColors[0].withOpacity(0.4),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          )
                                        ],
                                      ),
                                      child: Icon(page.icon, size: 54, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 36),

                            // Badge Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: page.gradientColors[0].withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: page.gradientColors[0].withOpacity(0.3)),
                              ),
                              child: Text(
                                page.badgeText,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                  color: page.gradientColors[0],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Title
                            Text(
                              page.title,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Subtitle
                            Text(
                              page.subtitle,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                height: 1.5,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Controls: Liquid Indicator & Morphing Action Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Liquid Dot Indicator (8px -> 32px expansion)
                      Row(
                        children: List.generate(_pages.length, (i) {
                          final isActive = i == _currentIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.only(right: 8),
                            height: 8,
                            width: isActive ? 32 : 8,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? _pages[_currentIndex].gradientColors[0]
                                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),

                      // Morphing "Next" -> "Get Started" Button
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        height: 52,
                        width: isLastPage ? 160 : 120,
                        child: ElevatedButton(
                          onPressed: () {
                            if (isLastPage) {
                              _completeOnboarding();
                            } else {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOutCubic,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _pages[_currentIndex].gradientColors[0],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isLastPage ? "Get Started" : "Next",
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                isLastPage ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
