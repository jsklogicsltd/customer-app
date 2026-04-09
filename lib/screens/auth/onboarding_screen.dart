import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../widgets/common/hunarmand_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = [
    {
      'emoji': '🛍️',
      'heading': 'Pakistan Ki Best Handmade Products',
      'text': 'Ghar bethy authentic Pakistani vendors se seedha kharido',
      'bg': '#E8F5E9',
    },
    {
      'emoji': '✅',
      'heading': 'Verified Vendors — Bharose Ke Saath',
      'text': 'Har vendor aur product admin team verify karti hai',
      'bg': '#E3F2FD',
    },
    {
      'emoji': '📦',
      'heading': 'Easy Ordering & Tracking',
      'text': 'Order karo, track karo, ghar pe receive karo',
      'bg': '#FFF8E1',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/signup');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => context.go('/signup'),
                child: Text('Skip', style: AppTypography.body.copyWith(color: AppColors.textMedium)),
              ),
            ),
            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Illustration
                        Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            color: Color(int.parse('0xFF${slide['bg']!.replaceAll('#', '')}')),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              slide['emoji']!,
                              style: const TextStyle(fontSize: 90),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          slide['heading']!,
                          style: AppTypography.h2.copyWith(color: AppColors.textDark),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          slide['text']!,
                          style: AppTypography.body.copyWith(color: AppColors.textMedium),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Dots + Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _slides.length,
                    effect: const ExpandingDotsEffect(
                      activeDotColor: AppColors.primaryGreen,
                      dotColor: AppColors.divider,
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  HunarmandButton(
                    label: _currentPage == _slides.length - 1 ? 'Get Started →' : 'Next →',
                    onPressed: _next,
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
