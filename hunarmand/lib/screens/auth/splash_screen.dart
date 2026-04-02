import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(parent: _logoController, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      _fadeController.forward();
    });

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) context.go('/language');
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryGreenDark, AppColors.primaryGreen],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            ScaleTransition(
              scale: _scaleAnim,
              child: Column(
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(25),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withAlpha(80), width: 2),
                    ),
                    child: const Center(
                      child: Text('🏺', style: TextStyle(fontSize: 52)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'KARSAAZI',
                    style: AppTypography.h1.copyWith(
                      color: Colors.white,
                      fontSize: 32,
                      letterSpacing: 3,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FadeTransition(
              opacity: _fadeAnim,
              child: Text(
                'Pakistan Ka Hunar, Duniya Tak',
                style: AppTypography.body.copyWith(
                  color: Colors.white.withAlpha(200),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const Spacer(),
            FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'v1.0.0',
                    style: AppTypography.caption.copyWith(color: Colors.white54),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
