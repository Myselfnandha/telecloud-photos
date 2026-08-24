import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_radii.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/app_motion.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPageData> _pages = const [
    _OnboardingPageData(
      icon: Icons.photo_library_rounded,
      badgeText: 'SMART TIMELINE',
      title: 'Your Photos,\nYour Cloud',
      description:
          'Experience your gallery with buttery-smooth pinch-to-zoom tiers, instant indexing, and intelligent duplicate detection.',
      gradientColors: [Color(0xFF0A84FF), Color(0xFF0066CC)],
    ),
    _OnboardingPageData(
      icon: Icons.cloud_upload_rounded,
      badgeText: 'UNLIMITED & FREE',
      title: 'Unlimited Telegram\nCloud Backup',
      description:
          'Back up photos and original-quality 4K videos to your private Telegram storage with multi-worker concurrent syncing.',
      gradientColors: [Color(0xFF30D158), Color(0xFF1E8E3E)],
    ),
    _OnboardingPageData(
      icon: Icons.shield_rounded,
      badgeText: 'COMPLETE CONTROL',
      title: 'Privacy-First &\nTotal Control',
      description:
          'Zero tracking, on-device SQLite database, custom topic channels, and background charging-only sync policies.',
      gradientColors: [Color(0xFFFF9F0A), Color(0xFFD47500)],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('telecloud_onboarding_done', true);
    if (!mounted) return;
    context.go('/setup');
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/icon/app_icon.png',
                          width: 28,
                          height: 28,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.cloud_done_rounded,
                            color: AppColors.primaryBlue,
                            size: 24,
                          ),
                        ),
                      ),
                      AppSpacing.gapHorizontalS,
                      const Text(
                        'TeleCloud',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _completeOnboarding,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white60,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            // Middle: PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  HapticFeedback.selectionClick();
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated Hero Card Graphic
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                page.gradientColors[0].withValues(alpha: 0.25),
                                page.gradientColors[1].withValues(alpha: 0.10),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: page.gradientColors[0].withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: page.gradientColors[0].withValues(alpha: 0.2),
                                blurRadius: 36,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              page.icon,
                              size: 64,
                              color: page.gradientColors[0],
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Badge Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: page.gradientColors[0].withValues(alpha: 0.15),
                            borderRadius: AppRadii.borderPill,
                            border: Border.all(
                              color: page.gradientColors[0].withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            page.badgeText,
                            style: TextStyle(
                              color: page.gradientColors[0],
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Description
                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade400,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Section: Page Indicators + Action Button
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
              child: Column(
                children: [
                  // Smooth Animated Dots Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: AppMotion.durationFast,
                        curve: AppMotion.curveStandard,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primaryBlue
                              : Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Action Button (Next or Get Started)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (isLastPage) {
                          _completeOnboarding();
                        } else {
                          HapticFeedback.lightImpact();
                          _pageController.nextPage(
                            duration: AppMotion.durationMedium,
                            curve: AppMotion.curveStandard,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadii.borderL,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLastPage ? 'Get Started' : 'Continue',
                            style: AppTypography.labelLarge(
                              color: Colors.white,
                            ).copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          AppSpacing.gapHorizontalS,
                          Icon(
                            isLastPage
                                ? Icons.arrow_forward_rounded
                                : Icons.chevron_right_rounded,
                            size: 20,
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
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final String badgeText;
  final String title;
  final String description;
  final List<Color> gradientColors;

  const _OnboardingPageData({
    required this.icon,
    required this.badgeText,
    required this.title,
    required this.description,
    required this.gradientColors,
  });
}
